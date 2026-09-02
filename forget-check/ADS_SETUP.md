# Forget Check 広告設定

## 現在の実装

- 広告SDK: `@capacitor-community/admob` 8.1.0
- 表示形式: iOSの小型バナー広告
- 表示画面: 種類選択、テンプレート編集
- 非表示画面: チェック、進捗、一時保存、復元、クリア、完了表示、起動画面
- 広告リクエスト: 非パーソナライズ（`npa: true`）
- 広告削除: StoreKit 2の非消費型App内課金（買い切り）
- Product ID: `jp.khunryo.forgetcheck.removeads`
- 日本価格: 100円（海外価格はApp Store Connectの地域別価格）
- 本番AdMobアプリID: `ca-app-pub-6124353053548665~9419537436`
- 本番バナー広告ユニットID: `ca-app-pub-6124353053548665/6793374096`

広告が読み込めなくても、チェックリストの操作は継続できます。持ち物・テンプレート・チェック状態を広告SDKへ渡すコードはありません。StoreKitが広告削除の購入資格を確認できるまで広告要求を開始せず、購入済みの場合は広告SDKの初期化と広告要求を行いません。

## 登録済みの本番設定

1. Google AdMobアカウント（`khunryo@gmail.com`）にiOSアプリ「Forget Check」を登録済み。
2. バナー広告ユニット「Forget Check Banner」を作成済み。
3. `index.html` と `ios/App/App/Info.plist` に本番IDを反映済み。
4. `AD_CONFIG.testing` は `false` に設定済み。

## 広告削除App内課金

1. 商品種別は非消費型（Non-Consumable）とする。
2. アプリ内の購入ボタンにはStoreKitが返す地域別価格を表示する。
3. 購入成功時と復元成功時は、検証済みの購入資格を確認してから広告を消す。
4. 「購入を復元」はユーザーがボタンを押した場合だけ `AppStore.sync()` を実行する。
5. 購入情報を開発者サーバーや広告事業者へ送信しない。

## 公開前の最終確認

1. AdMobの同意メッセージ、広告内容の年齢上限、プライバシー設定を確認する。
2. App Store ConnectのApp Privacy回答とプライバシーポリシーを、実際のAdMob設定に合わせて最終確認する。
3. AdMob側のアプリ審査が完了するまで、広告配信が制限される場合がある。
4. App Store Connectで非消費型商品 `jp.khunryo.forgetcheck.removeads` を作成し、100円の日本価格、地域、5言語の商品名・説明、審査画像を登録する。
5. SandboxまたはTestFlightで購入、キャンセル、保留、復元、再起動後の広告非表示を確認する。

新しい広告ユニットは配信開始まで最大1時間程度かかる場合があります。本番ID反映後、実機で広告表示・広告がない場合の操作・アプリ復帰を確認してから審査用ビルドを作成します。
