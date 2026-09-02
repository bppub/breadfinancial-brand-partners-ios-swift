import Foundation

package final class CoreLogger: @unchecked Sendable {
    package var isEnabled = false
    package var sink: @Sendable (String) -> Void

    package init(sink: @escaping @Sendable (String) -> Void = { _ in }) {
        self.sink = sink
    }

    package func emit(
        _ items: [Any],
        separator: String = " ",
        terminator: String = "\n"
    ) {
        guard isEnabled else { return }

        let message = items.map(String.init(describing:)).joined(separator: separator)
        Swift.print(message, terminator: terminator)
        sink(message)
    }

    package func requestMessage(
        url: URL,
        method: String,
        headers: [String: String]?,
        body: Data?
    ) -> String {
        var lines = [
            "\n--------------- Request Details ---------------",
            "URL     : \(url)",
            "Method  : \(method)",
        ]

        if let headers {
            lines.append("Headers :")
            lines.append(contentsOf: headers.map { "  \($0.key): \($0.value)" }.sorted())
        } else {
            lines.append("Headers : None")
        }
        lines.append("Body    : \(formattedRequestBody(body))")
        lines.append("--------------------------------------------------\n")
        return lines.joined(separator: "\n")
    }

    package func responseMessage(
        url: URL,
        statusCode: Int,
        headers: [AnyHashable: Any],
        body: Data?
    ) -> String {
        var lines = [
            "\n--------------- Response Details ---------------",
            "URL         : \(url)",
            "Status Code : \(statusCode)",
            "Headers :",
        ]
        lines.append(
            contentsOf: headers.compactMap { entry in
                responseHeaderLine(key: entry.key, value: entry.value)
            }.sorted()
        )
        lines.append("Body        : \(formattedResponseBody(body))")
        lines.append("--------------------------------------------------\n")
        return lines.joined(separator: "\n")
    }

    package func loadingURLMessage(_ url: URL) -> String {
        [
            "--------------- WebView URL ---------------",
            url.absoluteString.trimmingCharacters(in: .whitespacesAndNewlines),
            "--------------------------------------------------",
        ].joined(separator: "\n")
    }

    package func reCaptchaTokenMessage(_ token: String) -> String {
        [
            "--------------- ReCAPTCHA TOKEN ---------------",
            token,
            "--------------------------------------------------",
        ].joined(separator: "\n")
    }

    package func applicationResultMessage(_ payload: [String: Any]) -> String {
        [
            "\n---------- Application Result Details ----------",
            "Application ID     : \(payload["applicationId"] ?? "N/A")",
            "Call ID            : \(payload["callId"] ?? "N/A")",
            "Card Type          : \(payload["cardType"] ?? "N/A")",
            "Email Address      : \(payload["emailAddress"] ?? "N/A")",
            "Message            : \(payload["message"] ?? "N/A")",
            "Mobile Phone       : \(payload["mobilePhone"] ?? "N/A")",
            "Result             : \(payload["result"] ?? "N/A")",
            "Status             : \(payload["status"] ?? "N/A")",
            "--------------------------------------------------\n",
        ].joined(separator: "\n")
    }

    package func webAnchorsMessage(_ data: String) -> String {
        [
            "\n--------------- Anchors List ---------------",
            data,
            "--------------------------------------------------\n",
        ].joined(separator: "\n")
    }

    private func responseHeaderLine(key: AnyHashable, value: Any) -> String? {
        guard let displayableValue = value as? CustomStringConvertible else { return nil }
        return "  \(key): \(displayableValue)"
    }

    private func formattedRequestBody(_ body: Data?) -> String {
        guard let body else { return "No Body" }

        if let object = try? JSONSerialization.jsonObject(with: body),
            let prettyData = try? JSONSerialization.data(
                withJSONObject: object,
                options: .prettyPrinted
            )
        {
            return String(decoding: prettyData, as: UTF8.self)
        }
        return "No Body"
    }

    private func formattedResponseBody(_ body: Data?) -> String {
        let requestBody = formattedRequestBody(body)
        if requestBody != "No Body" {
            return requestBody
        }
        guard let body else { return "No Body" }
        return String(data: body, encoding: .utf8) ?? "No Body"
    }
}
