//
//  ActivityLog.swift
//  iDev Tango
//
//  学習アクティビティログのデータモデル
//  日付ごとの学習回数を記録
//

import Foundation
import SwiftData

@Model
class ActivityLog {
    @Attribute(.unique) var dateString: String // "2025-10-15"
    var date: Date
    var count: Int
    
    init(date: Date, count: Int = 1) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.dateString = formatter.string(from: date)
        self.date = date
        self.count = count
    }
}
