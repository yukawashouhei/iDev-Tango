# Firebaseセットアップ手順

このドキュメントでは、Gemini 1.5 Flash-8B + Firebase AI Logic + App Checkのセットアップ手順を説明します。

## 1. Firebaseプロジェクトの作成

1. [Firebaseコンソール](https://console.firebase.google.com/)にアクセス
2. 「プロジェクトを追加」をクリック
3. プロジェクト名を入力（例: "iDev Tango"）
4. Google Analyticsの設定（オプション）
5. プロジェクトを作成

## 2. iOSアプリの登録

1. Firebaseコンソールでプロジェクトを開く
2. 「iOSアプリを追加」をクリック
3. バンドルIDを入力: `com.perksh.iDevTango`
4. アプリのニックネームを入力（オプション）
5. `GoogleService-Info.plist`をダウンロード
6. ダウンロードした`GoogleService-Info.plist`をXcodeプロジェクトの`iDev Tango`フォルダに追加
   - Xcodeでプロジェクトを開く
   - `GoogleService-Info.plist`をドラッグ&ドロップ
   - 「Copy items if needed」にチェック
   - 「Add to targets: iDev Tango」にチェック

## 3. Firebase SDKの追加（Swift Package Manager）

1. Xcodeでプロジェクトを開く
2. プロジェクトナビゲーターでプロジェクトを選択
3. 「Package Dependencies」タブを選択
4. 「+」ボタンをクリック
5. 以下のURLを入力: `https://github.com/firebase/firebase-ios-sdk`
6. 「Add Package」をクリック
7. 以下のパッケージを選択して追加:
   - `FirebaseCore`
   - `FirebaseAppCheck`
   - `FirebaseAI`
8. 「Add Package」をクリック

## 4. Firebase AI Logicの有効化

1. Firebaseコンソールでプロジェクトを開く
2. 左側のメニューから「AI Logic」を選択（または「Build」→「AI Logic」）
3. 「Get started」をクリック
4. Gemini Developer APIを有効化
5. APIキーを設定（Firebaseコンソールで自動的に設定されます）

## 5. App Checkの設定

1. Firebaseコンソールでプロジェクトを開く
2. 左側のメニューから「App Check」を選択（または「Build」→「App Check」）
3. 「Get started」をクリック
4. iOSアプリを選択
5. プロバイダとして「DeviceCheck」を選択
6. 「Save」をクリック

### App Checkのデバッグ設定

開発中はデバッグトークンを使用できます：

1. App Checkの設定画面で「Manage debug tokens」をクリック
2. アプリを実行してコンソールに表示されるデバッグトークンをコピー
3. Firebaseコンソールにデバッグトークンを追加

## 6. ビルドとテスト

1. Xcodeでプロジェクトを開く
2. ビルド（⌘+B）してエラーがないか確認
3. 実機またはシミュレーターで実行
4. 単語を追加してAI定義生成機能をテスト

## トラブルシューティング

### エラー: "FirebaseApp.configure()" が失敗する
- `GoogleService-Info.plist`が正しくプロジェクトに追加されているか確認
- バンドルIDがFirebaseコンソールで登録したものと一致しているか確認

### エラー: App Checkのトークンが取得できない
- DeviceCheckプロバイダがFirebaseコンソールで正しく設定されているか確認
- 実機でテストしているか確認（シミュレーターではDeviceCheckが動作しない場合があります）

### エラー: Gemini APIが呼び出せない
- Firebase AI Logicが有効化されているか確認
- APIキーが正しく設定されているか確認
- App Checkが正しく設定されているか確認

## 注意事項

- `GoogleService-Info.plist`は`.gitignore`に追加されているため、Gitにコミットされません
- 各開発者はFirebaseコンソールから個別に`GoogleService-Info.plist`をダウンロードする必要があります
- App CheckのDeviceCheckプロバイダは実機でのテストが必要です
- デバッグビルドではApp Checkのデバッグプロバイダが使用されます


