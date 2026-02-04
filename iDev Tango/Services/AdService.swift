//
//  AdService.swift
//  iDev Tango
//
//  広告管理サービス
//  Google AdMobによるバナー広告の管理
//

import Foundation
import GoogleMobileAds
import AppTrackingTransparency
import OSLog

// MARK: - AdService

/// 広告管理サービス（シングルトン）
@MainActor
final class AdService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = AdService()
    
    // MARK: - Properties
    
    /// 広告の読み込み状態
    @Published private(set) var isAdLoaded = false
    
    /// 広告を表示するかどうか（サブスク購入者はfalse）
    @Published var shouldShowAds = true
    
    /// SDK初期化完了フラグ
    private var isInitialized = false
    
    /// ATTリクエスト完了フラグ
    private var hasRequestedATT = false
    
    private let logger = Logger(subsystem: "com.idevtango", category: "AdService")
    
    // MARK: - Test Device IDs
    
    /// テストデバイスID（DEBUGビルドのみ使用）
    /// AdMobコンソールログに出力されるIDを設定
    /// 本番リリース時は自動的に無効化される
    #if DEBUG
    private static let testDeviceIdentifiers = [
        "add61519413508fe70a1e9421c942efe"  // 開発用iPhone 11 Pro
    ]
    #else
    private static let testDeviceIdentifiers: [String] = []
    #endif
    
    // MARK: - Ad Unit IDs
    
    /// バナー広告ユニットID
    #if DEBUG
    static let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716" // テスト用
    #else
    static let bannerAdUnitID = "ca-app-pub-6898713833552918/1214353514" // 本番用
    #endif
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// AdMob SDKを初期化（ATTリクエストなし、アプリ起動時に呼ぶ）
    func initialize() {
        guard !isInitialized else { return }
        
        logger.info("📢 AdMob SDK初期化を開始")
        
        // テストデバイスを設定
        if !Self.testDeviceIdentifiers.isEmpty {
            MobileAds.shared.requestConfiguration.testDeviceIdentifiers = Self.testDeviceIdentifiers
            logger.info("📱 テストデバイスを設定: \(Self.testDeviceIdentifiers)")
        }
        
        // AdMob SDKを初期化
        MobileAds.shared.start { [weak self] status in
            Task { @MainActor in
                self?.logger.info("✅ AdMob SDK初期化完了")
                self?.isInitialized = true
                self?.isAdLoaded = true
            }
        }
    }
    
    /// App Tracking Transparencyの許可をリクエスト
    /// アプリがアクティブになってから呼び出すこと（onAppear等で使用）
    func requestTrackingAuthorizationIfNeeded() {
        guard !hasRequestedATT else { return }
        hasRequestedATT = true
        
        logger.info("📢 ATTリクエストを開始")
        
        // iOS 14以上でATTをリクエスト
        guard #available(iOS 14, *) else {
            logger.info("ℹ️ iOS 14未満のためATTリクエストをスキップ")
            return
        }
        
        // 現在の状態を確認
        let currentStatus = ATTrackingManager.trackingAuthorizationStatus
        if currentStatus != .notDetermined {
            // 既に決定済みの場合はリクエストしない
            logTrackingStatus(currentStatus)
            return
        }
        
        // アプリがアクティブになるまで少し待ってからダイアログを表示
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            ATTrackingManager.requestTrackingAuthorization { status in
                Task { @MainActor in
                    self?.logTrackingStatus(status)
                }
            }
        }
    }
    
    /// サブスクリプション状態に基づいて広告表示を更新
    func updateAdVisibility(isPremium: Bool) {
        shouldShowAds = !isPremium
        logger.info("📢 広告表示状態を更新: \(self.shouldShowAds ? "表示" : "非表示")")
    }
    
    // MARK: - Private Methods
    
    /// トラッキング許可状態をログ出力
    private func logTrackingStatus(_ status: ATTrackingManager.AuthorizationStatus) {
        switch status {
        case .authorized:
            logger.info("✅ トラッキング許可: authorized - パーソナライズ広告が有効")
        case .denied:
            logger.info("⚠️ トラッキング許可: denied - 一般広告を表示")
        case .restricted:
            logger.info("⚠️ トラッキング許可: restricted - 一般広告を表示")
        case .notDetermined:
            logger.info("⚠️ トラッキング許可: notDetermined")
        @unknown default:
            logger.info("⚠️ トラッキング許可: unknown")
        }
    }
}

