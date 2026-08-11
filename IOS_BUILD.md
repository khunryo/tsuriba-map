# 潮目 iOSビルド手順

## 現在の構成

- Capacitor 8 / WKWebView
- アプリ画面は `www` に同梱
- 潮位・投稿・投稿写真は `https://shiome-fishing.khunryo.chatgpt.site` のAPIを利用
- 仮Bundle ID: `com.khunryo.shiome`（App Store Connectで登録する前に確定する）
- 最低対応OS: iOS 15

## 推奨: Codemagicでビルドする

Macを所有していなくても、リポジトリ直下の `codemagic.yaml` を使ってクラウド上のMacで署名済みIPAを作成し、App Store Connectへアップロードできる。

1. Apple Developer Programへ登録し、Bundle ID `com.khunryo.shiome` を作成する。
2. App Store Connectで「潮目」のアプリレコードを同じBundle IDで作成する。
3. App Store Connectの「ユーザとアクセス」→「統合」から、App Manager権限のAPIキーを作成して `.p8`、Key ID、Issuer IDを保管する。
4. CodemagicのTeam integrations → Developer PortalへAPIキーを登録し、名前を `shiome-app-store-connect` にする。
5. CodemagicのCode signing identitiesでApple Distribution証明書とApp Store provisioning profileを生成または登録する。
6. CodemagicへGitHubリポジトリを追加し、`codemagic.yaml` を読み込んで `ios-testflight` を実行する。

このワークフローはXcode 26.4 / Node.js 22でWeb画面を生成し、Capacitorへ同期して署名済みIPAを作成する。成功するとIPAをApp Store Connectへアップロードするが、TestFlight外部審査やApp Store審査へは自動提出しない。まずApp Store Connectでビルドを確認し、内部テスターへ割り当てる。

APIキー、証明書、秘密鍵はGitHubへコミットせず、Codemagicの暗号化された設定だけに保存する。

## 任意: Macでローカルビルドする

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

## Macでのアーカイブと提出

Xcodeで `Any iOS Device (arm64)` を選び、Product → Archiveを実行する。Organizerで検証後、App Store Connectへアップロードし、まずTestFlightで実機テストを行う。
