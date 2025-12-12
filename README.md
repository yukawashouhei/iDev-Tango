# iDev Tango

Gemini 1.5 Flash-8B + Firebase AI Logic + App Checkを使用したAI単語帳アプリ

## 概要

iDev Tangoは、Firebase AI LogicとGemini 1.5 Flash-8Bを使用したAI単語帳アプリです。アプリエンジニア向けの技術用語を効率的に学習できます。App Checkにより、セキュアなAI API呼び出しを実現しています。

## 主な機能

### 🤖 AI定義生成
- **クラウドAI**: Firebase AI Logic + Gemini 1.5 Flash-8Bを使用
- **高精度**: Gemini 1.5 Flash-8Bによる高品質な定義生成
- **セキュリティ**: App CheckによるAPI保護

### 📚 単語帳機能
- **フォルダ管理**: テーマ別に単語を整理
- **編集機能**: タップで単語と定義を編集可能

## 開発環境
- **言語**: Swift 6.2
- **フレームワーク**: SwiftUI
- **データベース**: SwiftData
- **アーキテクチャ**: SwiftUI + SwiftData（@Queryを使用したリアクティブなデータ管理）
- **AI**: Firebase AI Logic + Gemini 1.5 Flash-8B
- **セキュリティ**: Firebase App Check（DeviceCheck）
- **対象OS**: iOS 18.0+

## セットアップ

Firebaseのセットアップ手順については、[FIREBASE_SETUP.md](FIREBASE_SETUP.md)を参照してください。

### 必要な手順
1. Firebaseプロジェクトの作成
2. iOSアプリの登録
3. Firebase SDKの追加（Swift Package Manager）
4. Firebase AI Logicの有効化
5. App Checkの設定
6. `GoogleService-Info.plist`の追加
