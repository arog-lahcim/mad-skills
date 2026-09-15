import AppKit
import Foundation

guard let screen = NSScreen.main else {
  fputs("Main screen not found\n", stderr)
  exit(1)
}

let frame = screen.frame
let visible = screen.visibleFrame
let menuBarHeight = frame.height - visible.height

print(
  "\(Int(frame.origin.x)) \(Int(frame.origin.y)) " +
  "\(Int(frame.width)) \(Int(frame.height)) \(Int(menuBarHeight))"
)
