import BreadPartners
import SwiftUI

struct DynamicPopupStyles: View {
    @State private var stylePopup: Bool = false
    @State private var selectedColorTheme: PopupStyleThemes =
        popupStyleThemeConst.first ?? popupStyleThemeConst[0]
    @State private var expandable: Bool = false
    @Binding var formData: PlacementFormData

    var body: some View {
        VStack {
            Text(
                "Popup styling will be applied only after generating a fresh placement."
            )

            Toggle(
                "Style Popup: ",
                isOn: $formData.stylePopup
            )
            
            Spacer()
                .frame(
                    height: 15
                )
            
            Menu {
                ForEach(
                    popupStyleThemeConst,
                    id: \.name
                ) { theme in
                    Button(
                        action: {
                            selectedColorTheme = theme
                            formData.popupStyleThemes = theme
                        }) {
                            Text(
                                theme.name
                            )
                        }
                }
            } label: {
                Text(
                    "Select Color Theme: \(selectedColorTheme.name)"
                )
                .padding()
                .background(
                    Color.blue.opacity(
                        0.2
                    )
                )
                .cornerRadius(
                    8
                )
            }
        }
        .padding()
    }
}
