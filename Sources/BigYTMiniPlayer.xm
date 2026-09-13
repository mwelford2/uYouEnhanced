#import "BigYTMiniPlayer.h"

// NOTE (v21.36.6+): YTWatchMiniBarView / YTWatchMiniBarViewController no longer exist in the
// YouTube binary — the mini player was internally decomposed into a new class family
// (YTWatchMiniBarVisibilityController, YTWatchMiniBarButtonView, YTPlaylistMiniBarView/Controller,
// etc.) with no single drop-in successor. Logos safely no-ops %hook on a missing class, so this
// group stays inert (no crash) rather than applying stale/guessed hooks — Big YouTube Mini Player
// is effectively disabled until it's rewritten against the new class hierarchy.
%group BigYTMiniPlayer // https://github.com/Galactic-Dev/BigYTMiniPlayer
%hook YTWatchMiniBarView
- (void)setWatchMiniPlayerLayout:(int)arg1 {
    %orig(1);
}
- (int)watchMiniPlayerLayout {
    return 1;
}
- (void)layoutSubviews {
    %orig;
    self.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width - self.frame.size.width), self.frame.origin.y, self.frame.size.width, self.frame.size.height);
}
%end

%hook YTMainAppVideoPlayerOverlayView
- (BOOL)isUserInteractionEnabled {
    if([[self _viewControllerForAncestor].parentViewController.parentViewController isKindOfClass:%c(YTWatchMiniBarViewController)]) {
        return NO;
    }
    return %orig;
}
%end
%end

%ctor {
    if (IS_ENABLED(kBigYTMiniPlayer) && (UIDevice.currentDevice.userInterfaceIdiom != UIUserInterfaceIdiomPad)) {
        %init(BigYTMiniPlayer);
    }
}
