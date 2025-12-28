# iDev Tango

Gemini 2.5 Flash-Lite + Firebase AI Logic + App Checkを使用したAI単語帳アプリ

## 概要

iDev Tangoは、Firebase AI LogicとGemini 2.5 Flash-Liteを使用したAI単語帳アプリです。アプリエンジニア向けの技術用語を効率的に学習できます。App Checkにより、セキュアなAI API呼び出しを実現しています。

## 主な機能

### 🤖 AI定義生成
- **クラウドAI**: Firebase AI Logic + Gemini 2.5 Flash-Liteを使用
- **高精度**: Gemini 2.5 Flash-Liteによる高品質な定義生成
- **セキュリティ**: App CheckによるAPI保護

### 📚 単語帳機能
- **フォルダ管理**: テーマ別に単語を整理
- **編集機能**: タップで単語と定義を編集可能
- **GitHub同期**: GitHubリポジトリから用語集を自動取得

### 📖 学習機能
- **フラッシュカード**: スワイプで学習
- **理解度管理**: 理解度に応じた復習
- **学習履歴**: 学習状況のトラッキング

## 開発環境
- **言語**: Swift 6.2
- **フレームワーク**: SwiftUI
- **データベース**: SwiftData
- **アーキテクチャ**: SwiftUI + SwiftData（@Queryを使用したリアクティブなデータ管理）
- **AI**: Firebase AI Logic + Gemini 2.5 Flash-Lite
- **セキュリティ**: Firebase App Check（DeviceCheck / App Attest）
- **対象OS**: iOS 18.0+

## プロジェクト構造

```
iDev Tango/
├── Models/
│   ├── ActivityLog.swift      # 学習履歴
│   ├── Card.swift             # 単語カード
│   ├── Deck.swift             # デッキ（フォルダ）
│   └── UnderstandingLevel.swift # 理解度
├── Services/
│   ├── AIService.swift        # AI定義生成（Gemini 2.5 Flash-Lite）
│   ├── GlossarySyncService.swift # GitHub用語集同期
│   ├── GlossaryCacheService.swift # キャッシュ管理
│   ├── LearningService.swift  # 学習ロジック
│   └── CompletionMessageService.swift # 達成メッセージ
├── Views/
│   └── Main/
│       ├── DeckListView.swift # デッキ一覧
│       ├── CardListView.swift # カード一覧
│       ├── AddCardView.swift  # カード追加
│       ├── LearningView.swift # 学習画面
│       └── ConfettiView.swift # 紙吹雪エフェクト
├── ContentView.swift          # メインエントリーポイント
└── iDev_TangoApp.swift        # アプリ設定・Firebase初期化
```

## セットアップ

Firebaseのセットアップ手順については、[FIREBASE_SETUP.md](FIREBASE_SETUP.md)を参照してください。

### 必要な手順
1. Firebaseプロジェクトの作成
2. iOSアプリの登録
3. Firebase SDKの追加（Swift Package Manager）
4. Firebase AI Logicの有効化（Gemini Developer API）
5. App Checkの設定（DeviceCheck / App Attest）
6. `GoogleService-Info.plist`の追加
7. Blazeプラン（従量課金）へのアップグレード

## 注意事項

- `GoogleService-Info.plist`は`.gitignore`に含まれるため、各開発者は個別にダウンロードが必要です
- Gemini APIの利用にはBlazeプラン（従量課金）が必要です
- 開発時はApp Checkのデバッグトークンが必要です
