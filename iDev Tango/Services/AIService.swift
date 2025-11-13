//
//  AIService.swift
//  iDev Tango
//
//  Foundation Models Frameworkを使用したAI定義生成サービス
//  オンデバイスAIで単語の定義を生成
//

import Foundation
import FoundationModels
import Combine

// AI生成のレスポンス構造体
struct DefinitionResponse {
    let definition: String
}

// AIエラー定義
enum AIError: LocalizedError {
    case notAvailable
    case deviceNotEligible
    case appleIntelligenceNotEnabled
    case modelNotReady
    case generationFailed
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "AIが利用できません"
        case .deviceNotEligible:
            return "この端末はApple Intelligenceに対応していません"
        case .appleIntelligenceNotEnabled:
            return "Apple Intelligenceを有効にしてください"
        case .modelNotReady:
            return "AIモデルの準備中です"
        case .generationFailed:
            return "定義の生成に失敗しました"
        case .unknown:
            return "不明なエラーが発生しました"
        }
    }
}

@MainActor
class AIService: ObservableObject {
    static let shared = AIService()
    
    @Published var isAvailable: Bool = false
    @Published var availabilityMessage: String = ""
    
    private init() {
        checkAvailability()
    }
    
    // AI利用可能性チェック
    func checkAvailability() {
        switch SystemLanguageModel.default.availability {
        case .available:
            isAvailable = true
            availabilityMessage = "AI利用可能"
        case .unavailable(.deviceNotEligible):
            isAvailable = false
            availabilityMessage = "この端末はApple Intelligenceに対応していません"
        case .unavailable(.appleIntelligenceNotEnabled):
            isAvailable = false
            availabilityMessage = "Apple Intelligenceを有効にしてください"
        case .unavailable(.modelNotReady):
            isAvailable = false
            availabilityMessage = "AIモデルの準備中です"
        default:
            isAvailable = false
            availabilityMessage = "AIが利用できません"
        }
    }
    
    // 単語の定義を生成（分野別専門家モード）
    func fetchDefinition(for term: String) async throws -> DefinitionResponse {
        // 利用可能性チェック
        guard SystemLanguageModel.default.isAvailable else {
            throw AIError.notAvailable
        }
        
        // セッション作成
        let session = LanguageModelSession()
        
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
            // AI生成実行
            // 参考: https://zenn.dev/lancers/articles/6be34c9ba461fc
            let response = try await session.respond(to: prompt)
            
            // レスポンスからテキストを取得
            let definition = response.content
            
            guard !definition.isEmpty else {
                throw AIError.generationFailed
            }
            
            return DefinitionResponse(definition: definition)
        } catch {
            print("❌ AI生成エラー: \(error)")
            if let aiError = error as? AIError {
                throw aiError
            } else {
                throw AIError.unknown
            }
        }
    }
}
