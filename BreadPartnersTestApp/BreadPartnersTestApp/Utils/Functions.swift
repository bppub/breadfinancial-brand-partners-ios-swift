import UIKit

func presentPopup(_ popup: UIViewController) {
    guard
        let windowScene = UIApplication.shared.connectedScenes.first
            as? UIWindowScene,
        let rootVC = windowScene.windows.first?.rootViewController
    else { return }

    popup.modalPresentationStyle = .overFullScreen
    popup.modalTransitionStyle = .crossDissolve

    rootVC.present(popup, animated: true)
}

func hideKeyboard() {
    UIApplication.shared.sendAction(
        #selector(UIResponder.resignFirstResponder), to: nil, from: nil,
        for: nil)
}
