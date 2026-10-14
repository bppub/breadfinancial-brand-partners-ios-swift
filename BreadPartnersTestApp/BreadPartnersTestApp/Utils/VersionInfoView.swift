import SwiftUI

struct VersionInfoView: View {
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    var body: some View {
        VStack {
            Text("App Version: \(appVersion) (\(buildNumber))")
                .font(.footnote)
                .padding()
        }
    }
}

struct VersionInfoView_Previews: PreviewProvider {
    static var previews: some View {
        VersionInfoView()
    }
}
