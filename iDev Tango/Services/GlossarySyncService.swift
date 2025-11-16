//
//  GlossarySyncService.swift
//  iDev Tango
//
//  用語集の同期サービス
//  GitHubから取得したデータをSwiftDataに反映（理解度を保持）
//

import Foundation
import SwiftData

@MainActor
class GlossarySyncService {
    static let shared = GlossarySyncService()
    
    private let githubService = GitHubGlossaryService.shared
    private let cacheService = GlossaryCacheService.shared
    
    private init() {}
    
    /// 用語集を同期（GitHubから取得してSwiftDataに反映）
    /// - Parameters:
    ///   - context: SwiftDataのModelContext
    ///   - token: GitHub Personal Access Token（オプション）
    ///   - forceUpdate: 強制更新フラグ（キャッシュを無視）
    func syncGlossary(context: ModelContext, token: String? = nil, forceUpdate: Bool = false) async throws {
        print("🔄 用語集の同期を開始...")
        
        // キャッシュが有効で、強制更新でない場合はキャッシュを使用
        if !forceUpdate, let cachedData = cacheService.getCachedGlossary(), cacheService.isCacheValid() {
            print("📦 キャッシュから用語集を読み込み")
            try await applyGlossaryToDatabase(cachedData, context: context)
            return
        }
        
        // GitHubから取得を試みる
        do {
            print("🌐 GitHubから用語集を取得中...")
            let glossaryData = try await githubService.fetchGlossary(token: token)
            
            // キャッシュに保存
            cacheService.saveCache(glossaryData)
            
            // データベースに反映
            try await applyGlossaryToDatabase(glossaryData, context: context)
            
            print("✅ 用語集の同期が完了しました")
            
        } catch {
            print("❌ GitHubからの取得に失敗: \(error)")
            
            // エラー時はキャッシュを使用（フォールバック）
            if let cachedData = cacheService.getCachedGlossary() {
                print("📦 キャッシュから用語集を読み込み（フォールバック）")
                try await applyGlossaryToDatabase(cachedData, context: context)
            } else {
                throw error
            }
        }
    }
    
    /// 用語集データをSwiftDataに反映（理解度を保持）
    /// - Parameters:
    ///   - glossaryData: 用語集データ
    ///   - context: SwiftDataのModelContext
    private func applyGlossaryToDatabase(_ glossaryData: GlossaryData, context: ModelContext) async throws {
        // 「Swift」デッキを取得または作成
        let deckDescriptor = FetchDescriptor<Deck>(
            predicate: #Predicate<Deck> { deck in
                deck.name == "Swift"
            }
        )
        
        let existingDecks = try context.fetch(deckDescriptor)
        let swiftDeck: Deck
        
        if let existingDeck = existingDecks.first {
            swiftDeck = existingDeck
        } else {
            swiftDeck = Deck(name: "Swift")
            context.insert(swiftDeck)
        }
        
        // 既存のデフォルトカードを取得（理解度を保持するため）
        let cardDescriptor = FetchDescriptor<Card>(
            predicate: #Predicate<Card> { card in
                card.isDefault == true && card.deck?.name == "Swift"
            }
        )
        
        let existingCards = try context.fetch(cardDescriptor)
        var existingCardsMap: [String: Card] = [:]
        
        for card in existingCards {
            existingCardsMap[card.term] = card
        }
        
        // 新しい用語集データを反映
        for item in glossaryData.glossary {
            if let existingCard = existingCardsMap[item.term] {
                // 既存のカードがある場合：定義のみ更新（理解度は保持）
                existingCard.definition = item.definition
                print("🔄 カードを更新: \(item.term)（理解度を保持）")
            } else {
                // 新しいカードを作成
                let newCard = Card(term: item.term, definition: item.definition, deck: swiftDeck, isDefault: true)
                context.insert(newCard)
                print("➕ 新しいカードを追加: \(item.term)")
            }
        }
        
        // 削除された単語の処理（GitHubに存在しないが、ローカルに存在するデフォルトカード）
        let currentTerms = Set(glossaryData.glossary.map { $0.term })
        for (term, card) in existingCardsMap {
            if !currentTerms.contains(term) {
                // 削除された単語は非表示にする（isDefaultをfalseに変更）
                // または削除する（ユーザーの理解度を保持するため、削除は推奨しない）
                // ここでは削除せず、isDefaultをfalseに変更
                card.isDefault = false
                print("🗑️ カードを非デフォルト化: \(term)")
            }
        }
        
        // 変更を保存
        try context.save()
        print("💾 データベースへの反映が完了しました")
    }
    
    /// 1日1回の定期チェックが必要かどうかを判定
    /// - Returns: チェックが必要な場合true
    func shouldCheckForUpdate() -> Bool {
        guard let lastUpdate = cacheService.getLastUpdateDate() else {
            return true
        }
        
        let now = Date()
        let timeInterval = now.timeIntervalSince(lastUpdate)
        let hours24: TimeInterval = 24 * 60 * 60
        
        return timeInterval >= hours24
    }
}

