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
#import "SIWindowManager.h"

static NSDictionary *SITestWindowInfo(pid_t pid, int number, int layer, CGRect bounds) {
    return @{
            (id) kCGWindowOwnerPID : @(pid),
            (id) kCGWindowNumber : @(number),
            (id) kCGWindowLayer : @(layer),
            (id) kCGWindowBounds : [(NSDictionary *) CGRectCreateDictionaryRepresentation(bounds) autorelease]
    };
}

static const pid_t kChrome = 1564;
static const pid_t kTerminal = 7281;

@interface SIFrontWindowInfoTests : XCTestCase
@end

@implementation SIFrontWindowInfoTests

- (void)testPicksActiveAppWindowOverFullScreenWindowOnAnotherDisplay {
    // Chrome in full screen on the second display stays in front of every other window
    NSArray *windows = @[
            SITestWindowInfo(kChrome, 10, 0, CGRectMake(1824, 1440, 1344, 41)),
            SITestWindowInfo(kTerminal, 20, 0, CGRectMake(0, 31, 1280, 1410)),
            SITestWindowInfo(kChrome, 11, 0, CGRectMake(1824, 1528, 1344, 808)),
    ];

    XCTAssertEqualObjects(@20, SIFrontWindowInfo(windows, kTerminal)[(id) kCGWindowNumber]);
}

- (void)testIgnoresNonWindowLayersOfActiveApp {
    NSArray *windows = @[
            SITestWindowInfo(kTerminal, 30, 25, CGRectMake(0, 0, 30, 24)),
            SITestWindowInfo(kTerminal, 20, 0, CGRectMake(0, 31, 1280, 1410)),
    ];

    XCTAssertEqualObjects(@20, SIFrontWindowInfo(windows, kTerminal)[(id) kCGWindowNumber]);
}

- (void)testActiveAppWithoutWindowsMovesNothing {
    NSArray *windows = @[SITestWindowInfo(kChrome, 10, 0, CGRectMake(1824, 1440, 1344, 41))];

    XCTAssertNil(SIFrontWindowInfo(windows, kTerminal));
}

- (void)testUnknownActiveAppFallsBackToFrontWindow {
    NSArray *windows = @[
            SITestWindowInfo(kChrome, 10, 0, CGRectMake(1824, 1440, 1344, 41)),
            SITestWindowInfo(kTerminal, 20, 0, CGRectMake(0, 31, 1280, 1410)),
    ];

    XCTAssertEqualObjects(@10, SIFrontWindowInfo(windows, 0)[(id) kCGWindowNumber]);
}

@end
