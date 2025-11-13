//
//  iDev_TangoApp.swift
//  iDev Tango
//
//  Apple Intelligence搭載 AI単語帳アプリ
//  iOS 26のFoundation Models Frameworkを使用
//

import SwiftUI
import SwiftData

@main
struct iDev_TangoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Deck.self, Card.self, ActivityLog.self])
    }
}
