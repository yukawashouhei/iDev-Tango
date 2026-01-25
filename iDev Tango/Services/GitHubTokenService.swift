//
//  GitHubTokenService.swift
//  iDev Tango
//
//  GitHub Personal Access Token管理サービス
//  環境変数または設定ファイルからトークンを安全に取得
//

import Foundation
import OSLog

/// GitHub Token管理サービス（シングルトン）
@MainActor
final class GitHubTokenService {
    
    // MARK: - Singleton
    
    static let shared = GitHubTokenService()
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "com.idevtango", category: "GitHubTokenService")
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// GitHub Personal Access Tokenを取得
    /// 優先順位: 1. 環境変数 2. GitHub-Info.plist
    /// - Returns: GitHub Personal Access Token（見つからない場合はnil）
    func getToken() -> String? {
        // 1. 環境変数から取得を試みる（推奨: XcodeのScheme設定で設定）
        if let token = ProcessInfo.processInfo.environment["GITHUB_TOKEN"],
           !token.isEmpty {
            logger.info("🔐 GitHub Tokenを環境変数から取得しました")
            return token
        }
        
        // 2. GitHub-Info.plistから取得を試みる（.gitignoreに追加済み）
        if let path = Bundle.main.path(forResource: "GitHub-Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let token = plist["GITHUB_TOKEN"] as? String,
           !token.isEmpty {
            logger.info("🔐 GitHub TokenをGitHub-Info.plistから取得しました")
            return token
        }
        
        // Tokenが見つからない場合はnilを返す
        logger.warning("⚠️ GitHub Tokenが見つかりません。環境変数またはGitHub-Info.plistを設定してください。")
        return nil
    }
    
    /// GitHub Tokenが設定されているかどうかを確認
    /// - Returns: Tokenが設定されている場合true
    func hasToken() -> Bool {
        return getToken() != nil
    }
}

