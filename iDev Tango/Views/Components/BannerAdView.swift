//
//  BannerAdView.swift
//  iDev Tango
//
//  バナー広告表示ビュー
//  Google AdMobのバナー広告をSwiftUIで表示
//

import SwiftUI
import GoogleMobileAds

// MARK: - BannerAdView

/// バナー広告を表示するSwiftUIビュー
struct BannerAdView: View {
    
    // MARK: - Properties
    
    @ObservedObject private var adService = AdService.shared
    
    /// バナーの高さ（Adaptive Bannerの標準高さ）
    private let bannerHeight: CGFloat = 50
    
    // MARK: - Body
    
    var body: some View {
        if adService.shouldShowAds {
            BannerAdRepresentable()
                .frame(height: bannerHeight)
                .background(Color(.systemBackground))
        }
    }
}

// MARK: - BannerAdRepresentable

/// UIViewRepresentableでAdMobバナーをラップ
struct BannerAdRepresentable: UIViewRepresentable {
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        
        // バナー広告ビューを作成（標準バナーサイズ: 320x50）
        let bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = AdService.bannerAdUnitID
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        
        // ルートビューコントローラーを取得して設定
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            bannerView.rootViewController = rootViewController
        }
        
        containerView.addSubview(bannerView)
        
        // 制約を設定
        NSLayoutConstraint.activate([
            bannerView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            bannerView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
        
        // 広告をロード
        bannerView.load(Request())
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // 更新は不要
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()
        Text("コンテンツエリア")
        Spacer()
        BannerAdView()
    }
}

