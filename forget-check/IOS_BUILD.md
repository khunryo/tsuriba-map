# 忘れ物チェック iOSビルド手順

## 現在の構成

- Capacitor 8 / WKWebView
- アプリ画面と全データを端末内に保持するオフライン構成
- 広告、ログイン、解析、外部API、端末権限なし
- 仮Bundle ID: `jp.khunryo.forgetcheck`
- 最低対応OS: iOS 15

## Sideloadly用の未署名IPA

釣りアプリと同じく、CodemagicのMacで未署名IPAを作成する。

1. この `forget-check` フォルダを独立したGitリポジトリとしてCodemagicへ登録する。
2. `codemagic.yaml` の `ios-debug-unsigned` を選ぶ。
3. `forget-check-ios-build-*` 形式のタグをpushしてビルドを開始する。
4. 成功後、Artifactsから `ForgetCheck-unsigned.ipa` をダウンロードする。
5. WindowsのSideloadlyでIPAを選択し、自分のApple Accountで署名してiPhoneへ導入する。

Sideloadlyでの署名期限や再署名条件はApple Accountの種類に依存する。アプリ本体はiOS 15以降のiPhone/iPadを対象とし、特定のiPhone機種には依存しない。

## 実機デバッグ項目

- 初回起動、2秒のタイトル画面、種類選択
- テンプレート追加・名称変更・アイコン変更・並び替え
- チェック、一時保存、クリア、復元
- アプリ終了後・端末再起動後のデータ保持
- 機内モードでの全操作
- ノッチ、Dynamic Island、ホームインジケータ付近の表示
- 文字サイズ変更時のボタンと入力欄

## App Store登録へ進むとき

1. Apple DeveloperでBundle IDを確定する。
2. `capacitor.config.json` とXcodeプロジェクトのBundle IDを一致させる。
3. CodemagicのApp Store Connect連携と配布証明書を設定する。
4. `ios-testflight` で署名済みIPAを作り、まずTestFlightへアップロードする。
5. プライバシー申告は「収集なし」を、実装と最終確認した上で回答する。

App Store審査では、単なるWebサイトのラッパーではなく十分な実用性が求められる。忘れ物チェックはオフライン利用、端末内テンプレート、進捗、一時保存、ネイティブ振動を備えるが、審査結果を保証するものではない。
