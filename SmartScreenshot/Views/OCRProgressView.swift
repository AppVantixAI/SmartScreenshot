import SwiftUI

struct OCRProgressView: View {
    @Binding var progress: Double
    let operation: String
    let isIndeterminate: Bool
    
    init(progress: Binding<Double> = .constant(0.0), operation: String, isIndeterminate: Bool = false) {
        self._progress = progress
        self.operation = operation
        self.isIndeterminate = isIndeterminate
    }
    
    var body: some View {
        VStack(spacing: 12) {
            if isIndeterminate {
                ProgressView()
                    .scaleEffect(1.2)
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle())
            }
            
            Text(operation)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            if !isIndeterminate {
                Text("\(Int(progress * 100))%")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .frame(maxWidth: 200)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 8)
    }
}

#Preview {
    VStack(spacing: 20) {
        OCRProgressView(operation: "Processing screenshot...", isIndeterminate: true)
        OCRProgressView(progress: .constant(0.75), operation: "Extracting text from image")
    }
    .padding()
}