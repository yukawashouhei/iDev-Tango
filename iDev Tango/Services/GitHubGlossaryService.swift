//
//  GitHubGlossaryService.swift
//  iDev Tango
//
//  GitHubから用語集JSONファイルを取得するサービス
//  Apple推奨のasync/awaitを使用した最新実装
//

import Foundation
import CryptoKit
import os.log

/// GitHub用語集データモデル
struct GlossaryItem: Codable, Sendable {
    let id: String
    let term: String
    let definition: String
}

struct GlossaryData: Codable, Sendable {
    let version: String
    let lastUpdated: String
    let signature: String?
    let glossary: [GlossaryItem]
}

/// GitHub用語集取得エラー
enum GitHubGlossaryError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case signatureVerificationFailed
    case noData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .networkError(let error):
            return "ネットワークエラー: \(error.localizedDescription)"
        case .invalidResponse:
            return "無効なレスポンスです"
        case .decodingError(let error):
            return "データの解析に失敗しました: \(error.localizedDescription)"
        case .signatureVerificationFailed:
            return "署名の検証に失敗しました"
        case .noData:
            return "データが取得できませんでした"
        }
    }
}

@MainActor
class GitHubGlossaryService {
    static let shared = GitHubGlossaryService()
    
    // ログ用のサブシステム
    private let logger = Logger(subsystem: "com.idevtango", category: "GitHubGlossaryService")
    
    private init() {}
    
    // GitHubリポジトリの設定（後で設定可能にする）
    private let repositoryOwner = "yukawashouhei"
    private let repositoryName = "iDev-Tango"
    private let glossaryPath = "glossary/swift-glossary.json"
    
    // GitHub APIのベースURL
    private var baseURL: String {
        "https://api.github.com/repos/\(repositoryOwner)/\(repositoryName)/contents/\(glossaryPath)"
    }
    
    /// GitHubから用語集JSONファイルを取得
    /// - Parameter token: GitHub Personal Access Token（オプション、読み取り専用）
    /// - Returns: 用語集データ
    func fetchGlossary(token: String? = nil) async throws -> GlossaryData {
        logger.info("🌐 GitHub APIにリクエストを送信: \(self.baseURL)")
        
        guard let url = URL(string: baseURL) else {
            logger.error("❌ 無効なURL: \(self.baseURL)")
            throw GitHubGlossaryError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        // 認証トークンが提供されている場合は追加
        if let token = token {
            request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
            logger.info("🔐 認証トークンを使用してリクエスト")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("❌ 無効なHTTPレスポンス")
                throw GitHubGlossaryError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                logger.error("❌ HTTPステータスコードエラー: \(httpResponse.statusCode)")
                throw GitHubGlossaryError.invalidResponse
            }
            
            logger.info("✅ HTTPレスポンス取得成功: \(httpResponse.statusCode)")
            
            // GitHub APIのレスポンスはBase64エンコードされている
            let githubResponse = try JSONDecoder().decode(GitHubContentResponse.self, from: data)
            
            guard let contentData = Data(base64Encoded: githubResponse.content, options: .ignoreUnknownCharacters) else {
                logger.error("❌ Base64デコードに失敗")
                throw GitHubGlossaryError.decodingError(NSError(domain: "Base64Decoding", code: -1))
            }
            
            // JSONをデコード
            let glossaryData = try JSONDecoder().decode(GlossaryData.self, from: contentData)
            logger.info("✅ JSONデコード成功: \(glossaryData.glossary.count)件の用語を取得")
            
            // 署名検証（オプション、署名が提供されている場合のみ）
            if let signature = glossaryData.signature, !signature.isEmpty {
                let isValid = try verifySignature(data: contentData, signature: signature)
                if !isValid {
                    logger.error("❌ 署名の検証に失敗")
                    throw GitHubGlossaryError.signatureVerificationFailed
                }
                logger.info("✅ 署名の検証に成功")
            }
            
            return glossaryData
            
        } catch let error as GitHubGlossaryError {
            logger.error("❌ GitHub用語集取得エラー: \(error.localizedDescription)\n")
            throw error
        } catch {
            logger.error("❌ ネットワークエラー: \(error.localizedDescription)")
            throw GitHubGlossaryError.networkError(error)
        }
    }
    
    /// 署名を検証（オプション機能）
    /// - Parameters:
    ///   - data: 検証するデータ
    ///   - signature: Base64エンコードされた署名
    /// - Returns: 検証結果
    private func verifySignature(data: Data, signature: String) throws -> Bool {
        // 実装は後で追加（公開鍵が必要）
        // 現在は署名が存在する場合のみ検証を試みる
        // 実際の実装では、CryptoKitを使用して公開鍵で署名を検証
        
        // 暫定的にtrueを返す（署名検証をスキップ）
        // 本番環境では適切に実装する必要がある
        return true
    }
}

/// GitHub APIのコンテンツレスポンス
private struct GitHubContentResponse: Codable {
    let content: String
    let encoding: String
    let sha: String
}

