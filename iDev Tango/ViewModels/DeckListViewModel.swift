//
//  DeckListViewModel.swift
//  iDev Tango
//
//  フォルダ一覧画面のViewModel
//  デッキの作成・削除・一覧取得を管理
//

import Foundation
import SwiftData
import Combine

@MainActor
class DeckListViewModel: ObservableObject {
    @Published var decks: [Deck] = []
    @Published var showingAddDeck = false
    @Published var newDeckName = ""
    
    private var modelContext: ModelContext?
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        fetchDecks()
    }
    
    // デッキ一覧を取得
    func fetchDecks() {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<Deck>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            decks = try context.fetch(descriptor)
        } catch {
            print("デッキの取得に失敗: \(error)")
        }
    }
    
    // 新しいデッキを作成
    func addDeck(name: String) {
        guard let context = modelContext, !name.isEmpty else { return }
        
        let newDeck = Deck(name: name)
        context.insert(newDeck)
        
        do {
            try context.save()
            fetchDecks()
            newDeckName = ""
            showingAddDeck = false
        } catch {
            print("デッキの保存に失敗: \(error)")
        }
    }
    
    // デッキを削除
    func deleteDeck(_ deck: Deck) {
        guard let context = modelContext else { return }
        
        context.delete(deck)
        
        do {
            try context.save()
            fetchDecks()
        } catch {
            print("デッキの削除に失敗: \(error)")
        }
    }
}
