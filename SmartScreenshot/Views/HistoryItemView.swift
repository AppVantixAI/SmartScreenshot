import Defaults
import SwiftUI

struct HistoryItemView: View {
  @Bindable var item: HistoryItemDecorator

  @Environment(AppState.self) private var appState

  var body: some View {
    ListItemView(
      id: item.id,
      appIcon: item.applicationImage,
      image: item.thumbnailImage,
      accessoryImage: item.thumbnailImage != nil ? nil : ColorImage.from(item.title),
      attributedTitle: item.attributedTitle,
      shortcuts: item.shortcuts,
      isSelected: item.isSelected
    ) {
      VStack(alignment: .leading, spacing: 2) {
        // Main title
        Text(verbatim: item.title)
          .lineLimit(2)
        
        // Additional info for screenshot items
        if item.thumbnailImage != nil {
          HStack(spacing: 8) {
            // OCR indicator
            HStack(spacing: 4) {
              Image(systemName: "text.magnifyingglass")
                .font(.caption2)
                .foregroundColor(.blue)
              Text("OCR Text Available")
                .font(.caption2)
                .foregroundColor(.secondary)
            }
            
            // Timestamp
            Text("Copied \(item.item.lastCopiedAt, style: .relative) ago")
              .font(.caption2)
              .foregroundColor(.secondary)
            
            // App name if available
            if let appName = item.application {
              Text(appName)
                .font(.caption2)
                .foregroundColor(.secondary)
            }
          }
        }
      }
    }
    .onTapGesture {
      appState.history.select(item)
    }
    .popover(isPresented: $item.showPreview, arrowEdge: .trailing) {
      PreviewItemView(item: item)
    }
  }
}
