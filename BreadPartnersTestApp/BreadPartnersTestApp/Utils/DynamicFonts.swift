import SwiftUI

struct DynamicFonts: View {
    
    @Binding var formData: PlacementFormData

    @State private var fontSize: CGFloat = 16
    @State private var selectedFont: String = "Gentium"
    
    let fonts = ["Gentium Plus", "Gloria Hallelujah", "Kaushan Script", "Maven Pro", "Pacifico"]
    
    var fontMapping: [String: String] = [
        "Gentium Plus": "Gentium Plus",
        "Gloria Hallelujah": "Gloria Hallelujah",
        "Kaushan Script": "Kaushan Script",
        "Maven Pro": "Maven Pro",
        "Pacifico": "Pacifico"
    ]
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            HStack {
                Text("Font Size ")
                Slider(value: $formData.fontSize, in: 12...32, step: 1)
            }
            
            Menu {
                ForEach(fonts, id: \.self) { font in
                    Button(action: {
                        selectedFont = font
                        formData.fontName = font
                    }) {
                        Text(font)
                    }
                }
            } label: {
                Text("Select Font: \(selectedFont)")
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
            }            
        }
        .padding()
    }
}
