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
    case cantCreateFile
    case failedSanitization(file:String, string:[(String, Int)])
    case patternNotFound
    case invalidFile
    case invalidData
    case invalidArgument(arg:String)
    case noArguments
    case wrongArgumentsCount(arg:String, given:Int, expected:Int)
    var description: String {
        switch self {
        case .success: return "Success"
        case .urlNotFound: return "Could not find resource at url."
        case .xcodeProjNotFound: return "Xcode project not found. Run this tool in a directory that contains a valid Xcode project."
        case .xcodePbxprojNotFound: return "Pbxproj not found. Check if the Xcode project contains one."
        case .xcodePbxprojCantOpen: return "Can't open Pbxproj."
        case .xcodePbxprojUnsupportedFormat  : return "It seems that the format used by Pbxproj is not supported."
        case .cantOpenFile: return "Can't open file at url."
        case .cantCreateFile: return "Can't create file at url"
        case .xcodeProjIsNotLocalized: return "It the Xcode project is not localized. You first need to add the supported localizations."
        case .failedSanitization(let file, let pairs): return "\(pairs.count) strings in \(file) failed sanitization:\r\n\(pairs.map{"\($0.0) on line \($0.1)"}.joinWithSeparator("\r\n"))"
        case .patternNotFound: return "Pattern not found."
        case .invalidFile: return "The file seems to be not quite we expected."
        case .invalidData: return "The data seems to be not quite we expected."
        case .invalidArgument(let arg): return "\(arg) is not a valid option or command. Try conveyor -h or conveyor command -h (e.g. conveyor locs -h)"
        case .noArguments: return "No arguments given. Try conveyor -h or conveyor command -h (e.g. conveyor locs -h)"
        case .wrongArgumentsCount(let arg, let given, let expected): return "Wrong arguments count for \(arg). Expected \(expected). Given \(given)"
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
        case .cantCreateFile : return 113
        case .invalidArgument : return 114
        case .noArguments : return 115
        case .wrongArgumentsCount : return 116
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