package protocol RTPSResponseDecoding: Sendable {
    func decode<T: Decodable>(
        _ type: T.Type,
        from response: RTPSNetworkResponse
    ) throws -> T
}
