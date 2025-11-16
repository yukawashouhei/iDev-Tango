# iDev Tango

Apple Intelligence搭載のAI単語帳アプリ

## 概要

iDev Tangoは、iOS 26のFoundation Models Frameworkを使用したAI単語帳アプリです。アプリエンジニア向けの技術用語を効率的に学習できます。

## 主な機能

### 🤖 AI定義生成
- **オンデバイスAI**: Foundation Models Frameworkを使用
- **プライバシー保護**: インターネット接続不要、端末内で完結

### 📚 単語帳機能
- **フォルダ管理**: テーマ別に単語を整理
- **編集機能**: タップで単語と定義を編集可能


### 開発環境
- **言語**: Swift 6.2
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
- **言語**: 日本語での定義生成
