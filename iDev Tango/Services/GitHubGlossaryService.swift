//
//  GitHubGlossaryService.swift
//  iDev Tango
//
//  GitHubから用語集JSONファイルを取得するサービス
//  Apple推奨のasync/awaitを使用した最新実装
//

import Foundation
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
    let glossary: [GlossaryItem]
}

/// GitHub用語集取得エラー
enum GitHubGlossaryError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
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
    ///                     指定されない場合はGitHubTokenServiceから自動取得
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
        
        // 認証トークン: 引数で指定されたもの、またはGitHubTokenServiceから取得
        let authToken = token ?? GitHubTokenService.shared.getToken()
        if let token = authToken {
            request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
            logger.info("🔐 認証トークンを使用してリクエスト")
        } else {
            logger.warning("⚠️ 認証トークンが設定されていません。Publicリポジトリの場合は問題ありませんが、Privateリポジトリの場合はエラーになる可能性があります。")
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
            
            return glossaryData
            
        } catch let error as GitHubGlossaryError {
            logger.error("❌ GitHub用語集取得エラー: \(error.localizedDescription)\n")
            throw error
        } catch {
            logger.error("❌ ネットワークエラー: \(error.localizedDescription)")
            throw GitHubGlossaryError.networkError(error)
        }
    }
}

/// GitHub APIのコンテンツレスポンス
private struct GitHubContentResponse: Codable {
    let content: String
    let encoding: String
    let sha: String
}

