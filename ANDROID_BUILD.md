# 潮先 Android版

Android版はiOS版と同じWebアプリをCapacitorで共有します。アプリIDは
`com.khunryo.shiome`、Google Playでの初期バージョンは`1.0.0`です。

## ローカル同期

```powershell
npm ci
npm run android:sync
```

Android Studioがある環境では`npm run android:open`で開けます。

## CodemagicでデバッグAPKを作る

`android-build-*`形式のGitタグをpushすると、`android-debug`ワークフローが
APKを生成します。これは実機確認用で、Google Play提出用ではありません。

## AdMob

Android用AdMobアプリとバナー広告ユニットはiOSとは別に作成します。
本番IDが未設定のビルドでは、Google公式テスト広告IDを使用します。

本番ビルド時にCodemagicの環境変数へ次を設定します。

- `ADMOB_ANDROID_APP_ID`: Androidアプリ用AdMob App ID
- `ADMOB_ANDROID_BANNER_ID`: Android用バナー広告ユニットID

## Google Play提出前に必要なもの

- Google Play Consoleのデベロッパ登録
- Android用AdMobアプリと広告ユニット
- アップロード署名鍵をCodemagicへ登録
- 署名済みAndroid App Bundle（AAB）のワークフロー
- ストア説明、スクリーンショット、プライバシーとデータセーフティ回答
- Android実機で現在地、投稿、画像選択、通報・非表示、広告同意を確認
