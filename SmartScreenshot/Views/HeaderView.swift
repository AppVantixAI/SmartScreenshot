import Defaults
import SwiftUI

struct HeaderView: View {
  @FocusState.Binding var searchFocused: Bool
  @Binding var searchQuery: String

  @Environment(AppState.self) private var appState
  @Environment(\.scenePhase) private var scenePhase

  @Default(.showTitle) private var showTitle
  @Default(.showSmartScreenshot) private var showSmartScreenshot

  var body: some View {
    VStack(spacing: 4) {
      HStack {
        if showTitle {
          VStack(alignment: .leading, spacing: 2) {
            Text("SmartScreenshot")
              .font(.headline)
              .foregroundStyle(.primary)
            
            Text("Auto-OCR Screenshot Text Extraction")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }

        Spacer()

        SearchFieldView(placeholder: "search_placeholder", query: $searchQuery)
          .focused($searchFocused)
          .frame(maxWidth: .infinity)
          .onChange(of: scenePhase) {
            if scenePhase == .background && !searchQuery.isEmpty {
              searchQuery = ""
            }
          }
      }
      
      // Status bar showing item count and last activity
      HStack {
        Text("\(appState.history.items.count) items")
          .font(.caption2)
          .foregroundStyle(.secondary)
        
        Spacer()
        
        if let lastItem = appState.history.items.first {
          Text("Last: \(lastItem.item.lastCopiedAt, style: .relative)")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
      }
    }
    .frame(height: appState.searchVisible ? 45 : 0)
    .opacity(appState.searchVisible ? 1 : 0)
    .padding(.horizontal, 10)
    // 2px is needed to prevent items from showing behind top pinned items during scrolling
    // https://github.com/p0deje/SmartScreenshot/issues/832
    .padding(.bottom, appState.searchVisible ? 5 : 2)
    .background {
      GeometryReader { geo in
        Color.clear
          .task(id: geo.size.height) {
            appState.popup.headerHeight = geo.size.height
          }
      }
    }
  }
}
