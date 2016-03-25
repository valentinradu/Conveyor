//
//  main.swift
//  Conveyor
//
//  Created by Valentin Radu on 11/03/16.
//  Copyright © 2016 Valentin Radu. All rights reserved.
//
import Foundation

do {
    let filemanager = NSFileManager.defaultManager()
    let project = try Project()
    
    /* Replace NSLocalizedStrings */
    var localizedStringsResult = Dictionary(try project.replaceInObjects(LocalizedStringsReplaceInSource()).flatMap{$0.replacements})
    
    /* Inject NSLocalizedStrings to extension */
    try filemanager.createFileAtUrlIfNeeded(filemanager.localizedStringsExtensionUrl(), contents: nil, attributes: nil)
    let localizedStringsExtensionFile = try NSFileHandle(forUpdatingURL: try filemanager.localizedStringsExtensionUrl())
    try localizedStringsExtensionFile.injectUnique(
        localizedStringsResult,
        extractRule: LocalizedStringsExtractFromExtension(),
        injectRule: LocalizedStringsInjectInExtension()
    )
    
//    /* Inject NSLocalizedStrings to CSV */
//    if localizedStringsResult.count == 0 {
//        localizedStringsResult = try localizedStringsExtensionFile.extract(LocalizedStringsExtractFromExtension())
//    }
//    
//    let nameExtract = {
//        (url:NSURL) -> String? in
//        return url.URLByDeletingLastPathComponent?.pathComponents?.last?.componentsSeparatedByString(".").first
//    }
//    let languagesUrls = try filemanager.localizedStringsUrls().filter{nameExtract($0)?.lowercaseString != "base"}
//    let languages = languagesUrls.flatMap{nameExtract($0)}
//    
//    let localizedStringsAllLang = Dictionary(localizedStringsResult.map{
//        _, value in
//        return (value, Dictionary(languages.map{($0, "")}))
//    })
//    try filemanager.createFileAtUrlIfNeeded(filemanager.localizedStringsCSVUrl(), contents: nil, attributes: nil)
//    let localizedStringsCSVFile = try NSFileHandle(forUpdatingURL: try filemanager.localizedStringsCSVUrl())
//    try localizedStringsCSVFile.injectUnique(
//        localizedStringsAllLang,
//        extractRule: LocalizedStringsExtractFromCSV(),
//        injectRule: LocalizedStringsInjectInCSV()
//    )
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
    localizedStringsExtensionFile.closeFile()
//    localizedStringsCSVFile.closeFile()
    
}
catch let e as Error {
    exit(e)
}





