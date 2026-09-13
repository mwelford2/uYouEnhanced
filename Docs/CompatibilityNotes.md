# YouTube Compatibility Notes

Verification method: extracted `Payload/YouTube.app/YouTube` from a decrypted IPA and
diffed the Objective-C class list (`__objc_classname` Mach-O section) plus targeted
`otool -oV` method-list inspection against every class referenced by `%hook` in
`Sources/*.xm` and `Tweaks/**/*.xm`.

## v21.36.6 (verified September 2026)

All core functionality confirmed intact: ad blocking, player controls, config-flag
overrides (`YTHotConfig`/`YTColdConfig`), progress bar, and 140+ other hooked classes
resolve cleanly. Four issues found and handled:

### Fixed (retargeted to the new class, verified present)

- **Snap-to-chapter disable** (`Sources/uYouPlus.xm`) — `YTSegmentableInlinePlayerBarView`
  was removed from the binary. `enableSnapToChapter` now lives on the
  `YTIPlayerBarPlayingState` model instead of the view; the hook was moved there.
- **Buffered progress bar color** (`Sources/uYouPlus.xm`, `gRedProgressBar` group) —
  same removed view; `bufferedProgressBarColor` now lives on `YTPlayerBarSegmentView`.
  The hook was retargeted; behavior (including the pre-existing no-op quirk where the
  constructed `UIColor` isn't actually applied) was preserved as-is.

### Temporarily inert (class removed, no direct successor — left as safe no-ops)

Logos silently skips a `%hook` whose target class doesn't exist at runtime, so these
don't crash — they just stop doing anything until rewritten against the new hierarchy:

- **Big YouTube Mini Player** (`Sources/BigYTMiniPlayer.xm`) and the mini-player state
  sync hook (`Sources/uYouPlus.xm`, `kYTMiniPlayer`) — `YTWatchMiniBarView` /
  `YTWatchMiniBarViewController` were decomposed into a new class family
  (`YTWatchMiniBarVisibilityController`, `YTWatchMiniBarButtonView`,
  `YTPlaylistMiniBarView`/`Controller`, etc.) with no single drop-in successor.
  Highest-impact of the four; needs deeper reverse-engineering of the new classes'
  method signatures before a safe rewrite is possible.
- **Dark-mode styling of the system "Open with..." sheet** (`Sources/uYouPlusThemes.xm`) —
  `ASWAppSwitchingSheetHeaderView` / `ASWAppSwitchingSheetFooterView` /
  `ASWAppSwitcherCollectionViewCell` no longer exist. This is Apple's own system UI
  surface (not YouTube's code), replaced by `ASWAppSwitchingFloatingButton`,
  `ASWAppSwitchingGm3Options`, and related classes. Cosmetic-only, lower priority.
- **Low Contrast Mode on a few Texture node types** (`Sources/LowContrastMode.xm`) —
  `ASTextFieldNode` / `ASTextView` / `ASButtonNode` (AsyncDisplayKit/Texture node
  classes) no longer exist under those names. Cosmetic-only (affects text color on a
  subset of widgets); the renamed equivalents weren't confidently identified from the
  binary alone, so this was left inert rather than guessed at.

### False positives during the diff (not actually broken — no action needed)

Classes belonging to the separately-bundled `Tweaks/uYou` sub-tweak (not YouTube's own
binary, so absence there is expected): `PlayerVC`, `PlayerManager`, `DownloadItem`,
`DownloadsManager`, `DownloadsPagerVC`, `FRPreferences`, `FRPSelectListTable`,
`settingsReorderTable`, `SSBouncyButton`, `ArtworkImageView`.

Defensive dual-hooks where a working sibling class already covers the same feature
(kept as-is for backward compatibility with older YouTube versions per the project's
"v21.14.4 or higher" support range): `YTFullScreenEngagementOverlayController`/`View`
(capital-S variant; the lowercase-s `YTFullscreenEngagementOverlayController`/`View`
sibling works), `YTReelPlayerViewControllerSub` (sibling `YTReelPlayerViewController`
works), `YTReelInfinitePlaybackDataSource` (sibling `YTReelDataSource` works).
