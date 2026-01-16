//
//  GlossarySyncService.swift
//  iDev Tango
//
//  用語集の同期サービス
//  GitHubから取得したデータをSwiftDataに反映（理解度を保持）
//

import Foundation
import SwiftData
import os.log

@MainActor
class GlossarySyncService {
    static let shared = GlossarySyncService()
    
    private let githubService = GitHubGlossaryService.shared
    private let cacheService = GlossaryCacheService.shared
    
    // ログ用のサブシステム
    private let logger = Logger(subsystem: "com.idevtango", category: "GlossarySyncService")
    
    private init() {}
    
    /// 用語集を同期（GitHubから取得してSwiftDataに反映）
    /// - Parameters:
    ///   - context: SwiftDataのModelContext
    ///   - token: GitHub Personal Access Token（オプション、通常は指定不要）
    ///            指定されない場合はGitHubTokenServiceから自動取得
    ///   - forceUpdate: 強制更新フラグ（キャッシュを無視）
    func syncGlossary(context: ModelContext, token: String? = nil, forceUpdate: Bool = false) async throws {
        logger.info("🔄 用語集の同期を開始")
        
        // キャッシュが有効で、強制更新でない場合はキャッシュを使用
        if !forceUpdate, let cachedData = cacheService.getCachedGlossary(), cacheService.isCacheValid() {
            logger.info("📦 キャッシュから用語集を読み込み")
            try await applyGlossaryToDatabase(cachedData, context: context)
            return
        }
        
        // GitHubから取得を試みる
        do {
            logger.info("🌐 GitHubから用語集を取得中...")
            // tokenが指定されていない場合は、GitHubTokenServiceから自動取得
            // GitHubGlossaryService内で処理されるため、ここではそのまま渡す
            let glossaryData = try await githubService.fetchGlossary(token: token)
            
            // キャッシュに保存
            cacheService.saveCache(glossaryData)
            logger.info("💾 用語集をキャッシュに保存しました")
            
            // データベースに反映
            try await applyGlossaryToDatabase(glossaryData, context: context)
            
            logger.info("✅ 用語集の同期が完了しました（GitHubから取得）")
            
        } catch {
            logger.error("❌ GitHubからの取得に失敗: \(error.localizedDescription)")
            
            // エラー時はキャッシュを使用（フォールバック）
            if let cachedData = cacheService.getCachedGlossary() {
                logger.info("📦 キャッシュから用語集を読み込み（フォールバック）")
                try await applyGlossaryToDatabase(cachedData, context: context)
                logger.info("✅ キャッシュから用語集の読み込みが完了しました")
            } else {
                logger.error("❌ キャッシュも存在しません。初回起動時はネットワーク接続が必要です")
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
                card.isDefault == true && (card.deck?.name ?? "") == "Swift"
            }
        )
        
        let existingCards = try context.fetch(cardDescriptor)
        var existingCardsMap: [String: Card] = [:]
        
        for card in existingCards {
            existingCardsMap[card.term] = card
        }
        
        // 新しい用語集データを反映
        var updatedCount = 0
        var addedCount = 0
        
        for item in glossaryData.glossary {
            if let existingCard = existingCardsMap[item.term] {
                // 既存のカードがある場合：定義のみ更新（理解度は保持）
                existingCard.definition = item.definition
                updatedCount += 1
            } else {
                // 新しいカードを作成
                let newCard = Card(term: item.term, definition: item.definition, deck: swiftDeck, isDefault: true)
                context.insert(newCard)
                addedCount += 1
            }
        }
        
        // 削除された単語の処理（GitHubに存在しないが、ローカルに存在するデフォルトカード）
        let currentTerms = Set(glossaryData.glossary.map { $0.term })
        var removedCount = 0
        
        for (term, card) in existingCardsMap {
            if !currentTerms.contains(term) {
                // 削除された単語は非表示にする（isDefaultをfalseに変更）
                // ユーザーの理解度を保持するため、削除は行わない
                card.isDefault = false
                removedCount += 1
            }
        }
        
        // 変更を保存
        try context.save()
        
        // 保留中の変更を処理して、@Queryが確実に更新されるようにする
        context.processPendingChanges()
        
        logger.info("💾 データベースへの反映が完了しました（追加: \(addedCount), 更新: \(updatedCount), 非デフォルト化: \(removedCount)）")
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

