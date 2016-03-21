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
    case cantOpenFile(file:String)
    case notAStringLiteral(data:[(String, String, Int)])
    case patternNotFound(file:String)
    var description: String {
        switch self {
        case .success(let arg) : return "\(NSLocalizedString("success", comment: "")), \(arg)"
        case .urlNotFound(let arg)  : return "\(NSLocalizedString("urlNotFound", comment: "")) \(arg)"
        case .xcodeProjNotFound(let arg)  : return "\(NSLocalizedString("xcodeProjNotFound", comment: "")) \(arg)"
        case .xcodePbxprojNotFound(let arg)  : return "\(NSLocalizedString("xcodePbxprojNotFound", comment: "")) \(arg)"
        case .xcodePbxprojCantOpen(let arg)  : return "\(NSLocalizedString("xcodePbxprojCantOpen", comment: "")) \(arg)"
        case .xcodePbxprojUnsupportedFormat(let arg)  : return "\(NSLocalizedString("xcodePbxprojUnsupportedFormat", comment: "")) \(arg)"
        case .cantOpenFile(let file)  : return "\(NSLocalizedString("cantOpenFile", comment: "")) \(file)"
        case .xcodeProjIsNotLocalized(let arg)  : return "\(NSLocalizedString("xcodeProjIsNotLocalized", comment: "")) \(arg)"
        case .notAStringLiteral(let data) : return "\(NSLocalizedString("notAStringLiteral", comment: "")) \n\(data.map{"\($0.0), \($0.1), \($0.2)"}.joinWithSeparator(", \n"))"
        case .patternNotFound(let file) : return "\(NSLocalizedString("patternNotFound", comment: "")), \(file)"
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
        case .notAStringLiteral : return 109
        case .patternNotFound : return 110
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