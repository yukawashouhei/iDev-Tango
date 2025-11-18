//
//  LearningService.swift
//  iDev Tango
//
//  間隔反復学習サービス
//  理解度に応じた出題頻度とランダム出題を管理
//

import Foundation
import SwiftData
import os.log

@MainActor
class LearningService: ObservableObject {
    static let shared = LearningService()
    
    // 現在の学習セッションで「わからない」を押したカードのID
    private var currentSessionDifficultCards: Set<UUID> = []
    
    // ログ用のサブシステム
    private let logger = Logger(subsystem: "com.idevtango", category: "LearningService")
    
    private init() {}
    
    // 学習セッション開始
    func startLearningSession() {
        self.currentSessionDifficultCards.removeAll()
        logger.info("🎯 学習セッション開始")
    }
    
    // 学習セッション終了
    func endLearningSession() {
        logger.info("🏁 学習セッション終了: 困難カード \(self.currentSessionDifficultCards.count)枚")
        self.currentSessionDifficultCards.removeAll()
    }
    
    // 学習対象カードを選択（理解度とランダム性を考慮）
    // パフォーマンス最適化: カード配列を直接受け取る（リレーションシップの遅延読み込みを避ける）
    func selectCardsForReview(from cards: [Card]) -> [Card] {
        // 早期リターンで処理を短縮
        guard !cards.isEmpty else {
            logger.info("⚠️ カードが空のため、空配列を返却")
            return []
        }
        
        let now = Date()
        let maxQuestions = min(10, cards.count) // 最大10問、または登録単語数
        
        // 1. 学習対象カードをフィルタリング（セッション内困難カードを除外）
        // 最適化: filterとmapを一度に実行
        var reviewableCards: [Card] = []
        reviewableCards.reserveCapacity(cards.count) // 容量を事前に確保
        
        for card in cards {
            // セッション内で「わからない」を押したカードは除外
            if self.currentSessionDifficultCards.contains(card.id) {
                continue
            }
            
            // 新規カードまたは次回学習日が来ているカード
            if card.nextReviewDate == nil || card.nextReviewDate! <= now {
                reviewableCards.append(card)
            }
        }
        
        // 2. 学習対象カードが少なすぎる場合は、全カードから選択
        if reviewableCards.count < maxQuestions {
            logger.info("⚠️ 学習対象カードが少ない(\(reviewableCards.count)枚)ため、全カードから選択")
            return Array(cards.shuffled().prefix(maxQuestions))
        }
        
        // 3. 理解度に応じて重み付け（最適化: 重複配列を作らずに直接選択）
        // 重み付け配列を作成（メモリ効率を改善）
        var weightedCardPairs: [(card: Card, weight: Int)] = []
        weightedCardPairs.reserveCapacity(reviewableCards.count)
        
        for card in reviewableCards {
            let level = UnderstandingLevel(rawValue: card.understandingLevel) ?? .new
            weightedCardPairs.append((card, level.weight))
        }
        
        // 4. 重み付けに基づいてカードを選択（重複を避けながら）
        var selectedCards: [Card] = []
        var seenCardIds: Set<UUID> = []
        selectedCards.reserveCapacity(maxQuestions)
        
        // 重みの合計を計算
        let totalWeight = weightedCardPairs.reduce(0) { $0 + $1.weight }
        
        // ランダムに選択（重みを考慮）
        let shuffledPairs = weightedCardPairs.shuffled()
        
        var remainingSlots = maxQuestions
        
        for pair in shuffledPairs {
            if remainingSlots <= 0 { break }
            
            // 既に選択されたカードはスキップ
            if seenCardIds.contains(pair.card.id) {
                continue
            }
            
            // 重みに基づいて選択確率を調整（簡易版）
            let selectionProbability = Double(pair.weight) / Double(totalWeight)
            if Double.random(in: 0...1) < selectionProbability * 2.0 || selectedCards.count < maxQuestions / 2 {
                selectedCards.append(pair.card)
                seenCardIds.insert(pair.card.id)
                remainingSlots -= 1
            }
        }
        
        // 5. 選択数が不足している場合は、残りをランダムに追加
        if selectedCards.count < maxQuestions {
            let remainingCards = reviewableCards.filter { !seenCardIds.contains($0.id) }
            let additionalNeeded = maxQuestions - selectedCards.count
            let additionalCards = Array(remainingCards.shuffled().prefix(additionalNeeded))
            selectedCards.append(contentsOf: additionalCards)
        }
        
        logger.info("✅ 最終選択カード数: \(selectedCards.count) (総カード数: \(cards.count))")
        return selectedCards
    }
    
    // デッキから学習対象カードを選択（後方互換性のため）
    func selectCardsForReview(from deck: Deck) -> [Card] {
        return selectCardsForReview(from: Array(deck.cards))
    }
    
    // 理解度を更新
    func updateUnderstanding(for card: Card, isCorrect: Bool) {
        let currentLevel = UnderstandingLevel(rawValue: card.understandingLevel) ?? .new
        
        if isCorrect {
            // 正解時：理解度を上げる
            let newLevel = min(currentLevel.rawValue + 1, UnderstandingLevel.expert.rawValue)
            card.understandingLevel = newLevel
            logger.info("✅ \(card.term): 理解度アップ \(currentLevel.displayName) → \(UnderstandingLevel(rawValue: newLevel)!.displayName)")
        } else {
            // 不正解時：理解度を下げる + セッション内困難カードに追加
            let newLevel = max(currentLevel.rawValue - 1, UnderstandingLevel.new.rawValue)
            card.understandingLevel = newLevel
            
            // セッション内困難カードに追加
            self.currentSessionDifficultCards.insert(card.id)
            logger.info("❌ \(card.term): 理解度ダウン \(currentLevel.displayName) → \(UnderstandingLevel(rawValue: newLevel)!.displayName)")
        }
        
        // 次回学習日を設定
        let newUnderstandingLevel = UnderstandingLevel(rawValue: card.understandingLevel)!
        
        // 「わからない」を押した場合は、次回学習を早める
        let reviewInterval = isCorrect ? 
            newUnderstandingLevel.nextReviewInterval : 
            min(newUnderstandingLevel.nextReviewInterval, 3600) // 最大1時間後に再学習
        
        card.nextReviewDate = Date().addingTimeInterval(reviewInterval)
        card.lastReviewed = Date()
        card.reviewCount += 1
    }
    
    // 理解度レベルの表示名を取得
    func getUnderstandingDisplayName(for card: Card) -> String {
        let level = UnderstandingLevel(rawValue: card.understandingLevel) ?? .new
        return level.displayName
    }
    
    // 次回学習日までの残り時間を取得
    func getTimeUntilNextReview(for card: Card) -> String {
        guard let nextReview = card.nextReviewDate else { return "今すぐ" }
        
        let now = Date()
        let timeInterval = nextReview.timeIntervalSince(now)
        
        if timeInterval <= 0 {
            return "今すぐ"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)分後"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)時間後"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)日後"
        }
    }
}

