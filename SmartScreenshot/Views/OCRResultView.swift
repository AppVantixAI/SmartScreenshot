import SwiftUI

struct OCRResultView: View {
    let originalImage: NSImage
    let extractedText: String
    @State private var editedText: String
    @Environment(\.dismiss) private var dismiss
    
    init(originalImage: NSImage, extractedText: String) {
        self.originalImage = originalImage
        self.extractedText = extractedText
        self._editedText = State(initialValue: extractedText)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("OCR Result")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(.regularMaterial)
            
            // Content
            HSplitView {
                // Original Image
                VStack {
                    Text("Original Image")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.top)
                    
                    Image(nsImage: originalImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding()
                }
                .frame(minWidth: 200, maxWidth: 400)
                
                // Extracted Text
                VStack {
                    HStack {
                        Text("Extracted Text")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Button("Copy All") {
                            copyToClipboard(editedText)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    TextEditor(text: $editedText)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(Color(.textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal)
                        .padding(.bottom)
                }
                .frame(minWidth: 300)
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .background(Color(.windowBackgroundColor))
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

#Preview {
    OCRResultView(
        originalImage: NSImage(),
        extractedText: "Sample extracted text from OCR processing..."
    )
}