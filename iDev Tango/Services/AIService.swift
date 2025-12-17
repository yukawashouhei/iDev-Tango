//
//  AIService.swift
//  iDev Tango
//
//  Firebase AI Logic（Gemini 1.5 Flash-8B）を使用したAI定義生成サービス
//  App Checkで保護されたクラウドAIで単語の定義を生成
//

import Foundation
import FirebaseAI
import Combine
import os.log

// AI生成のレスポンス構造体
struct DefinitionResponse {
    let definition: String
}

// AIエラー定義
enum AIError: LocalizedError {
    case notAvailable
    case networkError(Error)
    case authenticationError
    case rateLimitExceeded
    case generationFailed
    case invalidResponse
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "AIが利用できません"
        case .networkError(let error):
            return "ネットワークエラー: \(error.localizedDescription)"
        case .authenticationError:
            return "認証エラーが発生しました"
        case .rateLimitExceeded:
            return "リクエスト制限に達しました。しばらく待ってから再試行してください"
        case .generationFailed:
            return "定義の生成に失敗しました"
        case .invalidResponse:
            return "無効なレスポンスが返されました"
        case .unknown:
            return "不明なエラーが発生しました"
        }
    }
}

@MainActor
class AIService: ObservableObject {
    static let shared = AIService()
    
    @Published var isAvailable: Bool = true
    @Published var availabilityMessage: String = "AI利用可能"
    
    // ログ用のサブシステム
    private let logger = Logger(subsystem: "com.idevtango", category: "AIService")
    
    // Gemini 1.5 Flash-8Bモデル
    private let model: GenerativeModel
    
    private init() {
        // Gemini Developer APIを使用してGemini 1.5 Flash-8Bモデルを初期化
        // Firebase AI LogicでGoogleAIバックエンドを使用
        let ai = FirebaseAI.firebaseAI(backend: .googleAI())
        model = ai.generativeModel(modelName: "gemini-1.5-flash-8b")
        
        checkAvailability()
    }
    
    // AI利用可能性チェック
    func checkAvailability() {
        // Firebase AI Logicは常に利用可能とみなす
        // 実際の利用可能性はAPI呼び出し時にエラーハンドリングで確認
        isAvailable = true
        availabilityMessage = "AI利用可能"
    }
    
    // 単語の定義を生成（分野別専門家モード）
    func fetchDefinition(for term: String) async throws -> DefinitionResponse {
        // Mobile・iOS・Swift・SwiftUI専門家モードのプロンプト
        let prompt = """
        あなたはMobile、iOS、Swift、SwiftUIの専門家です。以下の単語について、簡潔な意味を100字以内の1〜2文で提供してください。
        
        
        重要な制約：
        - 説明は短ければ短いほど優れています
        - 説明はわかりやすければわかりやすいほど優れています
        - **、```などのマークダウン記号は使用しない
        - 例文は含めない
        - 簡潔に本質のみを説明する
        - 100字以内 1〜2行程度に収める
        
        単語: \(term)
        """
        
        do {
            logger.info("🤖 Gemini 1.5 Flash-8Bにリクエスト送信: \(term)")
            
            // Gemini APIを呼び出してテキスト生成
            let response = try await model.generateContent(prompt)
            
            // レスポンスからテキストを取得
            guard let definition = response.text, !definition.isEmpty else {
                logger.error("❌ 空のレスポンスが返されました")
                throw AIError.invalidResponse
            }
            
            logger.info("✅ AI生成成功: \(definition.prefix(50))...")
            
            return DefinitionResponse(definition: definition)
        } catch let error as NSError {
            logger.error("❌ AI生成エラー: \(error.localizedDescription)")
            
            // エラーの種類に応じて適切なAIErrorを返す
            if error.domain == NSURLErrorDomain {
                switch error.code {
                case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                    throw AIError.networkError(error)
                case NSURLErrorTimedOut:
                    throw AIError.networkError(error)
                default:
                    throw AIError.networkError(error)
                }
            } else if error.domain.contains("auth") || error.code == 401 || error.code == 403 {
                throw AIError.authenticationError
            } else if error.code == 429 {
                throw AIError.rateLimitExceeded
            } else {
                throw AIError.generationFailed
            }
        } catch {
            logger.error("❌ 予期しないエラー: \(error.localizedDescription)")
            throw AIError.unknown
        }
    }
}
