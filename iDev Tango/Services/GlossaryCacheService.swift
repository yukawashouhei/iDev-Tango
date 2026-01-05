//
//  GlossaryCacheService.swift
//  iDev Tango
//
//  用語集のローカルキャッシュ管理サービス
//  オフライン対応のためのキャッシュ機能
//
//  メモリ効率化: UserDefaultsではなくファイル保存を使用
//  （UserDefaultsはアプリ起動時に全データがメモリにロードされるため、
//   大きなデータには不適切）
//

import Foundation
import os.log

@MainActor
class GlossaryCacheService {
    static let shared = GlossaryCacheService()
    
    // ログ用のサブシステム
    private let logger = Logger(subsystem: "com.idevtango", category: "GlossaryCacheService")
    
    private init() {
        // 旧UserDefaultsデータの移行（一度だけ実行）
        migrateFromUserDefaultsIfNeeded()
    }
    
    // UserDefaultsのキー（最終更新日のみ - 小さなデータなのでOK）
    private let lastUpdateKey = "glossary_last_update"
    
    // 旧UserDefaultsキー（移行用）
    private let legacyCacheKey = "glossary_cache"
    
    // MARK: - ファイルパス
    
    /// キャッシュファイルのURL（Cachesディレクトリに保存）
    private var cacheFileURL: URL {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return cachesDirectory.appendingPathComponent("glossary_cache.json")
    }
    
    // MARK: - 移行処理
    
    /// 旧UserDefaultsからファイルへの移行（一度だけ実行）
    private func migrateFromUserDefaultsIfNeeded() {
        // 既にファイルが存在する場合は移行不要
        if FileManager.default.fileExists(atPath: cacheFileURL.path) {
            return
        }
        
        // 旧UserDefaultsにデータがある場合は移行
        if let legacyData = UserDefaults.standard.data(forKey: legacyCacheKey) {
            do {
                try legacyData.write(to: cacheFileURL)
                // 移行完了後、旧データを削除
                UserDefaults.standard.removeObject(forKey: legacyCacheKey)
                logger.info("✅ UserDefaultsからファイルへの移行が完了しました")
            } catch {
                logger.error("❌ 移行に失敗: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - キャッシュ操作
    
    /// キャッシュされた用語集データを取得
    /// - Returns: キャッシュされたデータ（存在しない場合はnil）
    func getCachedGlossary() -> GlossaryData? {
        guard FileManager.default.fileExists(atPath: cacheFileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: cacheFileURL)
            let glossaryData = try JSONDecoder().decode(GlossaryData.self, from: data)
            return glossaryData
        } catch {
            logger.error("❌ キャッシュの読み込みに失敗: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 用語集データをキャッシュに保存
    /// - Parameter glossaryData: 保存する用語集データ
    func saveCache(_ glossaryData: GlossaryData) {
        do {
            let data = try JSONEncoder().encode(glossaryData)
            try data.write(to: cacheFileURL)
            UserDefaults.standard.set(Date(), forKey: lastUpdateKey)
            logger.info("✅ キャッシュを保存しました（ファイル: \(self.cacheFileURL.lastPathComponent)）")
        } catch {
            logger.error("❌ キャッシュの保存に失敗: \(error.localizedDescription)")
        }
    }
    
    /// 最終更新日を取得
    /// - Returns: 最終更新日（キャッシュがない場合はnil）
    func getLastUpdateDate() -> Date? {
        return UserDefaults.standard.object(forKey: lastUpdateKey) as? Date
    }
    
    /// キャッシュをクリア
    func clearCache() {
        do {
            if FileManager.default.fileExists(atPath: cacheFileURL.path) {
                try FileManager.default.removeItem(at: cacheFileURL)
            }
        UserDefaults.standard.removeObject(forKey: lastUpdateKey)
        logger.info("✅ キャッシュをクリアしました")
        } catch {
            logger.error("❌ キャッシュのクリアに失敗: \(error.localizedDescription)")
        }
    }
    
    /// キャッシュが有効かどうかを判定（24時間以内）
    /// - Returns: キャッシュが有効な場合true
    func isCacheValid() -> Bool {
        guard let lastUpdate = getLastUpdateDate() else {
            return false
        }
        
        let now = Date()
        let timeInterval = now.timeIntervalSince(lastUpdate)
        let hours24: TimeInterval = 24 * 60 * 60
        
        return timeInterval < hours24
    }
}
