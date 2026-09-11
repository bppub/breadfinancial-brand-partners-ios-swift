import Foundation

package extension Optional where Wrapped == String {
    func takeIfNotEmpty() -> String? {
        guard let value = self,
            !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }
        return value
    }
}
