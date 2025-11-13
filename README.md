# iDev Tango

Apple Intelligence搭載のAI単語帳アプリ

## 概要

iDev Tangoは、iOS 26のFoundation Models Frameworkを使用したAI単語帳アプリです。アプリエンジニア向けの技術用語を効率的に学習できます。

## 主な機能

### 🤖 AI定義生成
- **オンデバイスAI**: Foundation Models Frameworkを使用
- **専門家モード**: Mobile、iOS、Swift、SwiftUIの専門家として設定
- **簡潔な定義**: 100字以内の1〜2文で本質のみを説明
- **プライバシー保護**: インターネット接続不要、データは端末内で完結

### 📚 単語帳機能
- **フォルダ管理**: テーマ別に単語を整理
- **カードフリップ**: Apple公式推奨の3Dアニメーション
- **学習モード**: カードをめくりながら効率的に学習
- **編集機能**: タップで単語と定義を編集可能

### 🎨 美しいUI
- **グラデーション背景**: 淡い青から淡い紫へのグラデーション
- **白い角丸カード**: 影付きで立体感のあるデザイン
- **横長カード**: 340×200ptの固定サイズで統一感
- **ダークモード対応**: ライト・ダークテーマ両対応

## 技術仕様

### 開発環境
- **言語**: Swift 6.0
- **フレームワーク**: SwiftUI
- **データベース**: SwiftData
- **アーキテクチャ**: MVVM
- **AI**: Foundation Models Framework
- **対象OS**: iOS 18.0+

### プロジェクト構造
```
iDev Tango/
├── Models/           # データモデル
│   ├── Deck.swift
│   ├── Card.swift
│   └── ActivityLog.swift
├── ViewModels/       # ViewModel
│   ├── DeckListViewModel.swift
│   └── CardListViewModel.swift
├── Views/           # SwiftUIビュー
│   └── Main/
│       ├── DeckListView.swift
│       ├── CardListView.swift
│       ├── AddCardView.swift
│       └── LearningView.swift
├── Services/        # サービス層
│   └── AIService.swift
└── Assets.xcassets/ # アセット
```

## 使用方法

### 1. フォルダ作成
- アプリ起動後、「＋フォルダ名」ボタンをタップ
- フォルダ名を入力して作成

### 2. 単語登録
- フォルダをタップして単語一覧画面へ
- 「追加」ボタンで単語登録画面を開く
- 単語を入力後、「意味を確認」ボタンでAI定義生成
- 必要に応じて定義を編集して保存

### 3. 学習
- 単語一覧画面で「学習する」ボタンをタップ
- カードをタップして表裏を切り替え
- 「次へ」ボタンで次のカードへ進む

## AI機能について

### 利用条件
- **対応端末**: Apple Intelligence対応のiPhone/iPad
- **設定**: Apple Intelligenceが有効になっている必要があります
- **言語**: 日本語での定義生成に対応

### プロンプト設計
```
あなたはMobile、iOS、Swift、SwiftUIの専門家です。
以下の単語について、簡潔な意味を100字以内の1〜2文で提供してください。

重要な制約：
- 説明は短ければ短いほど優れています
- 説明はわかりやすければわかりやすいほど優れています
- **、```などのマークダウン記号は使用しない
- 例文は含めない
- 簡潔に本質のみを説明する
- 100字以内 1〜2行程度に収める
```

## ビルド方法

1. Xcode 26.0以上でプロジェクトを開く
2. iOS 18.0以上のシミュレータまたは実機を選択
3. ビルドして実行

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。

## 貢献

プルリクエストやイシューの報告を歓迎します。

---

**iDev Tango** - Apple Intelligenceで学ぶ、新しい単語帳体験 🚀
