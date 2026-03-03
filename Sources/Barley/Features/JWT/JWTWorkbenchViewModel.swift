import Foundation

@MainActor
final class JWTWorkbenchViewModel: ObservableObject {
    @Published var token: String = ""
    @Published var claimQuery: String = "" {
        didSet {
            filterClaims()
        }
    }

    @Published private(set) var errorMessage: String?
    @Published private(set) var headerJSON: String = ""
    @Published private(set) var payloadJSON: String = ""
    @Published private(set) var claims: [ClaimEntry] = []
    @Published private(set) var filteredClaims: [ClaimEntry] = []

    func decodeToken() {
        do {
            let decoded = try JWTDecoder.decode(token)
            errorMessage = nil
            headerJSON = JWTDecoder.prettyPrintedJSON(from: decoded.header)
            payloadJSON = JWTDecoder.prettyPrintedJSON(from: decoded.payload)
            claims = JWTClaimSearcher.flattenedClaims(from: decoded.payload)
            filterClaims()
        } catch let error as JWTDecodeError {
            clearDecodedState()
            errorMessage = error.errorDescription
        } catch {
            clearDecodedState()
            errorMessage = "Unable to decode JWT."
        }
    }

    func clearAll() {
        token = ""
        claimQuery = ""
        errorMessage = nil
        clearDecodedState()
    }

    private func filterClaims() {
        filteredClaims = JWTClaimSearcher.search(claimQuery, in: claims)
    }

    private func clearDecodedState() {
        headerJSON = ""
        payloadJSON = ""
        claims = []
        filteredClaims = []
    }
}
