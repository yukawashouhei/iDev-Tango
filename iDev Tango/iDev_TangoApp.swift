//
//  iDev_TangoApp.swift
//  iDev Tango
//
//  Gemini 2.5 Flash-Lite + Firebase AI Logic + App Checkを使用したAI単語帳アプリ
//

import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseAppCheck

// App Checkプロバイダファクトリー
final class CustomAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        #if DEBUG
        // デバッグビルドではデバッグプロバイダを使用
        return AppCheckDebugProviderFactory().createProvider(with: app)
        #else
        // リリースビルドではDeviceCheckプロバイダを使用
        return DeviceCheckProvider(app: app)
        #endif
    }
}

@main
struct iDev_TangoApp: App {
    init() {
        // App Checkプロバイダを設定
        AppCheck.setAppCheckProviderFactory(CustomAppCheckProviderFactory())
        
        // Firebaseを初期化
        FirebaseApp.configure()
        
        // バックグラウンドタスクを登録
        GlossaryBackgroundTaskService.shared.registerBackgroundTask()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // バックグラウンドタスクをスケジュール
                    GlossaryBackgroundTaskService.shared.scheduleBackgroundTask()
                }
        }
        .modelContainer(for: [Deck.self, Card.self, ActivityLog.self])
    }
}
