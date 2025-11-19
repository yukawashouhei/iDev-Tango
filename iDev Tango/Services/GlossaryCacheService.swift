//
//  GlossaryCacheService.swift
//  iDev Tango
//
//  用語集のローカルキャッシュ管理サービス
//  オフライン対応のためのキャッシュ機能
//

import Foundation

@MainActor
class GlossaryCacheService {
    static let shared = GlossaryCacheService()
    
    private init() {}
    
    // UserDefaultsのキー
    private let cacheKey = "glossary_cache"
    private let lastUpdateKey = "glossary_last_update"
    
    /// キャッシュされた用語集データを取得
    /// - Returns: キャッシュされたデータ（存在しない場合はnil）
    func getCachedGlossary() -> GlossaryData? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else {
            return nil
        }
        
        do {
            let glossaryData = try JSONDecoder().decode(GlossaryData.self, from: data)
            return glossaryData
        } catch {
            print("❌ キャッシュの読み込みに失敗: \(error)")
            return nil
        }
    }
    
    /// 用語集データをキャッシュに保存
    /// - Parameter glossaryData: 保存する用語集データ
    func saveCache(_ glossaryData: GlossaryData) {
        do {
            let data = try JSONEncoder().encode(glossaryData)
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(Date(), forKey: lastUpdateKey)
            print("✅ キャッシュを保存しました")
        } catch {
            print("❌ キャッシュの保存に失敗: \(error)")
        }
    }
    
    /// 最終更新日を取得
    /// - Returns: 最終更新日（キャッシュがない場合はnil）
    func getLastUpdateDate() -> Date? {
        return UserDefaults.standard.object(forKey: lastUpdateKey) as? Date
    }
    
    /// キャッシュをクリア
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        UserDefaults.standard.removeObject(forKey: lastUpdateKey)
        print("✅ キャッシュをクリアしました")
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

