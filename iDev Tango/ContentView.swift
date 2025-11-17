//
//  ContentView.swift
//  iDev Tango
//
//  メインエントリーポイント
//  DeckListViewを表示
//

import SwiftUI
import SwiftData
import os.log

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var hasSeededData = false
    
    // ログ用のサブシステム
    private let logger = Logger(subsystem: "com.idevtango", category: "ContentView")
    
    var body: some View {
        DeckListView()
            .task {
                // 初回のみ初期データを投入
                if !hasSeededData {
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
    
    /// 用語集を初期化（GitHubから取得、キャッシュフォールバック付き）
    /// GitHub JSONをSingle Source of Truthとして扱う
    private func initializeGlossary() async {
        logger.info("🚀 用語集の初期化を開始")
        
        // キャッシュが存在しない場合は強制的にGitHubから取得（初回起動時）
        let cacheExists = GlossaryCacheService.shared.getCachedGlossary() != nil
        let forceUpdate = !cacheExists
        
        if forceUpdate {
            logger.info("📥 キャッシュが存在しないため、GitHubから強制取得します")
        }
        
        do {
            // GitHubから取得を試みる（初回起動時は強制更新）
            try await GlossarySyncService.shared.syncGlossary(context: modelContext, forceUpdate: forceUpdate)
            logger.info("✅ 用語集の初期化が完了しました")
        } catch {
            logger.error("❌ 用語集の初期化に失敗: \(error.localizedDescription)")
            
            // エラー時はキャッシュフォールバックを試みる
            do {
                logger.info("📦 エラー時のフォールバック: キャッシュから読み込みを試みます")
                try await GlossarySyncService.shared.syncGlossary(context: modelContext, forceUpdate: false)
                logger.info("✅ キャッシュから用語集の読み込みが完了しました")
            } catch {
                logger.error("❌ キャッシュからの読み込みも失敗: \(error.localizedDescription)")
                // キャッシュも存在しない場合は、ユーザーにネットワーク接続を促す
                // GitHub JSONがSingle Source of Truthのため、ハードコードデータは使用しない
            }
        }
    }
    
    /// 必要に応じて用語集を同期
    private func syncGlossaryIfNeeded() async {
        guard GlossarySyncService.shared.shouldCheckForUpdate() else {
            return
        }
        
        logger.info("🔄 用語集の定期同期を開始")
        
        do {
            try await GlossarySyncService.shared.syncGlossary(context: modelContext, forceUpdate: false)
            logger.info("✅ 用語集の定期同期が完了しました")
        } catch {
            logger.error("⚠️ 用語集の定期同期に失敗: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Deck.self, Card.self, ActivityLog.self])
}
