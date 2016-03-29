//
//  main.swift
//  Conveyor
//
//  Created by Valentin Radu on 11/03/16.
//  Copyright © 2016 Valentin Radu. All rights reserved.
//
import Foundation

do {
    
    let arguments = NSProcessInfo.processInfo().arguments
    let project = try Project()
    
    guard arguments.count > 1 else {throw Error.noArguments}
    guard [Array(project.commands!.keys), Array(project.options!.keys)].flatMap({$0}).contains(arguments[1]) else {throw Error.invalidArgument(arg: arguments[1])}
    
    if let command = project.commands?[arguments[1]] {
        guard arguments.count > 2 else {throw Error.wrongArgumentsCount(arg: arguments[1], given: arguments.count - 2, expected: 1)}
        guard command.0.options!.keys.contains(arguments[2]) else {throw Error.invalidArgument(arg: arguments[2])}
        
        let option = command.0.options![arguments[2]]!
        guard arguments.count - 3 == option.0 else {throw Error.wrongArgumentsCount(arg: arguments[2], given: arguments.count - 3, expected: option.0)}
        print(try option.1(args: Array(arguments[3..<arguments.count])))
    }
    else if let option = project.options?[arguments[1]] {
        guard arguments.count - 2 == option.0 else {throw Error.wrongArgumentsCount(arg: arguments[1], given: arguments.count - 2, expected: option.0)}
        print(try option.1(args: Array(arguments[2..<arguments.count])))
    }
    else {
        assertionFailure()//should never get here because of the guard above
    }
//
//    
//    /* Inject NSLocalizedStrings to String files */
//    let languagesFiles = Dictionary(try languagesUrls.enumerate().map{
//        (i:Int, value:NSURL) -> (String, NSFileHandle) in
//        try filemanager.createFileAtUrlIfNeeded(value, contents: nil, attributes: nil)
//        return (languages[i], try NSFileHandle(forUpdatingURL: value))
//    })
//    let localizedStringsAllLanguagesResult = try localizedStringsCSVFile.extract(LocalizedStringsExtractFromCSV())
//    
//    var languageMap = [String:[String:String]]()
//    localizedStringsAllLanguagesResult.forEach {
//        key, value in
//        for (k, v) in value {
//            if languageMap[k] == nil {languageMap[k] = [String:String]()}
//            languageMap[k]?[key] = v
//        }
//    }
//    
//    try languagesFiles.forEach {
//        key, value in
//        try value.inject(languageMap[key]!, rule: LocalizedStringsInjectInStringsFile())
//    }
//    
//    languagesFiles.forEach{$0.1.closeFile()}
//    localizedStringsCSVFile.closeFile()
    
}
catch let e as Error {
    exit(e)
}





