import SwiftData
import SwiftUI

struct ContentView: View {
  @State private var appState = AppState.shared
  @State private var modifierFlags = ModifierFlags()
  @State private var scenePhase: ScenePhase = .background
  @State private var showingSmartScreenshot = false

  @FocusState private var searchFocused: Bool

  var body: some View {
    ZStack {
      VisualEffectView()

      VStack(alignment: .leading, spacing: 0) {
        KeyHandlingView(searchQuery: $appState.history.searchQuery, searchFocused: $searchFocused) {
          HeaderView(
            searchFocused: $searchFocused,
            searchQuery: $appState.history.searchQuery
          )

          if showingSmartScreenshot {
            SmartScreenshotMainView()
              .transition(.slide)
          } else {
            HistoryListView(
              searchQuery: $appState.history.searchQuery,
              searchFocused: $searchFocused
            )
            .transition(.slide)
          }

          FooterView(footer: appState.footer)
        }
      }
      .animation(.default.speed(3), value: appState.history.items)
      .animation(.easeInOut(duration: 0.2), value: appState.searchVisible)
      .animation(.easeInOut(duration: 0.3), value: showingSmartScreenshot)
      .padding(.horizontal, 5)
      .padding(.vertical, appState.popup.verticalPadding)
      .onAppear {
        searchFocused = true
      }
      .onMouseMove {
        appState.isKeyboardNavigating = false
      }
      .task {
        try? await appState.history.load()
      }
    }
    .environment(appState)
    .environment(modifierFlags)
    .environment(\.scenePhase, scenePhase)
    // FloatingPanel is not a scene, so let's implement custom scenePhase..
    .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) {
      if let window = $0.object as? NSWindow,
         let bundleIdentifier = Bundle.main.bundleIdentifier,
         window.identifier == NSUserInterfaceItemIdentifier(bundleIdentifier) {
        scenePhase = .active
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)) {
      if let window = $0.object as? NSWindow,
         let bundleIdentifier = Bundle.main.bundleIdentifier,
         window.identifier == NSUserInterfaceItemIdentifier(bundleIdentifier) {
        scenePhase = .background
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: NSPopover.willShowNotification)) {
      if let popover = $0.object as? NSPopover {
        // Prevent NSPopover from showing close animation when
        // quickly toggling FloatingPanel while popover is visible.
        popover.animates = false
        // Prevent NSPopover from becoming first responder.
        popover.behavior = .semitransient
      }
    }
  }
}

// MARK: - Enhanced Search Field View
struct EnhancedSearchFieldView: View {
  let placeholder: LocalizedStringKey
  @Binding var query: String
  
  @State private var isFocused = false
  
  var body: some View {
    TextField(placeholder, text: $query)
      .padding(12)
      .background {
        RoundedRectangle(cornerRadius: 8)
          .fill(.ultraThinMaterial)
          .overlay {
            RoundedRectangle(cornerRadius: 8)
              .stroke(isFocused ? .blue.opacity(0.5) : .white.opacity(0.2), lineWidth: 1)
          }
      }
      .overlay {
        HStack {
          Image(systemName: "magnifyingglass")
            .foregroundStyle(.secondary)
            .padding(.leading, 12)
          
          Spacer()
        }
      }
      .onReceive(NotificationCenter.default.publisher(for: NSControl.textDidBeginEditingNotification)) { _ in
        withAnimation(.easeInOut(duration: 0.2)) {
          isFocused = true
        }
      }
      .onReceive(NotificationCenter.default.publisher(for: NSControl.textDidEndEditingNotification)) { _ in
        withAnimation(.easeInOut(duration: 0.2)) {
          isFocused = false
        }
      }
  }
}

#Preview {
  ContentView()
    .environment(\.locale, .init(identifier: "en"))
    .modelContainer(Storage.shared.container)
}
