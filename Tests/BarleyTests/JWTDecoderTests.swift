import Testing
@testable import Barley

struct JWTDecoderTests {
    @Test
    func decodeValidToken() throws {
        let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRydWUsInJvbGVzIjpbImRldiIsIm9wcyJdfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"

        let decoded = try JWTDecoder.decode(token)

        #expect(decoded.header["alg"] == .string("HS256"))
        #expect(decoded.payload["sub"] == .string("1234567890"))
        #expect(decoded.payload["admin"] == .bool(true))
    }

    @Test
    func rejectsInvalidFormat() {
        #expect(throws: JWTDecodeError.invalidTokenFormat) {
            try JWTDecoder.decode("abc")
        }
    }

    @Test
    func flattensAndSearchesClaims() {
        let payload: [String: JSONValue] = [
            "sub": .string("42"),
            "profile": .object([
                "email": .string("devly@example.com")
            ]),
            "roles": .array([
                .string("admin"),
                .string("engineer")
            ])
        ]

        let flattened = JWTClaimSearcher.flattenedClaims(from: payload)
        let matches = JWTClaimSearcher.search("engineer", in: flattened)

        #expect(flattened.contains { $0.path == "profile.email" && $0.value == "devly@example.com" })
        #expect(matches.contains { $0.path == "roles[1]" && $0.value == "engineer" })
    }
}
