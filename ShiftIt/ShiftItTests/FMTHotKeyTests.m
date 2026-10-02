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
#import "FMTHotKey.h"

static const NSUInteger kControlOptionCommand = NSEventModifierFlagControl | NSEventModifierFlagOption | NSEventModifierFlagCommand;

@interface FMTHotKeyTests : XCTestCase
@end

@implementation FMTHotKeyTests

- (void)testRecordedArrowKeyKeepsOnlyModifierKeys {
    // ⌃⌥⌘← as recorded from a real keyboard: arrows also carry the Fn and NumericPad flags
    NSUInteger recorded = kControlOptionCommand | NSEventModifierFlagFunction | NSEventModifierFlagNumericPad;
    FMTHotKey *hotKey = [[[FMTHotKey alloc] initWithKeyCode:123 modifiers:recorded] autorelease];

    XCTAssertEqual(kControlOptionCommand, [hotKey modifiers]);
}

- (void)testSameKeysWithDifferentDeviceFlagsAreEqual {
    FMTHotKey *recorded = [[[FMTHotKey alloc] initWithKeyCode:123 modifiers:kControlOptionCommand | NSEventModifierFlagFunction] autorelease];
    FMTHotKey *defaults = [[[FMTHotKey alloc] initWithKeyCode:123 modifiers:kControlOptionCommand | NSEventModifierFlagNumericPad] autorelease];

    XCTAssertTrue([recorded isEqualTo:defaults]);
}

- (void)testShiftIsKept {
    FMTHotKey *hotKey = [[[FMTHotKey alloc] initWithKeyCode:12 modifiers:kControlOptionCommand | NSEventModifierFlagShift] autorelease];

    XCTAssertEqual(kControlOptionCommand | NSEventModifierFlagShift, [hotKey modifiers]);
}

@end
