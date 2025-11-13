//
//  UnderstandingLevel.swift
//  iDev Tango
//
//  理解度レベル管理
//  間隔反復学習のための理解度定義
//

import Foundation

enum UnderstandingLevel: Int, CaseIterable {
    case new = 0        // 新規（毎回出題）
    case difficult = 1  // 難しい（頻繁に出題）
    case learning = 2   // 学習中（中程度）
    case familiar = 3   // 慣れてきた（少なめ）
    case mastered = 4   // 習得済み（稀に出題）
    case expert = 5     // 完全習得（ほぼ出題しない）
    
    var displayName: String {
        switch self {
        case .new: return "新規"
        case .difficult: return "難しい"
        case .learning: return "学習中"
        case .familiar: return "慣れてきた"
        case .mastered: return "習得済み"
        case .expert: return "完全習得"
        }
    }
    
    var nextReviewInterval: TimeInterval {
        switch self {
        case .new: return 0          // 即座
        case .difficult: return 3600 // 1時間後
        case .learning: return 86400 // 1日後
        case .familiar: return 259200 // 3日後
        case .mastered: return 604800 // 1週間後
        case .expert: return 2592000 // 1ヶ月後
        }
    }
    
    var weight: Int {
        switch self {
        case .new: return 5        // 最高優先度
        case .difficult: return 4
        case .learning: return 3
        case .familiar: return 2
        case .mastered: return 1
        case .expert: return 0     // 出題しない
        }
    }
}
