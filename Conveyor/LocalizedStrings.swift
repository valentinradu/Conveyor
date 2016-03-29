//
//  LocalizedStrings.swift
//  Conveyor
//
//  Created by Valentin Radu on 22/03/16.
//  Copyright © 2016 Valentin Radu. All rights reserved.
//

import Foundation

struct LocalizedStrings:Action {
    private(set) var commands:[String:(Action, String)]?
    private(set) var options:[String:(Int, (args:[String]) throws -> String, String)]?
    
    private let project:Project
    
    init() throws {
        project = try Project()
        commands = nil
        options = [
            "-h":(0, {args in return self.description}, "Show this help page"),
            "-sf-dr": (0, sfdr, "Makes a replace dry run on the source files, indicating any issues and showing all the valid strings found."),
            "-r-sf-ex":(0, rsfex, "Replace NSLocalizedStrings in source files and put them into a String extension (String+Localized.swift)."),
            "-sf-st":(0, sfst, "Get NSLocalizedStrings from source files into strings files based on Xcode localization settings (e.g. en/Strings.strings)."),
            "-ex-st":(0, exst, "Get strings from the extension (String+Localized.swift) into strings files based on Xcode localization settings (e.g. en/Strings.strings)."),
            "-st-csv":(0, stcsv, "Get strings from the strings files into a CSV file (Strings.csv)."),
            "-csv-st":(0, csvst, "Get strings from the CSV file into the strings files.")
        ]
    }
    
    func sfdr(args:[String]) throws -> String {
        let result = try project.replaceInObjects(LocalizedStringsReplaceInSource(), dryRun:true)
        
        var arr = [String]()
        
        result.forEach {
            r in
            if let path = r.path.lastPathComponent {
                arr.append(path)
            }
            arr.append(r.replacements.map({key, value in return "\(key) -> \(value)"}).joinWithSeparator("\r\n"))
        }
        
        return arr.joinWithSeparator("\r\n")
    }
    
    func rsfex(args:[String]) throws -> String {
        let result = Dictionary(try project.replaceInObjects(LocalizedStringsReplaceInSource(), dryRun:false).flatMap{$0.replacements})
        try putResultsToExtensionFile(result)
        return result.count > 0 ? "\(result.count) strings extracted to String+Localized.swift." : "No strings found."
    }
    func sfst(args:[String]) throws -> String {
        let result = Dictionary(try project.replaceInObjects(LocalizedStringsReplaceInSource(), dryRun:true).flatMap{$0.replacements})
        let filemanager = NSFileManager.defaultManager()
        let languages = try filemanager.localizedStringsUrls().filter({extractLanguageFromURL($0)?.lowercaseString != "base"}).flatMap{extractLanguageFromURL($0)}
        try putResultsToStringsFiles(Dictionary(languages.map{($0, result)}))
        return result.count > 0 ? "\(result.count) strings found" : "No strings found."
    }
    func exst(args:[String]) throws -> String {
        let filemanager = NSFileManager.defaultManager()
        let extensionFile = try NSFileHandle(forUpdatingURL: try filemanager.localizedStringsExtensionUrl())
        let result = try extensionFile.extract(LocalizedStringsExtractFromExtension())
        let languages = try filemanager.localizedStringsUrls().filter({extractLanguageFromURL($0)?.lowercaseString != "base"}).flatMap{extractLanguageFromURL($0)}
        try putResultsToStringsFiles(Dictionary(languages.map{($0, result)}))
        return result.count > 0 ? "\(result.count) strings put into the string files." : "No strings found in extension."
    }
    func stcsv(args:[String]) throws -> String {
        let filemanager = NSFileManager.defaultManager()
        let languagesUrls = try filemanager.localizedStringsUrls().filter{extractLanguageFromURL($0)?.lowercaseString != "base"}
        
        var dic = [String:[String:String]]()
        try languagesUrls.forEach {
            url in
            guard let language = extractLanguageFromURL(url) else {return}
            let languageFile = try NSFileHandle(forUpdatingURL: url)
            let result = try languageFile.extract(LocalizedStringsExtractFromStringsFile())
            
            for (key, value) in result {
                if dic[key] == nil {
                    dic[key] = [language:value]
                }
                else {
                    dic[key]![language] = value
                }
            }
            languageFile.closeFile()
        }
        try putResultsToCSVFile(dic)
        return dic.keys.count > 0 ? "\(dic.keys.count) strings put to CSV (Strings.csv)." : "No strings found."
    }
    func csvst(args:[String]) throws -> String {
        let filemanager = NSFileManager.defaultManager()
        let csvFile = try NSFileHandle(forUpdatingURL: try filemanager.localizedStringsCSVUrl())
        let result = try csvFile.extract(LocalizedStringsExtractFromCSV())
        try putResultsToStringsFiles(result)
        return result.count > 0 ? "\(result.count) strings put into the string files." : "No strings found."
    }
    
    func putResultsToExtensionFile(result:[String:String]) throws {
        let filemanager = NSFileManager.defaultManager()
        try filemanager.createFileAtUrlIfNeeded(filemanager.localizedStringsExtensionUrl(), contents: nil, attributes: nil)
        let extensionFile = try NSFileHandle(forUpdatingURL: try filemanager.localizedStringsExtensionUrl())
        try extensionFile.injectUnique(
            result,
            extractRule: LocalizedStringsExtractFromExtension(),
            injectRule: LocalizedStringsInjectInExtension()
        )
        extensionFile.closeFile()
    }
    
    func putResultsToStringsFiles(result:[String:[String:String]]) throws {
        let filemanager = NSFileManager.defaultManager()
        let languagesUrls = try filemanager.localizedStringsUrls().filter{extractLanguageFromURL($0)?.lowercaseString != "base"}
        for url in languagesUrls {
            guard let name = extractLanguageFromURL(url) else {continue}
            guard let dic = result[name] else {continue}
            try filemanager.createFileAtUrlIfNeeded(url, contents: nil, attributes: nil)
            let stringFile = try NSFileHandle(forUpdatingURL: url)
            try stringFile.injectUnique(
                dic,
                extractRule: LocalizedStringsExtractFromStringsFile(),
                injectRule: LocalizedStringsInjectInStringsFile()
            )
            stringFile.closeFile()
        }
    }
    
    func putResultsToCSVFile(result:[String:[String:String]]) throws {
        let filemanager = NSFileManager.defaultManager()
        try filemanager.createFileAtUrlIfNeeded(filemanager.localizedStringsCSVUrl(), contents: nil, attributes: nil)
        let CSVFile = try NSFileHandle(forUpdatingURL: try filemanager.localizedStringsCSVUrl())
        try CSVFile.injectUnique(
            result,
            extractRule: LocalizedStringsExtractFromCSV(),
            injectRule: LocalizedStringsInjectInCSV()
        )
        CSVFile.closeFile()
    }
    
    func extractLanguageFromURL(url:NSURL) -> String? {
        return url.URLByDeletingLastPathComponent?.pathComponents?.last?.componentsSeparatedByString(".").first
    }
}

struct LocalizedStringsExtractFromStringsFile:ExtractRule {
    typealias RawType = String
    typealias CanonicType = [String:String]
    func run(string:String) throws -> [String:String] {
        return string.propertyListFromStringsFileFormat()
    }
}

struct LocalizedStringsInjectInStringsFile:InjectRule {
    typealias RawType = String
    typealias CanonicType = [String:String]
    func run(p:[String:String]) throws -> String {
        return (p as NSDictionary).descriptionInStringsFileFormat
    }
}

struct LocalizedStringsExtractFromCSV:ExtractRule {
    typealias RawType = String
    typealias CanonicType = [String:[String:String]]
    func run(string:String) throws -> [String:[String:String]] {
        
        let characterSet = NSMutableCharacterSet.newlineCharacterSet()
        characterSet.formUnionWithCharacterSet(NSCharacterSet(charactersInString: "\";"))
        let scanner = NSScanner(string: string)
        scanner.caseSensitive = false
        scanner.charactersToBeSkipped = NSMutableCharacterSet.whitespaceCharacterSet()
        
        var isLiteral = false
        var arr = [[String]]()
        var stringAccumulator = ""
        while !scanner.atEnd {
            var partialString:NSString?
            if (scanner.scanUpToCharactersFromSet(characterSet, intoString: &partialString)) {
                guard let partialString = partialString as? String else {assertionFailure();continue}
                stringAccumulator.appendContentsOf(partialString)
            }
            
            
            if (scanner.scanCharactersFromSet(characterSet, intoString: &partialString)) {
                guard let partialString = partialString as? String else {assertionFailure();continue}
                for (i, separator) in partialString.characters.enumerate() {
                    switch separator {
                    case ";":
                        if !isLiteral {
                            if arr.last == nil {arr.append([String]())}
                            
                            if stringAccumulator.hasPrefix("\"") {
                                stringAccumulator.removeAtIndex(stringAccumulator.startIndex)
                            }
                            if stringAccumulator.hasSuffix("\"") {
                                stringAccumulator.removeAtIndex(stringAccumulator.endIndex.predecessor())
                            }
                            
                            arr[arr.count - 1].append(stringAccumulator)
                            stringAccumulator = ""
                        }
                        else {
                            stringAccumulator.append(separator)
                        }
                    case "\"":
                        if i > 0 {
                            let prev = partialString.characters[partialString.startIndex.advancedBy(i-1)]
                            if prev == "\\" || prev == "\"" {
                                stringAccumulator.append(separator)
                                break
                            }
                        }
                        
                        if i < partialString.characters.count - 1 {
                            let next = partialString.characters[partialString.startIndex.advancedBy(i+1)]
                            if next == "\"" {
                                stringAccumulator.append(separator)
                                break
                            }
                        }
                        
                        if !isLiteral {
                            isLiteral = true
                            stringAccumulator.append(separator)
                        }
                        else {
                            isLiteral = false
                            stringAccumulator.append(separator)
                        }
                    case _ where String(separator).rangeOfCharacterFromSet(NSMutableCharacterSet.newlineCharacterSet()) != nil:
                        if !isLiteral {
                            if arr.last == nil {arr.append([String]())}
                            
                            if stringAccumulator.hasPrefix("\"") {
                                stringAccumulator.removeAtIndex(stringAccumulator.startIndex)
                            }
                            if stringAccumulator.hasSuffix("\"") {
                                stringAccumulator.removeAtIndex(stringAccumulator.endIndex.predecessor())
                            }
                            
                            arr[arr.count - 1].append(stringAccumulator)
                            stringAccumulator = ""
                            arr.append([String]())
                        }
                        else {
                            stringAccumulator.append(separator)
                        }
                    default:
                        assertionFailure()
                        break
                    }
                }
            }
        }
        
        guard arr.count > 1 else {return [:]}
        guard let header = arr.first else {throw Error.invalidData}
        guard header.count > 1 else {throw Error.invalidData}
        arr = Array(arr.dropFirst())
        let languages = header.dropFirst()
        
        let pairs = Dictionary(arr.flatMap{
            (row:[String]) -> (String, [String:String])? in
            guard row.count == header.count else {return nil}
            let key = row[0]
            let p = Dictionary(zip(languages, row.dropFirst()))
            return (key,p)
        })
        return pairs
    }
}

struct LocalizedStringsInjectInCSV:InjectRule {
    typealias RawType = String
    typealias CanonicType = [String:[String:String]]
    func run(p:[String:[String:String]]) throws -> String {
        var orderedMap = p.map{($0.0, $0.1.map{$0}.sort{$0.0 < $0.1})}
        orderedMap = orderedMap.sort{$0.0.0 < $0.1.0}
        let result = orderedMap.flatMap {
            s in
            guard s.0.characters.count > 0 else {return nil}
            return String(format:TemplateLocalizedStringsCSVItem, "\"\(s.0)\"", s.1.map{"\"\($0.1)\""}.joinWithSeparator(";") ?? "")
            }.joinWithSeparator("\r\n")
        return String(format:TemplateLocalizedStringsCSV, orderedMap.first?.1.map{"\"\($0.0)\""}.joinWithSeparator(";") ?? "", result)
    }
}

struct LocalizedStringsReplaceInSource:SearchParam, ReplaceParam {
    func objectFilter(value:[String:AnyObject]) -> Bool {
        guard let path = value["path"] as? String where path != "String+Localized.swift" else {return false}
        return true
    }
    func sanitizeRegex() -> String {
        return "NSLocalizedString\\s*\\(\\s*((\"(?=.*?\\\\\\())|(?!\")).*?\\)"
    }
    func findRegex() -> String {
        return "NSLocalizedString\\s*\\(\\s*\"(\\w*)\".*?\\)"
    }
    func replaceRegex() -> String {
        return "$1"
    }
    func forwardTransform(s:String) -> String {
        return "String.localized.\(s.camelCaseString)"
    }
    func backwardTransform(s:String) -> String {
        return s.stringByReplacingCharactersInRange(s.rangeOfString("String.localized.")!, withString: "")
    }
}

struct LocalizedStringsExtractFromExtension:ExtractRule {
    typealias RawType = String
    typealias CanonicType = [String:String]
    func run(string:String) throws -> [String:String] {
        let regex = "let (.+?) = NSLocalizedString\\(\"(.+?)\",.*?\\)"
        let r = try NSRegularExpression(pattern: regex, options: [])
        let searchResults = r.matchesInString(string, options: .ReportCompletion, range: NSRange(location: 0, length: string.characters.count))
        return Dictionary(searchResults.map{
            (r:NSTextCheckingResult) -> (String, String) in
            return (string.substringWithRange(r.rangeAtIndex(1)), string.substringWithRange(r.rangeAtIndex(2)))
            })
    }
}

struct LocalizedStringsInjectInExtension: InjectRule {
    typealias RawType = String
    typealias CanonicType = [String:String]
    func run(p:[String:String]) throws -> String {
        let r = p.flatMap {
            s in
            guard s.0.characters.count > 0 else {return nil}
            return String(format:TemplateLocalizedStringsExtensionItem, s.0, s.1)
        }.joinWithSeparator("\n")
        
        return String(format:TemplateLocalizedStringsExtension, r)
    }
}