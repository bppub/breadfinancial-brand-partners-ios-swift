import Foundation

/// Converts a monetary value in cents to dollars.
public func fromMoneyToDollars(_ moneyValue: Int64?) -> Double? {
    guard let moneyValue else { return nil }

    return Double(moneyValue) / 100.0
}
