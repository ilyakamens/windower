import CoreGraphics
import XCTest

@testable import WindowGeometry

final class WindowGeometryTests: XCTestCase {
  func testHalvesTileOddSizedWorkAreaWithoutGaps() {
    let bounds = CGRect(x: -1511, y: -700, width: 1511, height: 901)
    let left = WindowGeometry.target(for: .left, in: bounds)
    let right = WindowGeometry.target(for: .right, in: bounds)
    let top = WindowGeometry.target(for: .top, in: bounds)
    let bottom = WindowGeometry.target(for: .bottom, in: bounds)
    XCTAssertEqual(left.maxX, right.minX)
    XCTAssertEqual(left.union(right), bounds)
    XCTAssertEqual(left.height, bounds.height)
    XCTAssertEqual(top.maxY, bottom.minY)
    XCTAssertEqual(top.union(bottom), bounds)
    XCTAssertEqual(top.width, bounds.width)
    XCTAssertEqual(top.minY, bounds.minY)
  }

  func testCenterUses75PercentOfEachDimension() {
    let bounds = CGRect(x: 50, y: 30, width: 1200, height: 800)
    let result = WindowGeometry.target(for: .center, in: bounds)
    XCTAssertEqual(result, CGRect(x: 200, y: 130, width: 900, height: 600))
  }

  func testFillScreenMatchesWorkAreaExactly() {
    let bounds = CGRect(x: -1800, y: 42, width: 1800, height: 1038)
    XCTAssertEqual(WindowGeometry.target(for: .maximize, in: bounds), bounds)
  }

  func testConvertsAppKitCoordinatesAboveAndBelowPrimaryDisplay() {
    XCTAssertEqual(
      WindowGeometry.accessibilityRect(
        CGRect(x: 0, y: 80, width: 1440, height: 795), primaryHeight: 900),
      CGRect(x: 0, y: 25, width: 1440, height: 795)
    )
    XCTAssertEqual(
      WindowGeometry.accessibilityRect(
        CGRect(x: -200, y: 900, width: 1200, height: 800), primaryHeight: 900),
      CGRect(x: -200, y: -800, width: 1200, height: 800)
    )
    XCTAssertEqual(
      WindowGeometry.accessibilityRect(
        CGRect(x: 0, y: -800, width: 1200, height: 800), primaryHeight: 900),
      CGRect(x: 0, y: 900, width: 1200, height: 800)
    )
  }

  func testChoosesDisplayWithLargestIntersection() {
    let screens = [
      CGRect(x: 0, y: 0, width: 1000, height: 800), CGRect(x: 1000, y: 0, width: 1000, height: 800),
    ]
    XCTAssertEqual(
      WindowGeometry.screenIndex(
        for: CGRect(x: 800, y: 200, width: 600, height: 300), screens: screens), 1)
    XCTAssertEqual(
      WindowGeometry.screenIndex(
        for: CGRect(x: 750, y: 200, width: 300, height: 300), screens: screens), 0)
  }

  func testDisconnectedDisplayFallsBackToNearestScreen() {
    let screens = [
      CGRect(x: 0, y: 0, width: 1000, height: 800),
      CGRect(x: -1000, y: 0, width: 1000, height: 800),
    ]
    XCTAssertEqual(
      WindowGeometry.screenIndex(
        for: CGRect(x: -2000, y: 200, width: 200, height: 200), screens: screens), 1)
    XCTAssertNil(WindowGeometry.screenIndex(for: .zero, screens: []))
  }

  func testConstrainedWindowsKeepRequestedAnchor() {
    let bounds = CGRect(x: 0, y: 30, width: 1000, height: 770)
    let size = CGSize(width: 650, height: 600)
    XCTAssertEqual(
      WindowGeometry.position(for: .right, size: size, in: bounds), CGPoint(x: 350, y: 30))
    XCTAssertEqual(
      WindowGeometry.position(for: .bottom, size: size, in: bounds), CGPoint(x: 0, y: 200))
    XCTAssertEqual(
      WindowGeometry.position(for: .center, size: size, in: bounds), CGPoint(x: 175, y: 115))
  }
}
