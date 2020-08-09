//
//  SUStandardVersionComparator.swift
//  Sparkle
//
//  Created by Federico Ciardi on 03/08/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

// MARK: One-time initialized variables
private var _defaultComparator: SUStandardVersionComparator?

private let dispatchOnce: () = {
    _defaultComparator = SUStandardVersionComparator()
}()

// MARK: -
/// Sparkle's default version comparator.
///
/// This comparator is adapted from MacPAD, by Kevin Ballard.
/// It's "dumb" in that it does essentially string comparison,
/// in components split by character type.
@objcMembers
public class SUStandardVersionComparator: NSObject {

    private enum SUCharacterType: Int {
        case kNumberType
        case kStringType
        case kSeparatorType
    }

    /// Initializes a new instance of the standard version comparator.
    override public init() {
        super.init()
    }

    /// Returns a singleton instance of the comparator.
    ///
    /// It is usually preferred to alloc/init new a comparator instead.
    public class func defaultComparator() -> SUStandardVersionComparator? {
        _ = dispatchOnce

        return _defaultComparator
    }

    private func type(ofCharacter character: String) -> SUCharacterType {
        if character == "." {
            return .kSeparatorType
        } else {
            let characterSet = CharacterSet(charactersIn: String(character.prefix(1)))

            if characterSet.isSubset(of: .decimalDigits) {
                return .kNumberType
            } else if characterSet.isSubset(of: .whitespacesAndNewlines) {
                return .kSeparatorType
            } else if characterSet.isSubset(of: .punctuationCharacters) {
                return .kSeparatorType
            } else {
                return .kStringType
            }
        }
    }

    private func splitVersionString(_ version: String) -> [String] {
        var parts: [String] = []
        guard version.count != 0 else { return parts } // Nothing to do here

        var s = String(version.prefix(1))
        var oldType = type(ofCharacter: s)
        var newType: SUCharacterType
        for i in 1...version.count - 1 {
            let startIndex = version.index(version.startIndex, offsetBy: i)
            let endIndex = version.index(startIndex, offsetBy: 1)
            let character = String(version[startIndex..<endIndex])

            newType = type(ofCharacter: character)
            if oldType != newType || oldType == .kSeparatorType {
                // We've reached a new segment
                parts.append(s)
                s = character
            } else {
                // Add character to string and continue
                s.append(character)
            }
            oldType = newType
        }

        // Add the last part onto the array
        parts.append(s)
        return parts
    }
}

extension SUStandardVersionComparator: SUVersionComparison {

    /// Compares version strings through textual analysis.
    ///
    /// See the implementation for more details.
    func compareVersion(_ versionA: String, toVersion versionB: String) -> ComparisonResult {
        let partsA = splitVersionString(versionA)
        let partsB = splitVersionString(versionB)

        let n = min(partsA.count, partsB.count)
        for i in 0..<n {
            let partA = partsA[i]
            let partB = partsB[i]

            let typeA = type(ofCharacter: partA)
            let typeB = type(ofCharacter: partB)

            // Compare types
            if typeA == typeB {
                // Same type; we can compare
                if typeA == .kNumberType {
                    let valueA = Int64(partA) ?? 0
                    let valueB = Int64(partB) ?? 0
                    return valueA > valueB ? .orderedDescending : .orderedAscending
                } else if typeA == .kStringType {
                    let result = partA.compare(partB)
                    if result != .orderedSame {
                        return result
                    }
                }
            } else {
                // Not the same type? Now we have to do some validity checking
                if typeA != .kStringType && typeB == .kStringType {
                    // typeA wins
                    return .orderedDescending
                } else if typeA == .kStringType && typeB != .kStringType {
                    // typeB wins
                    return .orderedAscending
                } else {
                    // One is a number and the other is a period. The period is invalid
                    return typeA == .kNumberType ? .orderedDescending : .orderedAscending
                }
            }
        }
        // The versions are equal up to the point where they both still have parts
        // Lets check to see if one is larger than the other
        if partsA.count != partsB.count {
            // Yep. Lets get the next part of the larger
            // n holds the index of the part we want.
            var missingPart: String
            var shorterResult: ComparisonResult
            var largerResult: ComparisonResult

            if partsA.count > partsB.count {
                missingPart = partsA[n]
                shorterResult = .orderedAscending
                largerResult = .orderedDescending
            } else {
                missingPart = partsB[n]
                shorterResult = .orderedDescending
                largerResult = .orderedAscending
            }

            let missingType = type(ofCharacter: missingPart)
            // Check the type
            // If it's a string. Shorter version wins
            // else it's a number/period. Larger version wins
            return missingType == .kStringType ? shorterResult : largerResult
        }

        // The 2 strings are identical
        return .orderedSame
    }
}
