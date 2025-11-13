//
//  LearningService.swift
//  iDev Tango
//
//  間隔反復学習サービス
//  理解度に応じた出題頻度とランダム出題を管理
//

import Foundation
import SwiftData

@MainActor
class LearningService: ObservableObject {
    static let shared = LearningService()
    
    // 現在の学習セッションで「わからない」を押したカードのID
    private var currentSessionDifficultCards: Set<UUID> = []
    
    private init() {}
    
    // 学習セッション開始
    func startLearningSession() {
        currentSessionDifficultCards.removeAll()
        print("🎯 学習セッション開始")
    }
    
    // 学習セッション終了
    func endLearningSession() {
        print("🏁 学習セッション終了: 困難カード \(currentSessionDifficultCards.count)枚")
        currentSessionDifficultCards.removeAll()
    }
    
    // 学習対象カードを選択（理解度とランダム性を考慮）
    func selectCardsForReview(from deck: Deck) -> [Card] {
        let now = Date()
        let allCards = deck.cards
        let maxQuestions = min(10, allCards.count) // 最大10問、または登録単語数
        
        print("🔍 学習カード選択開始: 総カード数 = \(allCards.count), 最大出題数 = \(maxQuestions)")
        
        // 1. 学習対象カードをフィルタリング（セッション内困難カードを除外）
        let reviewableCards = allCards.filter { card in
            // セッション内で「わからない」を押したカードは除外
            if currentSessionDifficultCards.contains(card.id) {
                print("🚫 セッション内除外: \(card.term)")
                return false
            }
            
            guard let nextReview = card.nextReviewDate else { 
                print("📝 新規カード: \(card.term) (理解度: \(card.understandingLevel))")
                return true // 新規カードは常に含める
            }
            let isReviewable = nextReview <= now
            if isReviewable {
                print("⏰ 学習対象: \(card.term) (理解度: \(card.understandingLevel), 次回学習: \(nextReview))")
            } else {
                print("⏳ 学習対象外: \(card.term) (理解度: \(card.understandingLevel), 次回学習: \(nextReview))")
            }
            return isReviewable
        }
        
        print("📚 学習対象カード数: \(reviewableCards.count)")
        
        // 2. 理解度に応じて重み付け（重複なし）
        let weightedCards = reviewableCards.flatMap { card in
            let level = UnderstandingLevel(rawValue: card.understandingLevel) ?? .new
            let weight = level.weight
            print("⚖️ \(card.term): 理解度\(level.displayName), 重み\(weight)")
            return Array(repeating: card, count: weight)
        }
        
        print("🎯 重み付け後カード数: \(weightedCards.count)")
        
        // 3. 重み付けされたカードが空の場合は、全てのカードをランダムに返す
        if weightedCards.isEmpty {
            print("⚠️ 重み付けカードが空のため、全カードをランダム返却")
            let shuffledCards = allCards.shuffled()
            return Array(shuffledCards.prefix(maxQuestions))
        }
        
        // 4. 学習対象カードが少なすぎる場合は、全カードから選択
        if reviewableCards.count < maxQuestions {
            print("⚠️ 学習対象カードが少ない(\(reviewableCards.count)枚)ため、全カードから選択")
            let shuffledCards = allCards.shuffled()
            return Array(shuffledCards.prefix(maxQuestions))
        }
        
        // 5. ランダムシャッフルして重複を除去
        let shuffledWeightedCards = weightedCards.shuffled()
        var uniqueCards: [Card] = []
        var seenCardIds: Set<UUID> = []
        
        for card in shuffledWeightedCards {
            if !seenCardIds.contains(card.id) {
                uniqueCards.append(card)
                seenCardIds.insert(card.id)
                if uniqueCards.count >= maxQuestions {
                    break
                }
            }
        }
        
        print("✅ 最終選択カード数: \(uniqueCards.count) (重複除去済み)")
        return uniqueCards
    }
    
    // 理解度を更新
    func updateUnderstanding(for card: Card, isCorrect: Bool) {
        let currentLevel = UnderstandingLevel(rawValue: card.understandingLevel) ?? .new
        
        if isCorrect {
            // 正解時：理解度を上げる
            let newLevel = min(currentLevel.rawValue + 1, UnderstandingLevel.expert.rawValue)
            card.understandingLevel = newLevel
            print("✅ \(card.term): 理解度アップ \(currentLevel.displayName) → \(UnderstandingLevel(rawValue: newLevel)!.displayName)")
        } else {
            // 不正解時：理解度を下げる + セッション内困難カードに追加
            let newLevel = max(currentLevel.rawValue - 1, UnderstandingLevel.new.rawValue)
            card.understandingLevel = newLevel
            
            // セッション内困難カードに追加
            currentSessionDifficultCards.insert(card.id)
            print("❌ \(card.term): 理解度ダウン \(currentLevel.displayName) → \(UnderstandingLevel(rawValue: newLevel)!.displayName)")
            print("📝 セッション内困難カードに追加: \(card.term)")
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
        
        if !isCorrect {
            print("⏰ 次回学習予定: \(card.term) - \(Int(reviewInterval/60))分後")
        }
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
