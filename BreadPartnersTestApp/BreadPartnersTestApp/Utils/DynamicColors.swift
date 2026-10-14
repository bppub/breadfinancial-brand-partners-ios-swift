import SwiftUI

struct DynamicColors: View {

    @Binding var formData: PlacementFormData

    @State private var selectedPrimaryColorName = "Black"
    @State private var selectedSecondaryColorName = "Blue"

    let colors: [String: Color] = [
        "Black": .black,
        "Red": .red,
        "Green": .green,
        "Blue": .blue,
        "Gray": .gray,
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            Menu {
                ForEach(colors.keys.sorted(), id: \.self) { colorName in
                    Button(action: {
                        selectedPrimaryColorName = colorName
                        formData.primaryColor = colors[
                            selectedPrimaryColorName]!
                    }) {
                        Text(colorName)
                    }
                }
            } label: {
                Text("Primary Color: \(selectedPrimaryColorName)")
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
            }

            Menu {
                ForEach(colors.keys.sorted(), id: \.self) { colorName in
                    Button(action: {
                        selectedSecondaryColorName = colorName
                        formData.secondaryColor = colors[
                            selectedSecondaryColorName]!
                    }) {
                        Text(colorName)
                    }
                }
            } label: {
                Text("Secondary Color: \(selectedSecondaryColorName)")
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
            }
        }
        .padding()
    }
}
