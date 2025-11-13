//
//  Card.swift
//  iDev Tango
//
//  単語カードのデータモデル
//  各カードは単語（term）とAI生成の定義（definition）を持つ
//

import Foundation
import SwiftData

@Model
class Card {
    @Attribute(.unique) var id: UUID
    var term: String      // 単語
    var definition: String // AI生成の定義
    var createdAt: Date
    
    // 理解度管理フィールド
    var understandingLevel: Int = 0  // 理解度レベル (0-5)
    var lastReviewed: Date?          // 最後に学習した日時
    var reviewCount: Int = 0         // 学習回数
    var nextReviewDate: Date?        // 次回学習予定日
    
    var deck: Deck?
    
    init(term: String, definition: String, deck: Deck? = nil) {
        self.id = UUID()
        self.term = term
        self.definition = definition
        self.createdAt = Date()
        self.understandingLevel = 0
        self.reviewCount = 0
        self.deck = deck
    }
}
