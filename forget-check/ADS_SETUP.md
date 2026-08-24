# Forget Check 広告設定

## 現在の実装

- 広告SDK: `@capacitor-community/admob` 8.1.0
- 表示形式: iOSの小型バナー広告
- 表示画面: 種類選択、テンプレート編集
- 非表示画面: チェック、進捗、一時保存、復元、クリア、完了表示、起動画面
- 広告リクエスト: 非パーソナライズ（`npa: true`）
- 課金: 今回は実装しない
- デバッグ用ID: Google AdMobのテストアプリID・テストバナーID

広告が読み込めなくても、チェックリストの操作は継続できます。持ち物・テンプレート・チェック状態を広告SDKへ渡すコードはありません。

## 公開前に必要な差し替え

1. AdMobでiOSアプリとバナー広告ユニットを作成する。
2. `index.html` の `AD_CONFIG.appId` と `AD_CONFIG.bannerId` を本番IDへ差し替える。
3. `ios/App/App/Info.plist` の `GADApplicationIdentifier` を本番アプリIDへ差し替える。
4. `AD_CONFIG.testing` を `false` にする。
5. AdMobの同意メッセージ、広告内容の年齢上限、プライバシー設定を確認する。
6. App Store ConnectのApp Privacy回答とプライバシーポリシーを、実際のAdMob設定に合わせて最終確認する。

テストIDのままでは収益化されません。本番IDへ差し替えた後に、実機で広告表示・広告がない場合の操作・アプリ復帰を確認してから審査用ビルドを作成します。
