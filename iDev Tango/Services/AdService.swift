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
    
    /// 初期化完了フラグ
    private var isInitialized = false
    
    private let logger = Logger(subsystem: "com.idevtango", category: "AdService")
    
    // MARK: - Ad Unit IDs
    
    /// バナー広告ユニットID
    /// 本番環境では実際の広告ユニットIDに置き換えてください
    #if DEBUG
    static let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716" // テスト用
    #else
    static let bannerAdUnitID = "ca-app-pub-XXXXX/XXXXX" // 本番用（要置き換え）
    #endif
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// AdMob SDKを初期化
    func initialize() {
        guard !isInitialized else { return }
        
        logger.info("📢 AdMob SDK初期化を開始")
        
        // App Tracking Transparencyの許可をリクエスト
        requestTrackingAuthorization { [weak self] in
            // AdMob SDKを初期化
            MobileAds.shared.start { [weak self] status in
                self?.logger.info("✅ AdMob SDK初期化完了")
                self?.isInitialized = true
                
                // 初期化完了後に広告読み込み状態を更新
                DispatchQueue.main.async {
                    self?.isAdLoaded = true
                }
            }
        }
    }
    
    /// App Tracking Transparencyの許可をリクエスト
    private func requestTrackingAuthorization(completion: @escaping () -> Void) {
        // iOS 14以上でATTをリクエスト
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                switch status {
                case .authorized:
                    self.logger.info("✅ トラッキング許可: authorized")
                case .denied:
                    self.logger.info("⚠️ トラッキング許可: denied")
                case .restricted:
                    self.logger.info("⚠️ トラッキング許可: restricted")
                case .notDetermined:
                    self.logger.info("⚠️ トラッキング許可: notDetermined")
                @unknown default:
                    self.logger.info("⚠️ トラッキング許可: unknown")
                }
                
                DispatchQueue.main.async {
                    completion()
                }
            }
        } else {
            completion()
        }
    }
    
    /// サブスクリプション状態に基づいて広告表示を更新
    func updateAdVisibility(isPremium: Bool) {
        shouldShowAds = !isPremium
        logger.info("📢 広告表示状態を更新: \(self.shouldShowAds ? "表示" : "非表示")")
    }
}


