/*
 ShiftIt: Window Organizer for OSX

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.

 */

#import <XCTest/XCTest.h>
#import "ShiftItApp.h"
#import "DefaultShiftItActions.h"

static const NSSize kScreen = {1440, 900};

#pragma mark Fakes

@interface SITestScreen : SIScreen
@end

@implementation SITestScreen
- (NSSize)size { return kScreen; }
- (NSRect)visibleRect { return NSMakeRect(0, 0, kScreen.width, kScreen.height); }
@end

@interface SITestWindow : NSObject <SIWindow>
@property NSRect geometry;
@property BOOL resizable;
@property BOOL fullScreen;
@property NSInteger setGeometryCalls;
@end

@implementation SITestWindow

- (BOOL)getGeometry:(NSRect *)geometry screen:(SIScreen **)screen error:(NSError **)error {
    *geometry = self.geometry;
    *screen = [[[SITestScreen alloc] init] autorelease];
    return YES;
}

- (BOOL)setGeometry:(NSRect)geometry screen:(SIScreen *)screen error:(NSError **)error {
    self.geometry = geometry;
    self.setGeometryCalls++;
    return YES;
}

- (BOOL)canMove:(BOOL *)flag error:(NSError **)error { *flag = YES; return YES; }
- (BOOL)canResize:(BOOL *)flag error:(NSError **)error { *flag = self.resizable; return YES; }
- (BOOL)canZoom:(BOOL *)flag error:(NSError **)error { *flag = YES; return YES; }
- (BOOL)canEnterFullScreen:(BOOL *)flag error:(NSError **)error { *flag = YES; return YES; }
- (BOOL)getFullScreen:(BOOL *)flag error:(NSError **)error { *flag = self.fullScreen; return YES; }

@end

@interface SITestContext : NSObject <SIWindowContext>
@property(retain) SITestWindow *window;
@property int lastAnchor;
@end

@implementation SITestContext

- (void)dealloc {
    [_window release];
    [super dealloc];
}

- (BOOL)getFocusedWindow:(id <SIWindow> *)window error:(NSError **)error {
    *window = self.window;
    return YES;
}

- (BOOL)anchorWindow:(id <SIWindow>)window to:(int)anchor error:(NSError **)error {
    self.lastAnchor = anchor;
    return YES;
}

- (void)getAnchorMargins:(Margins *)margins {
    margins->left = margins->top = margins->bottom = margins->right = 0;
}

@end

#pragma mark Tests

@interface ShiftItActionGeometryTests : XCTestCase
@end

@implementation ShiftItActionGeometryTests

- (void)setUp {
    [super setUp];
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{kMutipleActionsCycleWindowSizes : @NO}];
}

- (void)assertBlock:(SimpleWindowGeometryChangeBlock)block from:(NSRect)window gives:(NSRect)expected anchor:(int)anchor {
    AnchoredRect r = block(window, kScreen);
    XCTAssertTrue(NSEqualRects(expected, r.rect), @"expected %@ got %@", NSStringFromRect(expected), NSStringFromRect(r.rect));
    XCTAssertEqual(anchor, r.anchor);
}

- (void)testHalves {
    NSRect w = NSMakeRect(100, 100, 300, 200);
    [self assertBlock:shiftItLeft from:w gives:NSMakeRect(0, 0, 720, 900) anchor:kLeftDirection];
    [self assertBlock:shiftItRight from:w gives:NSMakeRect(720, 0, 720, 900) anchor:kRightDirection];
    [self assertBlock:shiftItTop from:w gives:NSMakeRect(0, 0, 1440, 450) anchor:kTopDirection];
    [self assertBlock:shiftItBottom from:w gives:NSMakeRect(0, 450, 1440, 450) anchor:kBottomDirection];
}

- (void)testQuarters {
    NSRect w = NSMakeRect(100, 100, 300, 200);
    [self assertBlock:shiftItTopLeft from:w gives:NSMakeRect(0, 0, 720, 450) anchor:kTopDirection | kLeftDirection];
    [self assertBlock:shiftItTopRight from:w gives:NSMakeRect(720, 0, 720, 450) anchor:kTopDirection | kRightDirection];
    [self assertBlock:shiftItBottomLeft from:w gives:NSMakeRect(0, 450, 720, 450) anchor:kBottomDirection | kLeftDirection];
    [self assertBlock:shiftItBottomRight from:w gives:NSMakeRect(720, 450, 720, 450) anchor:kBottomDirection | kRightDirection];
}

- (void)testThirds {
    NSRect w = NSMakeRect(100, 100, 300, 200);
    [self assertBlock:shiftItThirdTopLeft from:w gives:NSMakeRect(0, 0, 480, 450) anchor:kTopDirection | kLeftDirection];
    [self assertBlock:shiftItThirdBottomLeft from:w gives:NSMakeRect(0, 450, 480, 450) anchor:kBottomDirection | kLeftDirection];
    [self assertBlock:shiftItThirdTopCenter from:w gives:NSMakeRect(480, 0, 480, 450) anchor:kTopDirection];
    [self assertBlock:shiftItThirdBottomCenter from:w gives:NSMakeRect(480, 450, 480, 450) anchor:kBottomDirection];
    [self assertBlock:shiftItThirdTopRight from:w gives:NSMakeRect(960, 0, 480, 450) anchor:kTopDirection];
    [self assertBlock:shiftItThirdBottomRight from:w gives:NSMakeRect(960, 450, 480, 450) anchor:kBottomDirection];
    [self assertBlock:shiftItThirdLeft from:w gives:NSMakeRect(0, 0, 480, 900) anchor:kLeftDirection];
    [self assertBlock:shiftItThirdCenter from:w gives:NSMakeRect(480, 0, 480, 900) anchor:kTopDirection];
    [self assertBlock:shiftItThirdRight from:w gives:NSMakeRect(960, 0, 480, 900) anchor:kTopDirection];
}

- (void)testMaximizeAndCenter {
    NSRect w = NSMakeRect(10, 20, 400, 300);
    [self assertBlock:shiftItFullScreen from:w gives:NSMakeRect(0, 0, 1440, 900) anchor:0];
    [self assertBlock:shiftItCenter from:w gives:NSMakeRect(520, 300, 400, 300) anchor:0];
}

- (void)testRepeatedLeftDoesNotCycleByDefault {
    [self assertBlock:shiftItLeft from:NSMakeRect(0, 0, 720, 900) gives:NSMakeRect(0, 0, 720, 900) anchor:kLeftDirection];
}

- (void)testCycleWindowSizes {
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{kMutipleActionsCycleWindowSizes : @YES}];

    [self assertBlock:shiftItLeft from:NSMakeRect(0, 0, 720, 900) gives:NSMakeRect(0, 0, 480, 900) anchor:kLeftDirection];
    [self assertBlock:shiftItLeft from:NSMakeRect(0, 0, 480, 900) gives:NSMakeRect(0, 0, 960, 900) anchor:kLeftDirection];
    [self assertBlock:shiftItRight from:NSMakeRect(720, 0, 720, 900) gives:NSMakeRect(960, 0, 480, 900) anchor:kRightDirection];
    [self assertBlock:shiftItRight from:NSMakeRect(960, 0, 480, 900) gives:NSMakeRect(480, 0, 960, 900) anchor:kRightDirection];
    [self assertBlock:shiftItTop from:NSMakeRect(0, 0, 1440, 450) gives:NSMakeRect(0, 0, 1440, 300) anchor:kTopDirection];
    [self assertBlock:shiftItTop from:NSMakeRect(0, 0, 1440, 300) gives:NSMakeRect(0, 0, 1440, 600) anchor:kTopDirection];
    [self assertBlock:shiftItBottom from:NSMakeRect(0, 450, 1440, 450) gives:NSMakeRect(0, 600, 1440, 300) anchor:kBottomDirection];
    [self assertBlock:shiftItBottom from:NSMakeRect(0, 600, 1440, 300) gives:NSMakeRect(0, 300, 1440, 600) anchor:kBottomDirection];
}

- (NSRect)execute:(id <SIActionDelegate>)action on:(SITestWindow *)window anchor:(int *)anchor {
    SITestContext *ctx = [[[SITestContext alloc] init] autorelease];
    ctx.window = window;
    NSError *error = nil;
    XCTAssertTrue([action execute:ctx error:&error], @"%@", error);
    if (anchor) {
        *anchor = ctx.lastAnchor;
    }
    return window.geometry;
}

- (void)testExecuteMovesAndResizesWindow {
    SITestWindow *w = [[[SITestWindow alloc] init] autorelease];
    w.geometry = NSMakeRect(100, 100, 300, 200);
    w.resizable = YES;

    WindowGeometryShiftItAction *left = [[[WindowGeometryShiftItAction alloc] initWithBlock:shiftItLeft] autorelease];
    int anchor = -1;
    NSRect r = [self execute:left on:w anchor:&anchor];

    XCTAssertTrue(NSEqualRects(NSMakeRect(0, 0, 720, 900), r), @"%@", NSStringFromRect(r));
    XCTAssertEqual(kLeftDirection, anchor);
}

- (void)testExecuteOnlyMovesNonResizableWindowRespectingAnchor {
    SITestWindow *w = [[[SITestWindow alloc] init] autorelease];
    w.geometry = NSMakeRect(100, 100, 300, 200);
    w.resizable = NO;

    WindowGeometryShiftItAction *br = [[[WindowGeometryShiftItAction alloc] initWithBlock:shiftItBottomRight] autorelease];
    NSRect r = [self execute:br on:w anchor:NULL];

    XCTAssertTrue(NSEqualRects(NSMakeRect(1440 - 300, 900 - 200, 300, 200), r), @"%@", NSStringFromRect(r));
}

- (void)testExecuteRefusesFullScreenWindow {
    SITestWindow *w = [[[SITestWindow alloc] init] autorelease];
    w.geometry = NSMakeRect(0, 0, 1440, 900);
    w.resizable = YES;
    w.fullScreen = YES;

    SITestContext *ctx = [[[SITestContext alloc] init] autorelease];
    ctx.window = w;
    WindowGeometryShiftItAction *left = [[[WindowGeometryShiftItAction alloc] initWithBlock:shiftItLeft] autorelease];
    NSError *error = nil;

    XCTAssertFalse([left execute:ctx error:&error]);
    XCTAssertNotNil(error);
    XCTAssertEqual(0, w.setGeometryCalls);
}

- (void)testIncreaseAndReduceByScreenPercentage {
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
            kSizeDeltaTypePrefKey : @(kScreenSizeDeltaType),
            kScreenSizeDeltaPrefKey : @6.25
    }];

    SITestWindow *w = [[[SITestWindow alloc] init] autorelease];
    w.resizable = YES;

    // kw = 90, kh = 56.25 -> split between both sides when not touching an edge
    w.geometry = NSMakeRect(500, 300, 400, 200);
    NSRect r = [self execute:[[[IncreaseReduceShiftItAction alloc] initWithMode:YES] autorelease] on:w anchor:NULL];
    XCTAssertTrue(NSEqualRects(NSMakeRect(455, 272, 490, 256), r), @"%@", NSStringFromRect(r));

    w.geometry = NSMakeRect(500, 300, 400, 200);
    r = [self execute:[[[IncreaseReduceShiftItAction alloc] initWithMode:NO] autorelease] on:w anchor:NULL];
    XCTAssertTrue(NSEqualRects(NSMakeRect(545, 328, 310, 144), r), @"%@", NSStringFromRect(r));

    // touching the left/top edges -> grow only to the right/bottom
    w.geometry = NSMakeRect(0, 0, 400, 200);
    r = [self execute:[[[IncreaseReduceShiftItAction alloc] initWithMode:YES] autorelease] on:w anchor:NULL];
    XCTAssertTrue(NSEqualRects(NSMakeRect(0, 0, 490, 256), r), @"%@", NSStringFromRect(r));
}

- (void)testIncreaseIsClampedToScreen {
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
            kSizeDeltaTypePrefKey : @(kFixedSizeDeltaType),
            kFixedSizeWidthDeltaPrefKey : @50,
            kFixedSizeHeightDeltaPrefKey : @28
    }];

    SITestWindow *w = [[[SITestWindow alloc] init] autorelease];
    w.resizable = YES;
    w.geometry = NSMakeRect(5, 5, 1430, 890);

    NSRect r = [self execute:[[[IncreaseReduceShiftItAction alloc] initWithMode:YES] autorelease] on:w anchor:NULL];
    XCTAssertTrue(NSContainsRect(NSMakeRect(0, 0, 1440, 900), r), @"%@", NSStringFromRect(r));
}

@end
