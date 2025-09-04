import KeyboardShortcuts

extension KeyboardShortcuts.Name {
  static let popup = Self("popup", default: Shortcut(.c, modifiers: [.command, .shift]))
  static let pin = Self("pin", default: Shortcut(.p, modifiers: [.option]))
  static let delete = Self("delete", default: Shortcut(.delete, modifiers: [.option]))
  static let screenshotOCR = Self("screenshotOCR", default: Shortcut(.s, modifiers: [.command, .shift]))
  static let regionOCR = Self("regionOCR", default: Shortcut(.r, modifiers: [.command, .shift]))
  static let appOCR = Self("appOCR", default: Shortcut(.a, modifiers: [.command, .shift]))
  static let bulkOCR = Self("bulkOCR", default: Shortcut(.b, modifiers: [.command, .shift]))

}
