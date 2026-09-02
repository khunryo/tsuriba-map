# Forget Check App Store プライバシー回答案

最終確認日: 2026-08-31
対象: バージョン1.0、広告削除App内課金を含む新規ビルド

App Store Connect登録状態: 2026-08-31に以下の6種類を保存し、プライバシーラベルを公開済み。

## 実装根拠

- チェックリスト、テンプレート、チェック状態、一時保存は端末内の `localStorage` に保存する
- アカウント、クラウド同期、外部解析SDK、サブスクリプションは使用しない
- 広告削除はApple StoreKitの非消費型App内課金を使用し、購入資格は端末上でAppleの検証済みトランザクションから確認する
- 購入履歴を開発者サーバーや広告事業者へ送信しない
- Google Mobile Ads SDK（AdMob）を使用する
- 広告は種類選択画面とテンプレート編集画面だけに表示する
- 広告リクエストは `npa: true` で非パーソナライズ広告に限定する
- UMPの同意情報を確認し、広告リクエスト可能な場合だけバナーを要求する
- ATTを要求するコードと `NSUserTrackingUsageDescription` は含まない

## App Store Connect回答案

データ収集の質問は「はい、このアプリからデータを収集します」と回答する。アプリ自身の端末内データではなく、組み込まれたGoogle Mobile Ads SDKが広告配信のために扱う可能性があるデータを含める。

| データタイプ | 主な目的 | ユーザーにリンク | トラッキング |
|---|---|---|---|
| おおよその位置情報 | 第三者広告、アナリティクス | はい（端末情報と関連する可能性を含めて保守的に申告） | いいえ |
| デバイスID | 第三者広告、アナリティクス | はい | いいえ |
| 製品の操作 | 第三者広告、アナリティクス | はい | いいえ |
| 広告データ | 第三者広告、アナリティクス | はい | いいえ |
| クラッシュデータ | アナリティクス、アプリ機能 | いいえ | いいえ |
| パフォーマンスデータ | 第三者広告、アナリティクス、アプリ機能 | はい | いいえ |

チェックリスト本文、テンプレート名、連絡先、写真、正確な位置情報、検索履歴、購入履歴は収集データとして選択しない。広告削除の購入はAppleが処理し、本アプリはStoreKitから購入資格の有無だけを端末上で確認するため、開発者による「購入履歴」の収集には該当しない。

## URL

- プライバシーポリシーURL: https://forget-check-jp.khunryo.chatgpt.site/privacy.html（App Store Connectへ登録済み）
- ユーザプライバシー選択URL: 未設定（任意）

## 現行公式資料

- Apple App Privacy: https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/
- Apple App Privacy Details: https://developer.apple.com/app-store/app-privacy-details/
- Google Mobile Ads SDK App Store Data Disclosure: https://developers.google.com/admob/ios/privacy/data-disclosure

## 注意

Google Mobile Ads SDKやAdMob設定が変わった場合は、この回答を再確認する。メディエーション、追加の広告SDK、外部解析、パーソナライズ広告、ATTトラッキングを追加した場合は、この回答をそのまま流用しない。
