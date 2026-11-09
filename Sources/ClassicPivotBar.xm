// Keep YouTube's classic bottom tab bar.
//
// YouTube 21.4x rolls out a server-flagged "floaty" pivot bar
// (YTFloatingPivotBarView, flag iosEnableFloatyPivotBar). uYou only inserts its
// own tab (the Downloads / uYou tab) into the classic YTPivotBarView, so when the
// floating bar arrives the uYou tab silently disappears and downloaded videos have
// no place in the app. Force the floaty flags off so the classic bar comes back.
// Set keepFloatingTabBar_enabled = YES in NSUserDefaults to opt out.
#import "uYouPlus.h"
#import "UYTLog.h"
#import <objc/runtime.h>

static BOOL UYTReturnNo(id self, SEL _cmd) { return NO; }

%ctor {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"keepFloatingTabBar_enabled"]) return;
    NSArray<NSString *> *classes = @[@"YTColdConfig", @"YTHotConfig", @"YTGlobalConfig"];
    NSArray<NSString *> *selectors = @[
        @"immersiveWatchClientGlobalConfigIosEnableFloatyPivotBar",
        @"iosEnableFloatyPivotBar",
        @"mainAppCoreClientIosEnablePositionedFloatyBars",
        @"iosEnablePositionedFloatyBars",
        @"isPivotBarFloating",
        @"isBottomFloatingPivotBarVisible",
    ];
    for (NSString *cn in classes) {
        Class cls = objc_getClass(cn.UTF8String);
        if (!cls) continue;
        for (NSString *sn in selectors) {
            SEL sel = NSSelectorFromString(sn);
            Method m = class_getInstanceMethod(cls, sel);
            if (!m) continue;
            const char *types = method_getTypeEncoding(m);
            if (!types || types[0] != 'B') continue;   // only BOOL getters
            MSHookMessageEx(cls, sel, (IMP)UYTReturnNo, NULL);
            UYTDebugInfo(@"[ClassicPivotBar] forced NO: -[%@ %@]", cn, sn);
        }
    }
}
