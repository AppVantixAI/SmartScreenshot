import AppKit
import Defaults

enum MenuIcon: String, CaseIterable, Identifiable, Defaults.Serializable {
  case smartscreenshot
  case clipboard
  case scissors
  case paperclip

  var id: Self { self }

  var image: NSImage {
    switch self {
    case .smartscreenshot:
      return NSImage(named: .smartscreenshotStatusBar)!
    case .clipboard:
      return NSImage(named: .clipboard)!
    case .scissors:
      return NSImage(named: .scissors)!
    case .paperclip:
      return NSImage(named: .paperclip)!
    }
  }
}
