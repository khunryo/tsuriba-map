# Forget Check App Store リリースチェックリスト

最終更新: 2026-09-02
共通ルール原本: `C:\dev\fishing\APP_STORE_COMMON_SUBMISSION_RULES.md`

このチェックリストは、新規申請、再申請、アップデート申請のたびに使用する。必須画像の登録と表示確認、ユーザーの最終確認がすべて終わるまで、審査提出を行わない。審査用デモ動画はAppleからその申請について明示要求された場合だけ作成・添付する。

## 対象リリース

- アプリ名: Forget Check / 忘れ物チェック
- App Store ConnectアプリID: `6804138762`
- Bundle ID: `jp.khunryo.forgetcheck`
- バージョン: `1.0`
- 提出候補ビルド: `1.0 (34)`（入力拡大修正と広告削除App内課金を含む。CodemagicからApp Store Connectへアップロード済み）
- App Store Connect: https://appstoreconnect.apple.com/apps/6804138762/distribution/ios/version/inflight
- 現在の申請状態: 提出準備中（ビルド34のApple処理・選択、購入・復元実機確認まで審査提出を停止）

## 提出前ゲート

- [x] App Store Connectでビルド32とアプリアイコンの登録を確認した
- [x] 入力拡大修正と広告削除App内課金を含むビルド34を署名し、App Store Connectへアップロードした
- [ ] 2026-09-02の入力拡大修正と広告削除App内課金を含む新規ビルドを実機で最終確認した
- [x] 不適切だったiPhoneのアプリ一覧画像を削除し、アプリ実画面 `04-check-progress.png` へ差し替えた
- [ ] 2026-09-02受領のiPhone掲載用スクリーンショット4枚へ差し替え、順序と表示を確認した
- [ ] iPad 13インチの掲載用スクリーンショットを登録した
- [x] 最新UIの主要操作を補足する審査説明用画像を準備し、ローカルで表示確認した
- [x] 審査説明用画像をApp Reviewの添付欄へ登録し、ファイル名の表示を確認した
- [x] Appleから審査用デモ動画を明示要求されているか確認した。要求の記録がないため、自主添付動画を提出前に外した
- [ ] Appleから要求された場合だけ、審査用デモ動画が提出対象の修正版ビルドを実操作した指定準拠の動画であることを確認した
- [ ] Appleから要求された場合だけ、動画を指定場所へ登録し、App Store Connect上で最初から最後まで再生確認した
- [x] App Previewは、ユーザーの別途依頼またはAppleの明示指定がないため作成・登録していない
- [ ] スクリーンショット、審査説明用画像、および要求時だけ審査用デモ動画についてユーザーの最終確認を受けた
- [ ] 非消費型App内課金 `jp.khunryo.forgetcheck.removeads` を作成し、日本100円、配信地域、5言語、審査メモ、審査画像を登録した
- [ ] Sandbox／TestFlightで購入成功、キャンセル、保留、復元、再起動後の広告非表示を確認した
- [ ] バージョン1.0の「App内課金とサブスクリプション」へ広告削除商品を追加した
- [ ] 審査連絡先、広告・プライバシー文言、価格・配信地域、ローカライズを最終確認した（氏名、文言、価格、地域、5言語、プライバシー公開は完了。電話・メールだけ未保存）
- [ ] 「審査用に追加」後の提出内容を確認し、ユーザーから審査送信の最終承認を受けた
- [ ] 申請日時、提出バージョン、ビルド番号、添付物、申請後ステータスをこのファイルと個別チャットへ記録した

## 2026-09-02 iOS入力拡大不具合への対応

- 症状: テンプレート作成・編集で入力欄を選ぶとiPhone側が画面を拡大し、通常倍率へ戻りにくい
- 原因: iOS Safari／WKWebViewが16px未満の入力欄を自動拡大する一方、対象入力欄が12〜13pxだった
- 修正: 新規テンプレート、種類名、持ち物追加、持ち物名編集の全入力欄を16pxへ統一。`user-scalable=no` や `maximum-scale=1` は追加せず、利用者のピンチ拡大は維持
- コミット: `586542d958ee2b8f4f2b9cfcf036f247ce96d774`
- ブランチ: `codex/forget-check-input-zoom-fix`
- Codemagic起動タグ: `forget-check-ios-build-20260902-zoom-fix-1`
- ローカル検証: Web生成、Capacitor生成、iOS公開アセット同期に成功。390×844のスマホ表示で全入力欄16px、作成・名称変更・持ち物追加・タブ切替後の倍率1.0、横方向のはみ出しなし、コンソールエラーなしを確認
- Sideloadly実機確認用IPA: `C:\Users\81906\Downloads\ForgetCheck-input-zoom-fix-586542d-sideload.ipa`
- IPA SHA-256: `8D963AA76A8151137DA9B10496CAB24B3B272756B934EB8CF808414975981130`
- IPA検証: 直前の未署名IPAから変更された格納物が `Payload/ForgetCheck.app/public/index.html` の1ファイルだけであること、格納したHTMLがiOS生成物と完全一致すること、アプリ本体・Info.plist・Google Mobile Ads本体を含む全45ファイルが維持されていることを確認。このIPAはSideloadly実機確認専用で、App Store提出には使用しない
- 審査提出: 未実施。修正版IPAのSideloadly実機確認と、修正版TestFlightビルドへの差し替えが終わるまで提出しない

## 2026-09-02 広告削除対応ビルド

- 実装コミット: `484432bb1a83aa7cc7bc1a359f2c0d2d0b6fc97f`
- Codemagic起動タグ: `forget-check-ios-build-20260902-remove-ads-1`
- 商品ID: `jp.khunryo.forgetcheck.removeads`
- 実装方式: StoreKit 2の非消費型App内課金。Appleが検証した現在の購入資格だけで広告非表示を判定し、明示操作の「購入を復元」に対応
- 広告制御: 購入資格の確認が完了するまで広告要求を開始せず、購入済み・復元済みの場合はAdMobを表示しない
- Mac検証: Xcode 26.4 / iPhoneOS ReleaseでSwift、StoreKit、Capacitor、AdMobを含むビルドに成功
- Codemagic未署名ビルド: https://codemagic.io/app/6a7bcbd5cfca7ac6fad54354/build/6a9808bed473e2482d48d671
- Sideloadly実機確認用IPA: `C:\Users\81906\Downloads\ForgetCheck-remove-ads-484432b-sideload.ipa`
- Sideloadly用IPA SHA-256: `DC4174AE293C0B1660222ADE26DDCD7D2F562BB7A2D11B398A37A0E5EE02563A`
- IPA内容確認: Bundle ID `jp.khunryo.forgetcheck`、AppIcon、5言語、AdMob実App ID、`AdRemovalPlugin`、商品IDを確認
- Codemagic署名ビルド: https://codemagic.io/app/6a7bcbd5cfca7ac6fad54354/build/6a980af985e2ece5cf692832
- App Store提出用IPA: `C:\dev\fishing\forget-check\artifacts\ForgetCheck-AppStore-484432b.ipa`
- App Store提出用IPA SHA-256: `8DD525C5CE78545A828365F99F331A33EFE90A4BDA2178819578742CEAD3B631`
- App Storeバージョン／ビルド: `1.0 (34)`
- 署名確認: `_CodeSignature` と `embedded.mobileprovision` を含み、AppIconとAdMob実App IDを確認
- App Store Connect: Codemagicの配信処理に成功。Apple側の処理完了、バージョン1.0への選択、TestFlight実機確認は未完了

## 2026-09-02受領の掲載用スクリーンショット

登録場所: App Store Connect → Forget Check → 配信 → iOSアプリ 1.0 → プレビューとスクリーンショット → iPhone → 6.5インチディスプレイ

| 登録予定ファイル名 | ローカル絶対パス | 内容 | 状態 |
|---|---|---|---|
| `01-category-selection-20260902.png` | `C:\dev\fishing\forget-check\store-assets\2026-09-02\01-category-selection-20260902.png` | 種類選択画面 | 1242×2688 RGB PNG・準備済み・未登録 |
| `02-check-progress-20260902.png` | `C:\dev\fishing\forget-check\store-assets\2026-09-02\02-check-progress-20260902.png` | 3 / 6件チェック済みの進捗画面 | 1242×2688 RGB PNG・準備済み・未登録 |
| `03-template-overview-20260902.png` | `C:\dev\fishing\forget-check\store-assets\2026-09-02\03-template-overview-20260902.png` | テンプレート作成・種類選択 | 1242×2688 RGB PNG・準備済み・未登録 |
| `04-template-items-20260902.png` | `C:\dev\fishing\forget-check\store-assets\2026-09-02\04-template-items-20260902.png` | アイコン選択・持ち物編集 | 1242×2688 RGB PNG・準備済み・未登録 |

削除済み: `forget-check-iphone-6.5.png`（iPhoneのアプリ一覧画面）。App Store Connect上に残っていないことを確認済み。

掲載予定順: `01-category-selection-20260902.png` → `02-check-progress-20260902.png` → `03-template-overview-20260902.png` → `04-template-items-20260902.png`。

受領元: `C:\Users\81906\.codex\codex-remote-attachments\01a026f8-2af0-7301-8efc-a792176d10c5\5A6BCBBB-3CB2-47F5-9346-E44C56275B11`。4枚とも元画像は588×1280 JPEGであるため、内容を変えずApp Store対応の1242×2688へ変換した。

現在のビルドはiPhoneとiPadの両方を対象（`TARGETED_DEVICE_FAMILY = "1,2"`）としているため、13インチiPad用スクリーンショットも必要。これはWeb版の合成画像で代用せず、ビルド34をiPad実機またはiOSシミュレーターで起動して撮影する。現在登録中の英語（アメリカ）ローカライゼーションの画像は日本語UIなので、グローバル掲載品質を上げるには英語UIのiPhone／iPad実画面も別途撮影する。

今後作り直す画像のファイル名は、`ForgetCheck_AppStore_Screenshot_{連番}_{YYYYMMDD}.png` を使用する。提出ビルド番号は、このチェックリストの対象リリース欄と撮影記録に必ず残す。

## 広告削除App内課金の審査画像

登録場所: App Store Connect → Forget Check → App内課金 → Remove Ads → 審査情報 → スクリーンショット

- Product ID: `jp.khunryo.forgetcheck.removeads`
- ファイル名: `ForgetCheck_IAP_Review_RemoveAds_20260902.png`
- ローカル絶対パス: `C:\dev\fishing\forget-check\store-assets\2026-09-02\iap-review\ForgetCheck_IAP_Review_RemoveAds_20260902.png`
- 仕様: 1242×2688、RGB PNG、透過なし
- 状態: ローカル実装の購入導線を表示確認済み。App Store Connectには未登録

## 審査説明用画像

登録場所: App Store Connect → Forget Check → 配信 → iOSアプリ 1.0 → App Reviewに関する情報 → 添付ファイル

- 現在の状態: ローカル作成・表示確認済み、App Store ConnectのApp Review添付欄へ登録済み
- ファイル名: `ForgetCheck_AppReview_Image_CoreFlow_20260830.png`
- ローカル絶対パス: `C:\dev\fishing\forget-check\artifacts\app-review-images\ForgetCheck_AppReview_Image_CoreFlow_20260830.png`
- 現在の内容: 種類選択、チェック進捗、テンプレート編集、広告表示位置、ログイン不要・端末内保存の説明
- 一時保存・クリア・復元: 審査メモの操作手順で説明する。Appleから追加資料を求められた場合は、その時点のビルド実画面で補足する
- 添付欄で画像を登録できない場合: 審査メモに各操作手順と掲載用スクリーンショットの対応関係を記載する

## App Store Connect登録状況（2026-09-02）

- 掲載文: 英語、日本語、中国語（簡体字）、韓国語、スペイン語のプロモーションテキスト、説明、キーワードをApp Store Connectへ保存済み。原稿は `C:\dev\fishing\forget-check\APP_STORE_METADATA.md`
- App情報ローカリゼーション: 5言語を登録済み。表示名は英語・日本語・中国語（簡体字）・韓国語が `Forget Check`、スペイン語が `Equipaje listo al salir`。各言語のサブタイトルも保存済み
- Appプライバシー回答: `C:\dev\fishing\forget-check\APP_STORE_PRIVACY_RESPONSES.md` の6種類をApp Store Connectへ保存し、2026-08-31に公開済み
- プライバシーポリシーURL: `https://forget-check-jp.khunryo.chatgpt.site/privacy.html`（App Store Connectへ登録済み）
- プライバシーポリシー修正: AdMobがIPアドレスからおおよその地域を推定する可能性を、日本語・英語で正確に追記。ローカルビルドと配信アーカイブを検証済み
- 公開サイト: Sitesバージョン14を本番公開中。広告削除App内課金を追記したバージョン15（ソース `706329aef69f51944fb402fa036ff913c827e8d1`）は保存済みで、公開更新の明示承認待ち
- カテゴリ: プライマリ「仕事効率化」、セカンダリ「旅行」を保存済み
- コンテンツ配信権: AdMob広告が第三者コンテンツを表示するため「はい。必要な権利を保有」を保存済み
- 年齢制限: 広告のみ「はい」、その他は「いいえ／なし」、上書き「該当なし」で保存済み。算出結果は `4+`
- アプリ内言語検査: 日本語を基準に、英語・中国語（簡体字）・韓国語・スペイン語の各65キーが一致し、欠落0・余分0を静的検査で確認済み
- Web／Capacitorアセット: `build.mjs` と `scripts/build-mobile.mjs` を再実行し、プライバシー文言を含む生成物がHTTP 200相当で返ることを検証済み
- 審査連絡先: 氏名 `Ryohei Sugamata` は保存済み。電話 `+81 90 6528 2236` とメール `tabitomo.support@gmail.com` はApp Store Connectの入力欄が入力直後に空へ戻るため未保存。Chromeで手入力して保存・再読み込み確認が必要
- 審査メモ: 広告表示位置、端末内保存、ログイン不要、主要確認手順を英語で保存済み
- 審査説明用画像: `ForgetCheck_AppReview_Image_CoreFlow_20260830.png` を添付済み
- 審査動画: Appleから要求記録がないため、App Store Connectから外した状態を維持する
- アプリ価格: 無料を維持
- 広告削除App内課金: 非消費型、日本100円で新規登録待ち
- 提出候補ビルド: `1.0 (34)` をCodemagicからApp Store Connectへアップロード済み。Apple側の処理完了とバージョンへの選択待ち
- 配信地域: EUを除外し、148地域で利用可能・27地域で利用不可を確認済み
- Mac（Apple Silicon）／Apple Vision Pro: 現在有効。未検証プラットフォームのため、iPhone／iPad限定にする場合は提出前に無効化する
- 外部登録操作: 上記の画像、掲載文、カテゴリ、配信権、年齢制限、プライバシー、審査メモを保存済み。審査送信は未実施で、最終承認を別途得る

## 審査用デモ動画

登録場所: App Store Connect → Forget Check → 配信 → iOSアプリ 1.0 → App Reviewに関する情報 → 添付ファイル

- App Store Connect上のファイル名: `forget-check-app-review-demo.mp4`
- ローカル絶対パス: `C:\dev\fishing\forget-check\artifacts\app-review-video\forget-check-app-review-demo.mp4`
- 扱い: Appleからこの申請について明示要求された場合だけ使用する。通常申請へ自主添付しない
- Appleからの要求: 現時点で記録なし
- 登録状態: App Store Connectから削除済み（2026-08-30）。再読み込み後、添付欄が「ファイルを選択（任意）」だけになり、動画名が表示されないことを確認済み
- ローカルファイル: 削除せず保管中
- 再生確認: 対象外（Appleから動画要求がないため提出しない）
- 最新ビルド32の実操作動画であることの確認: 対象外（Appleから要求された場合は、その指定に合わせて改めて確認・作成する）
- 今後作り直す場合のファイル名: `ForgetCheck_AppReview_Demo_v1.0_20260830.mp4`
- 要求時の標準構成: Appleの指定を優先し、指定がなければ 起動 → 種類選択 → チェックと進捗 → 一時保存／クリア／復元 → テンプレート編集 → 広告表示位置

ローカルの動画ファイルは削除せず保管してよいが、Appleから要求されるまで添付・流用しない。この動画は審査員向けであり、App Storeの商品ページに掲載するApp Previewとは別物として扱う。

## App Preview（ストア掲載用動画）

- 現在の状態: 未登録
- 扱い: ユーザーが別途掲載を希望する場合、またはAppleから明示指定された場合だけ作成する
- 登録場所: App Store Connect → Forget Check → 配信 → iOSアプリ 1.0 → プレビューとスクリーンショット → アプリプレビュー
- 審査用デモ動画をそのまま流用せず、その時点のApp Preview要件に適合する別ファイルとして準備する

## 申請完了記録

- 申請日時: 未申請
- 提出バージョン／ビルド: `1.0 (34)` をアップロード済み、App Store Connectでの処理・選択待ち
- ユーザー最終確認日時: 未確認
- 申請後ステータス: 提出準備中
- 審査結果・指摘: 未記録

## Claude引き継ぎ用記載

Forget CheckのApp Store Connectは https://appstoreconnect.apple.com/apps/6804138762/distribution/ios/version/inflight です。提出候補は入力拡大修正、AdMob、StoreKit 2の広告削除を含むバージョン `1.0 (34)` です。Codemagicで署名・App Store Connectへのアップロードに成功し、Sideloadly用IPAは `C:\Users\81906\Downloads\ForgetCheck-remove-ads-484432b-sideload.ipa` に保存済みです。2026-09-02受領のiPhone画像4枚は `C:\dev\fishing\forget-check\store-assets\2026-09-02` に1242×2688 RGB PNGとして準備済み、広告削除商品の審査画像は `C:\dev\fishing\forget-check\store-assets\2026-09-02\iap-review\ForgetCheck_IAP_Review_RemoveAds_20260902.png` です。既存の審査説明用画像 `C:\dev\fishing\forget-check\artifacts\app-review-images\ForgetCheck_AppReview_Image_CoreFlow_20260830.png` はApp Review添付欄へ登録済みです。英語、日本語、中国語（簡体字）、韓国語、スペイン語の掲載文、カテゴリ「仕事効率化／旅行」、第三者コンテンツ配信権、年齢制限 `4+`、AdMobに対応する6種類のプライバシー回答は保存済みです。広告削除を追記した公開サイトのSitesバージョン15は保存済みですが、本番公開は明示承認待ちです。Appleから動画要求はなく、`forget-check-app-review-demo.mp4` はApp Store Connectから外したままです。未完了は、(1) App Store Connectへの再ログイン、(2) ビルド34のApple処理完了とバージョンへの選択、(3) iPhone画像4枚の差し替え、(4) 非消費型商品 `jp.khunryo.forgetcheck.removeads` の日本100円・5言語・審査画像登録、(5) `+81 90 6528 2236` と `tabitomo.support@gmail.com` の審査連絡先保存、(6) 13インチiPad実画面スクリーンショット、(7) Sandbox／TestFlightでの購入・復元を含む実機最終確認、(8) ユーザーの最終確認と審査送信承認です。現時点では審査へ提出しないでください。
