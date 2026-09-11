import UIKit

@MainActor internal enum DeviceInformationProvider {
    static var userAgent: String {
        let device = UIDevice.current
        return "\(device.model): \(device.systemName) \(device.systemVersion)"
    }
}
