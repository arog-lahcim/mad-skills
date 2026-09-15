import CoreGraphics
import Foundation

let owner = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Google Chrome for Testing"
let titlePrefix = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : ""

guard let info = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
  fputs("Could not read window list\n", stderr)
  exit(1)
}

for window in info {
  guard let name = window[kCGWindowOwnerName as String] as? String, name == owner else {
    continue
  }
  let title = window[kCGWindowName as String] as? String ?? ""
  if !titlePrefix.isEmpty && !title.hasPrefix(titlePrefix) {
    continue
  }
  if let windowId = window[kCGWindowNumber as String] {
    print(windowId)
    exit(0)
  }
}

fputs("window not found for owner=\(owner) titlePrefix=\(titlePrefix)\n", stderr)
exit(1)
