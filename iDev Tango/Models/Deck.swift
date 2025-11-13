//
//  Deck.swift
//  iDev Tango
//
//  フォルダ（デッキ）のデータモデル
//  SwiftDataを使用してローカルDBに保存
//

import Foundation
import SwiftData

@Model
class Deck {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \Card.deck)
    var cards: [Card] = []
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        // cardsは自動的に空配列で初期化される
    }
}
