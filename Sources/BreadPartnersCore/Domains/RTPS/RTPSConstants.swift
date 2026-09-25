package enum RTPSRequestHeaders {
    package static let clientKey = "X-Client-Key"
    package static let requestedWith = "X-Requested-With"
    package static let xmlHttpRequest = "XMLHttpRequest"
}

package enum RTPSRecaptcha {
    package static let action = "checkout"
    package static let timeout: Double = 10000
}

package enum RTPSConstants {
    package static let error = "Error:"

    package static func apiError(message: String) -> String {
        "\(error) \(message)"
    }

    package static func catchError(message: String) -> String {
        apiError(message: message)
    }

    package static let prescreenRequiredFieldsError =
        "Error: Prescreen requires customer information: firstname, lastname, and complete billing address must be provided in MerchantConfiguration."
}
