# 潮目 iOSビルド手順

## 現在の構成

- Capacitor 8 / WKWebView
- アプリ画面は `www` に同梱
- 潮位・投稿・投稿写真は `https://shiome-fishing.khunryo.chatgpt.site` のAPIを利用
- 仮Bundle ID: `com.khunryo.shiome`（App Store Connectで登録する前に確定する）
- 最低対応OS: iOS 15

## Macで最初に行うこと

1. Node.js 22以上、Xcode 26以上、Xcode Command Line Toolsを準備する。
2. このリポジトリで `npm install` を実行する。
3. `npm run ios:sync` を実行して最新の画面をiOSプロジェクトへ同期する。
4. `npm run ios:open` でXcodeを開く。
5. Signing & CapabilitiesでApple Developer Teamを選び、実機で確認する。

iOSプロジェクト、カメラ・写真権限、プライバシーマニフェスト、アプリアイコン、ネイティブ起動画面はすでに追加済み。

2回目以降は、Web画面を変更したあとに `npm run ios:sync` を実行する。

## TestFlight前の必須確認

- Bundle IDを確定し、App Store Connectのアプリレコードと一致させる
- 1024×1024のApp Storeアイコンを用意する
- プライバシーポリシー、利用規約、投稿削除・通報導線を公開する
- APIを一般ユーザーが利用できる公開構成へ切り替える
- 機内モード、低速回線、写真権限拒否、投稿失敗時の表示を実機確認する
- 投稿型サービスとして不適切投稿の通報・非表示・管理者対応を実装する
- App Storeのプライバシー申告を `mobile/PrivacyInfo.xcprivacy` と一致させる

## アーカイブと提出

Xcodeで `Any iOS Device (arm64)` を選び、Product → Archiveを実行する。Organizerで検証後、App Store Connectへアップロードし、まずTestFlightで実機テストを行う。
