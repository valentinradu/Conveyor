//
//  Swift+CO.swift
//  Conveyor
//
//  Created by Valentin Radu on 11/03/16.
//  Copyright © 2016 Valentin Radu. All rights reserved.
//

import Foundation

enum Error:ErrorType, CustomStringConvertible {
    case success
    case urlNotFound
    case xcodeProjNotFound
    case xcodePbxprojNotFound
    case xcodePbxprojCantOpen
    case xcodePbxprojUnsupportedFormat
    case xcodeProjIsNotLocalized
    case cantOpenFile
    case failedSanitization
    case patternNotFound
    case invalidFile
    case invalidData
    var description: String {
        switch self {
        case .success: return "\(NSLocalizedString("success", comment: ""))"
        case .urlNotFound: return "\(NSLocalizedString("urlNotFound", comment: ""))"
        case .xcodeProjNotFound: return "\(NSLocalizedString("xcodeProjNotFound", comment: ""))"
        case .xcodePbxprojNotFound: return "\(NSLocalizedString("xcodePbxprojNotFound", comment: ""))"
        case .xcodePbxprojCantOpen: return "\(NSLocalizedString("xcodePbxprojCantOpen", comment: ""))"
        case .xcodePbxprojUnsupportedFormat  : return "\(NSLocalizedString("xcodePbxprojUnsupportedFormat", comment: ""))"
        case .cantOpenFile: return "\(NSLocalizedString("cantOpenFile", comment: ""))"
        case .xcodeProjIsNotLocalized: return "\(NSLocalizedString("xcodeProjIsNotLocalized", comment: ""))"
        case .failedSanitization: return "\(NSLocalizedString("failedSanitization", comment: ""))"
        case .patternNotFound: return "\(NSLocalizedString("patternNotFound", comment: ""))"
        case .invalidFile: return "\(NSLocalizedString("invalidFile", comment: ""))"
        case .invalidData: return "\(NSLocalizedString("invalidData", comment: ""))"
        }
    }
    func code() -> Int {
        switch self {
        case .success : return 101
        case .urlNotFound : return 102
        case .xcodeProjNotFound : return 103
        case .xcodePbxprojNotFound : return 104
        case .xcodePbxprojCantOpen : return 105
        case .xcodePbxprojUnsupportedFormat : return 106
        case .cantOpenFile : return 107
        case .xcodeProjIsNotLocalized : return 108
        case .failedSanitization : return 109
        case .patternNotFound : return 110
        case .invalidFile : return 111
        case .invalidData : return 112
        }
    }
}

@noreturn
func exit(status:Error) {
    print(status)
    exit(Int32(status.code()))
}
@noreturn
func exit(error:NSError) {
    print(error.localizedDescription)
    exit(Int32(error.code))
}