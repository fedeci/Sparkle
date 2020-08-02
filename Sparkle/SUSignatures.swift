//
//  SUSignatures.swift
//  Sparkle
//
//  Created by Federico Ciardi on 27/07/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

enum SUSigningInputStatus: UInt8 {
    /// An input was not provided at all.
    case absent = 0

    /// An input was provided, but did not have the correct format.
    case invalid

    /// An input was provided and can be used for verifying signing information.
    case present
    static let lastValidCase = SUSigningInputStatus.present.rawValue
}

private let SUDSASignatureKey = "SUDSASignature"
private let SUDSASignatureStatusKey = "SUDSASignatureStatus"
private let SUEDSignatureKey = "SUEDSignature"
private let SUEDSignatureStatusKey = "SUEDSignatureStatus"

// MARK: -
@objcMembers
class SUSignatures: NSObject {
    private var _ed25519Signature = [UInt8](repeating: 0, count: 64)
    private(set) var dsaSignature: Data?
    private(set) var dsaSignatureStatus: SUSigningInputStatus?
    private(set) var ed25519SignatureStatus: SUSigningInputStatus?

    var ed25519Signature: [UInt8]? {
        if ed25519SignatureStatus == .present {
            return _ed25519Signature
        }
        return nil
    }

    init(dsa maybeDsa: String?, ed maybeEd25519: String?) {
        super.init()
        dsaSignatureStatus = decode(maybeDsa, &dsaSignature)
        if dsaSignatureStatus == .invalid {
            SULog(.error, "The provided DSA signature could not be decoded.")
        }

        if maybeEd25519 != nil {
            var data: Data?
            ed25519SignatureStatus = decode(maybeEd25519, &data)
            if let data = data {
                assert(64 == MemoryLayout.size(ofValue: _ed25519Signature))
                if data.count == MemoryLayout.size(ofValue: _ed25519Signature) {
                    data.copyBytes(to: &_ed25519Signature, count: MemoryLayout.size(ofValue: _ed25519Signature))
                } else {
                    ed25519SignatureStatus = .invalid
                }
            }

            if ed25519SignatureStatus == .invalid {
                SULog(.error, "The provided EdDSA signature could not be decoded.")
            }
        }
    }

    required init?(coder: NSCoder) {
        super.init()
        guard decodeStatus(decoder: coder, key: SUDSASignatureStatusKey, outStatus: &dsaSignatureStatus) else { return nil }

        if let dsaSignature = coder.decodeObject(forKey: SUDSASignatureKey) as? Data {
            self.dsaSignature = dsaSignature
        }

        guard decodeStatus(decoder: coder, key: SUEDSignatureStatusKey, outStatus: &ed25519SignatureStatus) else { return nil }

        if let edSignature = coder.decodeObject(forKey: SUEDSignatureKey) as? Data {
            guard edSignature.count == MemoryLayout.size(ofValue: _ed25519Signature) else { return nil }
            edSignature.copyBytes(to: &_ed25519Signature, count: MemoryLayout.size(ofValue: _ed25519Signature))
        }
    }
}

extension SUSignatures: NSSecureCoding {
    static var supportsSecureCoding: Bool {
        return true
    }

    func encode(with coder: NSCoder) {
        coder.encode(dsaSignatureStatus, forKey: SUDSASignatureStatusKey)

        if dsaSignature != nil {
            coder.encode(dsaSignature, forKey: SUDSASignatureKey)
        }

        coder.encode(ed25519SignatureStatus, forKey: SUEDSignatureStatusKey)
        if ed25519Signature != nil {
            let edSignature = Data(bytesNoCopy: &_ed25519Signature, count: MemoryLayout.size(ofValue: _ed25519Signature), deallocator: .free)
            coder.encode(edSignature, forKey: SUEDSignatureKey)
        }
    }
}

// MARK: -
@objcMembers
class SUPublicKeys: NSObject {
    private var _ed25519PubKey = [UInt8](repeating: 0, count: 32)
    private(set) var dsaPubKey: String?

    var dsaPubKeyStatus: SUSigningInputStatus {
        // We don't currently do any prevalidation of DSA public keys,
        // so this is always going to be "present" or "absent".
        return dsaPubKey != nil ? .present : .absent
    }

    var ed25519PubKey: [UInt8]? {
        if ed25519PubKeyStatus == .present {
            return _ed25519PubKey
        }
        return nil
    }

    private(set) var ed25519PubKeyStatus: SUSigningInputStatus?

    /// Returns true if either key is present (though they may be invalid).
    var hasAnyKeys: Bool {
        return dsaPubKeyStatus != .absent || ed25519PubKeyStatus != .absent
    }

    init(dsa maybeDsa: String?, ed maybeEd25519: String?) {
        super.init()
        dsaPubKey = maybeDsa
        if let maybeEd25519 = maybeEd25519 {
            var ed: Data?
            ed25519PubKeyStatus = decode(maybeEd25519, &ed)
            if let ed = ed {
                assert(32 == MemoryLayout.size(ofValue: _ed25519PubKey))
                if ed.count == MemoryLayout.size(ofValue: _ed25519PubKey) {
                    ed.copyBytes(to: &_ed25519PubKey, count: MemoryLayout.size(ofValue: _ed25519PubKey))
                } else {
                    ed25519PubKeyStatus = .invalid
                }
            }

            if ed25519PubKeyStatus == .invalid {
                SULog(.error, "The provided EdDSA key could not be decoded.")
            }
        }
    }
}

// MARK: -
private func decode(_ str: String?, _ outData: inout Data?) -> SUSigningInputStatus {
    guard let str = str else { return .absent }

    let stripped = str.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let result = Data(base64Encoded: stripped) else { return .invalid }

    outData = result
    return .present
}

private func decodeStatus(decoder: NSCoder, key: String, outStatus: inout SUSigningInputStatus?) -> Bool {
    let rawValue = decoder.decodeInteger(forKey: key)
    guard rawValue <= SUSigningInputStatus.lastValidCase,
          let status = SUSigningInputStatus(rawValue: UInt8(rawValue))
    else { return false }

    outStatus = status
    return true
}
