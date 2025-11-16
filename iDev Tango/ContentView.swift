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
            .task {
                // 初回のみ初期データを投入
                if !hasSeededData {
                    // まずGitHubから取得を試みる（フォールバックは既存のハードコード）
                    await initializeGlossary()
                    hasSeededData = true
                }
            }
            .onAppear {
                // バックグラウンドタスクから同期が必要とマークされている場合、または1日1回の定期チェックが必要な場合
                let syncNeeded = UserDefaults.standard.bool(forKey: "glossary_sync_needed")
                if syncNeeded || GlossarySyncService.shared.shouldCheckForUpdate() {
                    UserDefaults.standard.set(false, forKey: "glossary_sync_needed")
                    Task {
                        await syncGlossaryIfNeeded()
                    }
                }
            }
    }
    
    /// 用語集を初期化（GitHubから取得を試みる）
    private func initializeGlossary() async {
        do {
            // GitHubから取得を試みる
            try await GlossarySyncService.shared.syncGlossary(context: modelContext, forceUpdate: false)
            print("✅ GitHubから用語集を取得しました")
        } catch {
            print("⚠️ GitHubからの取得に失敗、フォールバックを使用: \(error)")
            // フォールバック：既存のハードコードデータを使用
            InitialDataService.shared.seedInitialData(context: modelContext)
        }
    }
    
    /// 必要に応じて用語集を同期
    private func syncGlossaryIfNeeded() async {
        guard GlossarySyncService.shared.shouldCheckForUpdate() else {
            return
        }
        
        do {
            try await GlossarySyncService.shared.syncGlossary(context: modelContext, forceUpdate: false)
            print("✅ 用語集の定期同期が完了しました")
        } catch {
            print("⚠️ 用語集の定期同期に失敗: \(error)")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Deck.self, Card.self, ActivityLog.self])
}
