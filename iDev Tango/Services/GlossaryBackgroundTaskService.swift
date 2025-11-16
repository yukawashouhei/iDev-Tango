//
//  GlossaryBackgroundTaskService.swift
//  iDev Tango
//
//  バックグラウンドタスクサービス
//  1日1回の用語集更新チェックを実行
//

import Foundation
import BackgroundTasks

@MainActor
class GlossaryBackgroundTaskService {
    static let shared = GlossaryBackgroundTaskService()
    
    private init() {}
    
    // バックグラウンドタスクの識別子（Info.plistで登録が必要）
    static let backgroundTaskIdentifier = "com.idevtango.glossary-sync"
    
    /// バックグラウンドタスクを登録
    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.backgroundTaskIdentifier,
            using: nil
        ) { task in
            self.handleBackgroundTask(task: task as! BGAppRefreshTask)
        }
    }
    
    /// バックグラウンドタスクをスケジュール
    func scheduleBackgroundTask() {
        let request = BGAppRefreshTaskRequest(identifier: Self.backgroundTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 24 * 60 * 60) // 24時間後
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ バックグラウンドタスクをスケジュールしました")
        } catch {
            print("❌ バックグラウンドタスクのスケジュールに失敗: \(error)")
        }
    }
    
    /// バックグラウンドタスクのハンドラー
    private func handleBackgroundTask(task: BGAppRefreshTask) {
        print("🔄 バックグラウンドタスクを実行中...")
        
        // タスクの期限を設定（30秒）
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // バックグラウンドタスクでは、実際の同期は行わず
        // 次回アプリ起動時に同期が必要であることを通知するだけ
        // （ModelContextはバックグラウンドタスクから取得できないため）
        UserDefaults.standard.set(true, forKey: "glossary_sync_needed")
        
        // 次のバックグラウンドタスクをスケジュール
        scheduleBackgroundTask()
        
        task.setTaskCompleted(success: true)
        print("✅ バックグラウンドタスクが完了しました（次回起動時に同期予定）")
    }
}

