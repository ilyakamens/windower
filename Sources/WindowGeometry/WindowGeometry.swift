import CoreGraphics
import Foundation

public enum WindowAction: Int, CaseIterable, Sendable {
  case left, right, top, bottom, center, maximize

  public var title: String {
    switch self {
    case .left: "Left Half"
    case .right: "Right Half"
    case .top: "Top Half"
    case .bottom: "Bottom Half"
    case .center: "Center"
    case .maximize: "Fill Screen"
    }
  }
}

/// All rectangles use Accessibility coordinates: origin at the main display's top left.
public enum WindowGeometry {
  public static func accessibilityRect(_ rect: CGRect, primaryHeight: CGFloat) -> CGRect {
    CGRect(x: rect.minX, y: primaryHeight - rect.maxY, width: rect.width, height: rect.height)
  }

  public static func screenIndex(for window: CGRect, screens: [CGRect]) -> Int? {
    guard !screens.isEmpty else { return nil }
    let areas = screens.map { screen -> CGFloat in
      let intersection = screen.intersection(window)
      return intersection.isNull ? 0 : intersection.width * intersection.height
    }
    if let best = areas.indices.max(by: { areas[$0] < areas[$1] }), areas[best] > 0 {
      return best
    }
    // Recover windows left offscreen after a monitor disconnect.
    return screens.indices.min { distance(window, screens[$0]) < distance(window, screens[$1]) }
  }

  public static func target(for action: WindowAction, in bounds: CGRect) -> CGRect {
    let halfWidth = floor(bounds.width / 2)
    let halfHeight = floor(bounds.height / 2)
    switch action {
    case .left:
      return CGRect(x: bounds.minX, y: bounds.minY, width: halfWidth, height: bounds.height)
    case .right:
      return CGRect(
        x: bounds.minX + halfWidth, y: bounds.minY,
        width: bounds.width - halfWidth, height: bounds.height)
    case .top:
      return CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: halfHeight)
    case .bottom:
      return CGRect(
        x: bounds.minX, y: bounds.minY + halfHeight,
        width: bounds.width, height: bounds.height - halfHeight)
    case .maximize:
      return bounds
    case .center:
      let size = CGSize(width: floor(bounds.width * 0.75), height: floor(bounds.height * 0.75))
      return CGRect(
        x: bounds.midX - size.width / 2, y: bounds.midY - size.height / 2,
        width: size.width, height: size.height)
    }
  }

  /// Anchor the actual size when an app enforces a minimum size or resize increments.
  public static func position(for action: WindowAction, size: CGSize, in bounds: CGRect) -> CGPoint
  {
    let target = target(for: action, in: bounds)
    switch action {
    case .right: return CGPoint(x: bounds.maxX - size.width, y: bounds.minY)
    case .bottom: return CGPoint(x: bounds.minX, y: bounds.maxY - size.height)
    case .center: return CGPoint(x: bounds.midX - size.width / 2, y: bounds.midY - size.height / 2)
    default: return target.origin
    }
  }

  private static func distance(_ window: CGRect, _ screen: CGRect) -> CGFloat {
    let dx = max(screen.minX - window.midX, 0, window.midX - screen.maxX)
    let dy = max(screen.minY - window.midY, 0, window.midY - screen.maxY)
    return dx * dx + dy * dy
  }
}
