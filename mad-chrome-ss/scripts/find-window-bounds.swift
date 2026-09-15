import CoreGraphics
import Foundation

let owner = CommandLine.arguments.count > 1
  ? CommandLine.arguments[1]
  : "Google Chrome for Testing"
let titlePrefix = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : ""
let ownerPid = CommandLine.arguments.count > 3
  ? Int(CommandLine.arguments[3])
  : nil

guard let info = CGWindowListCopyWindowInfo(
  [.optionOnScreenOnly, .excludeDesktopElements],
  kCGNullWindowID
) as? [[String: Any]] else {
  fputs("Could not read window list\n", stderr)
  exit(1)
}

for window in info {
  guard
    let name = window[kCGWindowOwnerName as String] as? String,
    name == owner
  else {
    continue
  }
  if
    let ownerPid,
    let windowPid = window[kCGWindowOwnerPID as String] as? Int,
    windowPid != ownerPid
  {
    continue
  }

  let title = window[kCGWindowName as String] as? String ?? ""
  if titlePrefix.isEmpty {
    if title.hasPrefix("about:blank") {
      continue
    }
  } else if !title.hasPrefix(titlePrefix) {
    continue
  }

  guard
    let bounds = window[kCGWindowBounds as String] as? [String: CGFloat],
    let x = bounds["X"],
    let y = bounds["Y"],
    let width = bounds["Width"],
    let height = bounds["Height"]
  else {
    continue
  }

  print("\(Int(x)) \(Int(y)) \(Int(width)) \(Int(height))")
  exit(0)
}

fputs("window not found for owner=\(owner) titlePrefix=\(titlePrefix)\n", stderr)
exit(1)
