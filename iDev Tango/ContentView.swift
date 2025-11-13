//
//  ContentView.swift
//  iDev Tango
//
//  メインエントリーポイント
//  DeckListViewを表示
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var hasSeededData = false
    
    var body: some View {
        DeckListView()
            .onAppear {
                // 初回のみ初期データを投入
                if !hasSeededData {
                    InitialDataService.shared.seedInitialData(context: modelContext)
                    hasSeededData = true
                }
            }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Deck.self, Card.self, ActivityLog.self])
}
