package enum RTPSRequestHeaders {
    package static let clientKey = "X-Client-Key"
    package static let requestedWith = "X-Requested-With"
    package static let xmlHttpRequest = "XMLHttpRequest"
}

package enum RTPSRecaptcha {
    package static let action = "checkout"
    package static let timeout: Double = 10000
}
