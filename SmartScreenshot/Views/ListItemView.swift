import Defaults
import SwiftUI

struct ListItemView<Title: View>: View {
  var id: UUID
  var appIcon: ApplicationImage?
  var image: NSImage?
  var accessoryImage: NSImage?
  var attributedTitle: AttributedString?
  var shortcuts: [KeyShortcut]
  var isSelected: Bool
  var help: LocalizedStringKey?
  @ViewBuilder var title: () -> Title

  @Default(.showApplicationIcons) private var showIcons
  @Environment(AppState.self) private var appState
  @Environment(ModifierFlags.self) private var modifierFlags

  // Generate helpful tooltip based on item type
  private var helpfulTooltip: LocalizedStringKey {
    if image != nil {
      return "Screenshot with OCR text. Click to copy the extracted text to clipboard."
    } else if accessoryImage != nil {
      return "Text content. Click to copy to clipboard."
    } else {
      return "Clipboard item. Click to copy to clipboard."
    }
  }

  var body: some View {
    HStack(spacing: 0) {
      if showIcons, let appIcon {
        VStack {
          Spacer(minLength: 0)
          Image(nsImage: appIcon.nsImage)
            .resizable()
            .frame(width: 15, height: 15)
          Spacer(minLength: 0)
        }
        .padding(.leading, 4)
        .padding(.vertical, 5)
      }

      Spacer()
        .frame(width: showIcons ? 5 : 10)

      // Enhanced content preview area
      contentPreviewArea
        .padding(.trailing, 5)
        .padding(.vertical, 5)

      Spacer()

      if !shortcuts.isEmpty {
        ZStack {
          ForEach(shortcuts) { shortcut in
            KeyboardShortcutView(shortcut: shortcut)
              .opacity(shortcut.isVisible(shortcuts, modifierFlags.flags) ? 1 : 0)
          }
        }
        .padding(.trailing, 10)
      } else {
        Spacer()
          .frame(width: 50)
      }
    }
    .frame(minHeight: 22)
    .id(id)
    .frame(maxWidth: .infinity, alignment: .leading)
    .foregroundStyle(isSelected ? Color.white : .primary)
    .background(isSelected ? Color.accentColor.opacity(0.8) : .clear)
    .clipShape(.rect(cornerRadius: 4))
    .onHover { hovering in
      if hovering {
        if !appState.isKeyboardNavigating {
          appState.selectWithoutScrolling(id)
        } else {
          appState.hoverSelectionWhileKeyboardNavigating = id
        }
      }
    }
    .help(help ?? helpfulTooltip)
  }
  
  // Enhanced content preview area with different content types
  @ViewBuilder
  private var contentPreviewArea: some View {
    if let image = image {
      // Image preview with enhanced styling
      VStack(spacing: 4) {
        Image(nsImage: image)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(maxWidth: 60, maxHeight: 40)
          .clipShape(RoundedRectangle(cornerRadius: 6))
          .overlay(
            RoundedRectangle(cornerRadius: 6)
              .stroke(Color.gray.opacity(0.3), lineWidth: 1)
          )
        
        // Image indicator
        HStack(spacing: 4) {
          Image(systemName: "photo")
            .font(.caption2)
            .foregroundColor(.blue)
          Text("Image")
            .font(.caption2)
            .foregroundColor(.secondary)
        }
      }
      .accessibilityIdentifier("copy-history-item")
      
    } else if let accessoryImage = accessoryImage {
      // Text content preview with enhanced styling
      VStack(spacing: 4) {
        Image(nsImage: accessoryImage)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(maxWidth: 60, maxHeight: 40)
          .clipShape(RoundedRectangle(cornerRadius: 6))
          .overlay(
            RoundedRectangle(cornerRadius: 6)
              .stroke(Color.gray.opacity(0.3), lineWidth: 1)
          )
        
        // Text indicator
        HStack(spacing: 4) {
          Image(systemName: "doc.text")
            .font(.caption2)
            .foregroundColor(.green)
          Text("Text")
            .font(.caption2)
            .foregroundColor(.secondary)
        }
      }
      .accessibilityIdentifier("copy-history-item")
      
    } else {
      // Default title view for other content types
      ListItemTitleView(attributedTitle: attributedTitle, title: title)
    }
  }
}
