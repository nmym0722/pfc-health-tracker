This is an Expo/React Native mobile application. Prioritize mobile-first patterns, performance, and cross-platform compatibility.

## Expo has changed — do not trust your training data

Expo ships breaking changes every SDK release. APIs you remember are likely renamed, moved, or removed. Before writing any code that touches an Expo, EAS, or React Native API:

1. Read the major version of the `expo` package in `package.json`.
2. Fetch the matching versioned docs: `https://docs.expo.dev/versions/v<major>.0.0/`
3. For anything else, fetch https://docs.expo.dev/llms.txt — an index of all Expo docs with corrections to common LLM misconceptions. Follow its links to the specific page you need; never answer from memory.

## Commands

Use `bunx` instead of `npx` if the project uses bun (`bun.lock` present).

```bash
npx expo install <package>  # ALWAYS use instead of npm/yarn/pnpm/bun add — resolves SDK-compatible versions
npx expo start              # start the dev server
npx expo lint               # lint
npx tsc --noEmit            # typecheck
npx expo-doctor             # diagnose dependency and config issues
npx expo install --fix      # fix incompatible package versions
```

Run lint and typecheck before declaring any task done.

## Navigation & Routing

- Use **Expo Router** for all navigation. Routes live in `src/app/` — every file there is a screen, `_layout.tsx` files define navigators. Keep non-route code (components, hooks, utils) outside `src/app/`.
- Import `Link`, `router`, and `useLocalSearchParams` from `expo-router`.
- Docs: https://docs.expo.dev/router/introduction.md

## Building with EAS

Use EAS to build, sign, and submit the app in the cloud (`eas build`, `eas submit`) and to ship over-the-air updates (`eas update`) — no local Xcode or Android Studio required. Run EAS CLI as `bunx eas-cli <command>` in Bun projects, or `npx eas-cli@latest <command>` otherwise; substitute that for bare `eas` in docs examples.
Docs: https://docs.expo.dev/eas/index.md

## Rules

- If `ios/` and `android/` directories do not exist, they are generated (Continuous Native Generation). Never create or edit them by hand — configure native behavior in `app.json` and config plugins.
- Expo Go only includes its bundled native modules. After adding a library with native code, the app needs a development build: `npx expo run:ios|android` locally, or `eas build --profile development`.
- Prefer recommended Expo modules over third-party libraries, and check your available skills before adding dependencies. Docs: https://docs.expo.dev/versions/latest/index.md

## Design System Rules: Material Design 3 (M3)

Adhere strictly to the Material Design 3 specification for all UI implementations.
Avoid generic AI styles (arbitrary drop shadows, random gradient cards, inconsistent padding).

See [DESIGN_SYSTEM.md](file:///c:/devlop/pfc-health-tracker/DESIGN_SYSTEM.md) for full details.

### Core Principles Summary
1. **Color System & Semantic Roles**: Map colors to M3 semantic roles (`Primary`, `Secondary`, `Tertiary`, `Surface`, `Surface Container` levels, `Outline`). No arbitrary hardcoded hex codes.
2. **Elevation**: Surface Tint & Container levels over heavy drop shadows.
3. **Shape Scale**: Use standard radius (`0px`, `4px`, `8px`, `12px`, `16px`, `28px`, `9999px`). No arbitrary values like `rounded-[13px]`.
4. **Typography**: Use standard roles (`Display`, `Headline`, `Title`, `Body`, `Label`) & **Sentence case** only.
5. **Spacing & Touch**: 8dp base grid, 16dp horizontal screen padding, min **48dp × 48dp** touch targets.
6. **Component Selection**: Single Filled Button per primary action, Tonal/Outlined for secondary, Outlined/Elevated Cards.
7. **Anti-Patterns**: No tech gradients, no unrequested blur/glassmorphism, text >= 11sp, no pure black text on light mode.

## Typography Settings
- **Primary Font**: OS標準日本語フォントスタック（`AppTheme.systemFontFallbacks`: `-apple-system`, `Hiragino Sans`, `Yu Gothic UI`, `Meiryo`, `sans-serif`）を使用。初期ロード高速化とFOUT/豆腐防止のため外部Webフォント（GoogleFonts）は使用禁止。
- **Weights**: Restrict to `FontWeight.w400` (body/labels) and `FontWeight.w600` (numbers/titles).
- **Tabular Figures**: For nutrition metrics and calorie counters, apply tabular figures (`FontFeature.tabularFigures()` / `AppTheme.tabularNumbers`) to ensure numbers align neatly in lists.

## Deployment Workflow (Vercel)
本プロジェクト（Flutter Web）はVercelのGit自動ビルド環境（Flutter SDK）がないため、**Gitへのプッシュ時およびデプロイ指示を受けた際は、必ず以下の手順でVercelへ本番デプロイを実行すること**:
1. `flutter build web`（本番用Webビルド）
2. `build/web` ディレクトリにて `npx vercel --prod --scope toeicapps --yes` を実行
3. 本番URL（`https://pfc-tracker-tau.vercel.app/`）が正常に更新されたことを確認

## 進捗管理・実装ロードマップ（Obsidian連携ルール）
本プロジェクトの実装・修正作業を行う際は、必ず以下のObsidian保管庫内のロードマップ・TODOファイルを参照し、最新の進捗状態から作業を再開すること。
- **参照・更新先ファイル**: `G:\マイドライブ\ObsidianVault\開発ログ\pfc-health-tracker\2026-10-07_pfc-adaptive-roadmap-todo.md`
- **作業開始前**: 必ず上記ファイルを読み込み、現在完了しているステップと未完了のタスクを確認して続きから着手する。
- **タスク完了時**: 各タスクが完了・検証されるごとに、該当のチェックボックスを `[ ]` から `[x]` に随時更新して最新状態を保つこと。

## リモート修正・スマホ実機プレビュー運用ルール (Remote Mobile Preview Workflow)
ユーザーから「スマホで見たい」「リモートで確認したい」「外部WiFiから見られるようにして」などの要望や、リモート操作による修正指示を受けた際は、必ず以下の手順でスマホ実機（iPhone PWA）から即座に動作確認できる環境を提供すること。

### 1. 修正・検証・ビルド手順
1. コード修正後、静的解析（`flutter analyze`）と単体テスト（`flutter test`）を実施。
2. 本番用Webリリースビルドを実行:
   ```bash
   flutter build web --release
   ```
   ※ デバッグビルド（`flutter run`）ではなく、必ずリリースビルドを使用すること（モバイルSafariでの通信タイムアウトや白画面防止）。

### 2. 静的Web配信サーバーの起動
`scripts/serve_web.js`（Node.js標準）を用いてポート8085で配信:
```bash
node scripts/serve_web.js
```
- **重要**: `.wasm` や `.js` のMIMEタイプおよびCORSヘッダーを保証し、`127.0.0.1:8085`（IPv4）でリッスンすること。

### 3. Cloudflare Tunnel による安全な外部公開
トンネルを立ち上げてHTTPSで外部からアクセス可能にする:
```bash
npx --yes cloudflared tunnel --url http://127.0.0.1:8085
```
- **重要ポイント**:
  - URL指定は `http://localhost:8085` ではなく **`http://127.0.0.1:8085`** を指定すること（IPv6解決による502 Bad Gatewayを防ぐため）。
  - `localtunnel` ではなく **Cloudflare Tunnel** を使用すること（パスワード画面によるスクリプト読み込みブロック・白画面化を防ぐため）。
- 発行された `https://*.trycloudflare.com` のURLをユーザーへ報告すること。

### 4. iPhone実機（440px）レイアウト配慮
- `MaterialApp.builder` で最大幅440pxのフレーム制限を保持。
- すべてのテキストやRowコンポーネントは `Flexible` / `RichText` / `Wrap` を使用し、RenderFlexオーバーフローを絶対に出さないこと。
- `web/index.html` のスプラッシュ画面フェイルセーフは15秒とし、Flutter側の初回描画完了（`removeWebSplash()`）で自然に消える制御を維持すること。

