//
//  CardListViewModel.swift
//  iDev Tango
//
//  単語一覧画面のViewModel
//  カードの作成・削除・一覧取得を管理
//

import Foundation
import SwiftData
import Combine
import os.log

@MainActor
class CardListViewModel: ObservableObject {
    @Published var cards: [Card] = []
    @Published var showingAddCard = false
    
    // ログ用のサブシステム
    private let logger = Logger(subsystem: "com.idevtango", category: "CardListViewModel")
    
    private var modelContext: ModelContext?
    private var currentDeck: Deck?
    
    func setModelContext(_ context: ModelContext, deck: Deck) {
        self.modelContext = context
        self.currentDeck = deck
        fetchCards()
    }
    
    // カード一覧を取得
    func fetchCards() {
        guard let deck = currentDeck else { return }
        cards = deck.cards
    }
    
    // 新しいカードを作成
    func addCard(term: String, definition: String) {
        guard let context = modelContext,
              let deck = currentDeck,
              !term.isEmpty,
              !definition.isEmpty else { return }
        
        let newCard = Card(term: term, definition: definition, deck: deck)
        context.insert(newCard)
        
        do {
            try context.save()
            fetchCards()
        } catch {
            logger.error("❌ カードの保存に失敗: \(error.localizedDescription)")
        }
    }
    
    // カードを削除
    func deleteCard(_ card: Card) {
        guard let context = modelContext else { return }
        
        context.delete(card)
        
        do {
            try context.save()
            fetchCards()
        } catch {
            logger.error("❌ カードの削除に失敗: \(error.localizedDescription)")
        }
    }
    
    // カードを更新
    func updateCard(_ card: Card, term: String, definition: String) {
        guard let context = modelContext else { return }
        
        card.term = term
        card.definition = definition
        
        do {
            try context.save()
            fetchCards()
        } catch {
            logger.error("❌ カードの更新に失敗: \(error.localizedDescription)")
        }
    }
}
