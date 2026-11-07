# E2E Coverage Map

This is a behavioral coverage dashboard for the Tauri/WebDriver E2E suite.
It is not line or branch coverage. A spec contributes coverage to each platform
and layer declared in the manifest, weighted by confidence and criticality.

- Manifest: `e2e/coverage-map.json`
- Specs directory: `e2e/specs`
- Mapped specs: 30
- Declared test blocks: 122
- Weighted coverage points: 98.4

Confidence weights: strong=1.0, partial=0.7, conditional=0.4, smoke=0.3.
Criticality weights: high=1.0, medium=0.7, low=0.4.
Declared test blocks are counted statically from source, so parameterized specs
can execute more runtime cases than this number shows.

## Platform Summary

| Platform | Specs | Declared tests | Weighted points | Layers | Features | Critical score |
| --- | --- | --- | --- | --- | --- | --- |
| windows | 26 | 116 | 96.4 | 13 | 37 | 89% |
| macos | 27 | 88 | 71.0 | 12 | 36 | 89% |
| linux | 23 | 82 | 69.0 | 11 | 33 | 89% |

## Runtime Results

No runtime result directory was supplied. Run with
`--results-dir e2e/results` after WDIO emits runtime JSON to include actual
pass/fail/skip counts.

## Layer Matrix

| Layer | windows | macos | linux |
| --- | --- | --- | --- |
| audio-device | 2 specs / 26 tests / 19.4 pts | - | - |
| billing | 1 specs / 1 tests / 1.0 pts | 1 specs / 1 tests / 1.0 pts | 1 specs / 1 tests / 1.0 pts |
| capture-ocr | 2 specs / 13 tests / 5.2 pts | 2 specs / 3 tests / 1.2 pts | 1 specs / 2 tests / 0.8 pts |
| local-api | 8 specs / 62 tests / 51.0 pts | 7 specs / 37 tests / 32.0 pts | 6 specs / 36 tests / 31.6 pts |
| notifications | 2 specs / 11 tests / 10.1 pts | 1 specs / 3 tests / 2.1 pts | 1 specs / 3 tests / 2.1 pts |
| onboarding | 1 specs / 3 tests / 1.2 pts | 1 specs / 3 tests / 1.2 pts | 1 specs / 3 tests / 1.2 pts |
| os-integration | 1 specs / 15 tests / 15.0 pts | 1 specs / 2 tests / 0.8 pts | - |
| performance | 2 specs / 41 tests / 41.0 pts | 3 specs / 29 tests / 27.0 pts | 1 specs / 26 tests / 26.0 pts |
| real-ui-e2e | 15 specs / 58 tests / 46.3 pts | 16 specs / 44 tests / 35.6 pts | 13 specs / 39 tests / 33.9 pts |
| settings | 7 specs / 21 tests / 20.1 pts | 6 specs / 13 tests / 12.1 pts | 6 specs / 13 tests / 12.1 pts |
| storage-privacy | 5 specs / 19 tests / 18.1 pts | 4 specs / 11 tests / 10.1 pts | 4 specs / 11 tests / 10.1 pts |
| tauri-command | 8 specs / 17 tests / 10.3 pts | 9 specs / 18 tests / 10.6 pts | 8 specs / 17 tests / 10.3 pts |
| window-lifecycle | 13 specs / 58 tests / 50.1 pts | 13 specs / 38 tests / 28.2 pts | 11 specs / 35 tests / 27.1 pts |

## Critical Feature Matrix

| Feature | Required layers | windows | macos | linux |
| --- | --- | --- | --- | --- |
| App launch and Home shell | real-ui-e2e | covered (strong; app-lifecycle, onboarding-redirect) | covered (strong; app-lifecycle, onboarding-redirect) | covered (strong; app-lifecycle, onboarding-redirect) |
| Home to floating Search | real-ui-e2e | covered (strong; windows-user-journey, tray-search) | covered (partial; tray-search) | covered (partial; tray-search) |
| Timeline navigation and frames | real-ui-e2e | covered (strong; windows-user-journey, windows-core-recording) | covered (strong; home-window, timeline) | covered (strong; home-window, timeline) |
| Real capture, OCR, and indexing | capture-ocr | weak (conditional; windows-core-recording, timeline) | weak (conditional; timeline, hd-recording-pipeline) | weak (conditional; timeline) |
| Local API auth enforcement | local-api | covered (strong; api-search-stress, windows-system-integration) | covered (strong; api-search-stress, api-key-cold-spawn) | covered (strong; api-search-stress, api-key-cold-spawn) |
| Local API search stability | local-api | covered (strong; api-search-stress, windows-core-recording) | covered (strong; api-search-stress) | covered (strong; api-search-stress) |
| Recording settings UX | settings | covered (strong; settings-sections, windows-user-journey) | covered (strong; settings-sections) | covered (strong; settings-sections) |
| Privacy API auth settings UX | settings | covered (strong; settings-sections, windows-user-journey) | covered (strong; settings-sections, privacy-api-auth) | covered (strong; settings-sections, privacy-api-auth) |
| Notification history and viewer paths | notifications | covered (strong; windows-user-journey, notification-viewer-link) | covered (partial; notification-viewer-link) | covered (partial; notification-viewer-link) |
| Window lifecycle, focus, and dedupe | window-lifecycle | covered (strong; windows-system-integration, window-lifecycle) | covered (strong; window-lifecycle, viewer-deeplink) | covered (strong; window-lifecycle, viewer-deeplink) |
| Tray/search window behavior | window-lifecycle | covered (strong; window-lifecycle, tray-search) | covered (strong; window-lifecycle, tray-search) | covered (strong; window-lifecycle, tray-search) |
| Storage retention safety UX | storage-privacy | covered (strong; settings-sections, windows-user-journey) | covered (strong; settings-sections) | covered (strong; settings-sections) |
| Updater install and rollback safety | os-integration | gap | gap | gap |
| Update-available banner surfacing | real-ui-e2e | covered (partial; updater-banner) | covered (partial; updater-banner) | covered (partial; updater-banner) |

## Critical Gaps

- windows: Real capture, OCR, and indexing (weak); Updater install and rollback safety (gap).
- macos: Real capture, OCR, and indexing (weak); Updater install and rollback safety (gap).
- linux: Real capture, OCR, and indexing (weak); Updater install and rollback safety (gap).

## Execution Integrity

- Every mapped spec declares at least one executable test block.
- Declared coverage below is NOT reconciled against execution: no runtime results
  were supplied. Specs can self-skip on hosted runners (no display, vision off,
  recording disabled) and still read as covered. Run `e2e:coverage:runtime` (or pass
  `--results-dir`) in CI to flag declared coverage that did not actually run.

## Spec Inventory

| Spec | Platforms | Layers | Features | Criticality | Confidence | UX | Tests | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| api-key-cold-spawn.spec.ts | windows, macos, linux | local-api, tauri-command | local-api-auth, app-launch | medium | partial | command | 3 | Cold-spawn local API config regression coverage. |
| api-search-stress.spec.ts | windows, macos, linux | local-api, performance | local-api-auth, local-api-search, health, local-api-load | high | strong | api | 26 | Broad readonly API, auth, search, and load coverage. |
| api.spec.ts | windows, macos, linux | local-api | health, local-api-auth | high | partial | api | 1 | Smoke coverage for local HTTP API shape and auth behavior. |
| app-lifecycle.spec.ts | windows, macos, linux | real-ui-e2e, window-lifecycle | app-launch, home-navigation, webview-stability, route-churn, browser-storage | high | strong | mixed | 14 | Home webview, routing, reload, focus, resize, and storage stability. |
| focus-server.spec.ts | windows, macos, linux | local-api, window-lifecycle, tauri-command | window-lifecycle, focus-server, deeplink | medium | partial | api | 2 | Focus server opens windows and forwards deeplink args. |
| hd-recording-pipeline.spec.ts | macos | capture-ocr, local-api, performance | capture-ocr, hd-recording, timeline | high | conditional | api | 1 | Opt-in macOS HD capture and OCR indexing. |
| help-discord-link.spec.ts | windows, macos, linux | real-ui-e2e | help | low | smoke | real-user-flow | 1 | Help section Discord invite link. |
| home-window.spec.ts | windows, macos, linux | real-ui-e2e, window-lifecycle | app-launch, home-navigation, timeline, settings-recording | high | strong | real-user-flow | 1 | Clicks through Home, Pipes, Timeline, Help, and Settings. |
| macos-ui-performance.spec.ts | macos | performance, real-ui-e2e | timeline, audio-device-health | medium | conditional | performance | 2 | macOS-only timeline/audio UI performance guards. |
| main-overlay-visibility.spec.ts | windows, macos, linux | window-lifecycle, tauri-command | window-lifecycle, main-overlay | medium | partial | command | 1 | Main overlay show/hide without duplicate handles. |
| main-window-close-reopen.spec.ts | windows, macos, linux | window-lifecycle, tauri-command | window-lifecycle, main-window | medium | partial | command | 1 | Main close/reopen without handle leaks. |
| main-window.spec.ts | windows, macos, linux | window-lifecycle, tauri-command | window-lifecycle, main-window | medium | partial | command | 2 | Main window show/hide dedupe. |
| notification-viewer-link.spec.ts | windows, macos, linux | notifications, local-api, window-lifecycle | notifications, viewer-deeplink | high | partial | mixed | 3 | Notification local file links rewrite into in-app viewer links. |
| onboarding-redirect.spec.ts | windows, macos, linux | onboarding, real-ui-e2e, window-lifecycle | onboarding, app-launch | high | conditional | real-user-flow | 3 | Opt-in no-onboarding seed verifies onboarding redirect. |
| permission-recovery.spec.ts | macos | os-integration, real-ui-e2e, window-lifecycle | permission-recovery, window-lifecycle | high | conditional | real-user-flow | 2 | macOS-only recovery window for missing TCC permissions. |
| privacy-api-auth-enforcement.spec.ts | windows, macos, linux | settings, local-api, storage-privacy | settings-privacy-api-auth, local-api-auth, restart-flow | high | conditional | mixed | 1 | Opt-in restart smoke toggles API auth and verifies backend behavior. |
| privacy-api-auth.spec.ts | windows, macos, linux | settings, storage-privacy, real-ui-e2e | settings-privacy-api-auth, local-api-auth | high | strong | real-user-flow | 1 | Privacy settings reveal/copy local API key flow. |
| privacy-installed-apps.spec.ts | windows, macos, linux | settings, storage-privacy, real-ui-e2e | settings-privacy-filters, installed-apps | medium | strong | real-user-flow | 1 | Privacy content filters surface installed-but-not-captured apps as typeable options with the not-captured hint (fetch-intercepted /installed-apps for determinism). |
| settings-sections.spec.ts | windows, macos, linux | settings, real-ui-e2e, storage-privacy | settings-recording, settings-privacy-api-auth, storage-retention | high | strong | real-user-flow | 8 | Settings sections, storage, privacy, and rapid switching crash guard. |
| timeline.spec.ts | windows, macos, linux | real-ui-e2e, capture-ocr | timeline, capture-ocr | high | conditional | real-user-flow | 2 | Timeline shell always runs; seeded frame assertion skips under no-recording. |
| tray-search.spec.ts | windows, macos, linux | window-lifecycle, tauri-command, real-ui-e2e | tray-search, home-search, window-lifecycle | high | partial | command | 2 | Invokes open_search_window and verifies focused floating Search. |
| updater-banner.spec.ts | windows, macos, linux | real-ui-e2e | update-surfacing | high | partial | synthetic | 1 | Synthetic update-available event surfaces the restart-to-update banner (no relaunch). Real check/download/install + rollback stay manual via e2e/mock-updates; the debug e2e build disables the updater check under cfg!(debug_assertions). |
| viewer-deeplink.spec.ts | windows, macos, linux | window-lifecycle, tauri-command | viewer-deeplink, window-lifecycle | medium | partial | command | 3 | Viewer window creation and per-path dedupe. |
| window-activation.spec.ts | macos | window-lifecycle, tauri-command, real-ui-e2e | window-lifecycle | medium | conditional | real-user-flow | 1 | macOS-only show_window_activated focus coverage. |
| window-lifecycle.spec.ts | windows, macos, linux | window-lifecycle, tauri-command, real-ui-e2e | window-lifecycle, onboarding, tray-search | high | strong | mixed | 3 | Home, Search, and onboarding window routing. |
| windows-core-recording.spec.ts | windows | capture-ocr, local-api, audio-device, real-ui-e2e | capture-ocr, local-api-auth, local-api-search, audio-device-health, timeline | high | conditional | mixed | 11 | Windows recording-enabled lane; hosted runners can skip frame-dependent OCR assertions. |
| windows-system-integration.spec.ts | windows | os-integration, local-api, audio-device, window-lifecycle, performance | app-launch, local-api-auth, audio-device-health, window-lifecycle, os-process-health, webview-stability | high | strong | mixed | 15 | Windows display, WebView2, loopback, process, Defender, audio, focus, and crash-report checks. |
| windows-user-journey.spec.ts | windows | real-ui-e2e, settings, notifications, storage-privacy, window-lifecycle | home-search, timeline, settings-recording, meeting-notes, shortcut-reminder, notifications, storage-retention, settings-privacy-api-auth | high | strong | real-user-flow | 8 | Windows-first real UX journey across search, timeline, settings, meetings, notifications, storage, and privacy. |
| zz-app-entitlement-gate.spec.ts | windows, macos, linux | settings, billing, real-ui-e2e | app-entitlement-gate, billing-gate | high | strong | real-user-flow | 1 | Production billing gate blocks an unentitled session behind the paywall and restores access when the forced-gate flag is cleared. |
| zz-logout-resurrect.spec.ts | windows, macos, linux | real-ui-e2e, settings | account-logout, auth-session | high | strong | synthetic | 1 | Logout must not be resurrected by an in-flight loadUser. Logs in via a synthetic deep-link (?api_key=) with a mocked /api/user fetch, makes the fetch slow, fires it, then clicks logout while it is pending and asserts the slow response cannot re-write the user (the 'logout needs two clicks' bug). Covers the auth-generation guard in use-settings.tsx. |
