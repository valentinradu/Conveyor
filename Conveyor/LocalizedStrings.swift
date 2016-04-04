//
//  LocalizedStrings.swift
//  Conveyor
//
//  Created by Valentin Radu on 22/03/16.
//  Copyright © 2016 Valentin Radu. All rights reserved.
//

import Foundation

class LocalizedStrings:ActionContext {
    var command:String?
    var options:[(String, [String])]?
    var otherArgs:[String]?
    var availableCommands:[String:(protocol<Action,Context>, String)]?
    var availableOptions:[String:OptionDescription]?
    var project:Project
    var forceful = false
    var testFirst = false
    
    init(project p:Project) throws {
        project = p
        availableCommands = nil
        availableOptions = [
            "-h":OptionDescription(runable: {_ in return self.description}, description: "Show this help page", priority: 0),
            "-t":OptionDescription(runable: {[weak self] _ in try self?.checkTest(); return nil}, description: "First makes a search on the source files, indicating any issues and showing all the valid strings found.", priority: 1),
            "-f":OptionDescription(runable: {_ in self.forceful = true; return nil}, description: "Overwrite the strings already present in the target file.", priority: 2),
            "-r-sf-ex":OptionDescription(runable: rsfex, description: "Replace NSLocalizedStrings in source files and put them into a String extension (String+Localized.swift).", priority: 3),
            "-sf-st":OptionDescription(runable: sfst, description: "Get NSLocalizedStrings from source files into strings files based on Xcode localization settings (e.g. en/Strings.strings).", priority: 3, paramCount: 0...1024),
            "-ex-st":OptionDescription(runable: exst, description: "Get strings from the extension (String+Localized.swift) into strings files based on Xcode localization settings (e.g. en/Strings.strings).", priority: 3),
            "-st-csv":OptionDescription(runable: stcsv, description: "Get strings from the strings files into a CSV file (Strings.csv).", priority: 3),
            "-csv-st":OptionDescription(runable: csvst, description: "Get strings from the CSV file into the strings files.", priority: 3)
        ]
    }
    func test(param:ReplaceParam) throws {
        let result = try project.replaceInObjects(param, dryRun:true)
        
        var arr = [String]()
        
        result.forEach {
            r in
            if let path = r.path.lastPathComponent {
                arr.append("")
                arr.append(path)
            }
            arr.append(r.replacements.map({key, value in return "\(value) -> \(key)"}).joinWithSeparator("\r\n"))
        }
        
        try testAsk(arr)
    }
    func test(result:[String:[String:String]]) throws {
        let arr = result.flatMap{[$0.0] + $0.1.flatMap{[$0.0, $0.1] + ["\n"]}}
        try testAsk(arr)
    }
    func test(result:[String:String]) throws {
        let arr = result.flatMap{[$0.0, $0.1]}
        try testAsk(arr)
    }
    func testAsk(results:[String]) throws {
        if results.count > 0 {
            print(results.joinWithSeparator("\r\n"))
            print("Would you like to move forward and apply the rest of the operations [Y/n]")
            
            var response:String?
            while response != "Y" && response != "n" {
                response = readLine(stripNewline: true)
                if response != "Y" && response != "n" {
                    print("Invalid answer. Please try again.")
                }
            }
            
            if response != "Y" {
                throw Error.interrupt
            }
        }
        else {
            throw Error.noTokensFound
        }
    }
    func rsfex(args:[String]) throws -> String {
        let param = LocalizedStringsReplaceInSource()
        if self.testFirst {try test(param)}
        let result = Dictionary(try project.replaceInObjects(param, dryRun:false).flatMap{$0.replacements})
        try putResultsToExtensionFile(result)
        return result.count > 0 ? "\(result.count) unique tokens injected into String+Localized.swift." : "No tokens found."
    }
    func sfst(args:[String]) throws -> String {
        let filemanager = NSFileManager.defaultManager()
        let r = try NSRegularExpression(pattern: "^[a-z]{2,3}(?:-[A-Z]{2,3}(?:-[a-zA-Z]{4})?)?$", options: [])
        for arg in args {
            do {
                guard r.numberOfMatchesInString(arg, options: .ReportCompletion, range: NSRange(location: 0, length: arg.characters.count)) != 0 else {throw Error.notACountryCode(code: arg)}
                let url = try languageURLFromName(arg)
                try filemanager.createDirectoryAtURL(url, withIntermediateDirectories: true, attributes: nil)
            }
            catch let e as Error {
                print(e)
            }
            catch let e as NSError {
                print(e)
            }
        }
        let param = LocalizedStringsReplaceInSource()
        if self.testFirst {try test(param)}
        let result = Dictionary(try project.replaceInObjects(param, dryRun:true).flatMap{$0.replacements})
        let languages = try filemanager.localizedStringsUrls().filter({extractLanguageFromURL($0)?.lowercaseString != "base"}).flatMap{extractLanguageFromURL($0)}
        try putResultsToStringsFiles(Dictionary(languages.map{($0, Dictionary(result.map{($0.1, "")}))}))
        return result.count > 0 ? "\(result.count) unique tokens injected into the strings files" : "No tokens found."
    }
    func exst(args:[String]) throws -> String {
        let filemanager = NSFileManager.defaultManager()
        let extensionFile = try NSFileHandle(forUpdatingURL: try filemanager.localizedStringsExtensionUrl())
        let param = LocalizedStringsExtractFromExtension()
        let result = try extensionFile.extract(param)
        if self.testFirst {try test(result)}
        let languages = try filemanager.localizedStringsUrls().filter({extractLanguageFromURL($0)?.lowercaseString != "base"}).flatMap{extractLanguageFromURL($0)}
        try putResultsToStringsFiles(Dictionary(languages.map{($0, Dictionary(result.map{($0.1, "")}))}))
        return result.count > 0 ? "\(result.count) unique tokens injected into the string files." : "No tokens found in extension."
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
        if self.testFirst {try test(dic)}
        try putResultsToCSVFile(dic)
        return dic.keys.count > 0 ? "\(dic.keys.count) unique tokens injected into CSV (Strings.csv)." : "No tokens found."
    }
    func csvst(args:[String]) throws -> String {
        let filemanager = NSFileManager.defaultManager()
        let url = try filemanager.localizedStringsCSVUrl()
        let csvFile = try NSFileHandle(forUpdatingURL: url)
        let result = try csvFile.extract(LocalizedStringsExtractFromCSV())
        if self.testFirst {try test(result)}
        
        var dic = [String:[String:String]]()
        result.forEach {
            item in
            item.1.forEach {
                pair in
                if dic[pair.0] == nil {dic[pair.0] = [String:String]()}
                dic[pair.0]![item.0] = pair.1
            }
        }
        
        try putResultsToStringsFiles(dic)
        return result.count > 0 ? "\(result.count) tokens injected into the string files." : "No tokens found."
    }
    
    func putResultsToExtensionFile(result:[String:String]) throws {
        let filemanager = NSFileManager.defaultManager()
        try filemanager.createFileAtUrlIfNeeded(filemanager.localizedStringsExtensionUrl(), contents: nil, attributes: nil)
        let extensionFile = try NSFileHandle(forUpdatingURL: try filemanager.localizedStringsExtensionUrl())
        try extensionFile.injectUnique(
            self.forceful,
            pairs: result,
            extractRule: LocalizedStringsExtractFromExtension(),
            injectRule: LocalizedStringsInjectInExtension()
        )
        extensionFile.closeFile()
    }
    
    func putResultsToStringsFiles(result:[String:[String:String]]) throws {
        let filemanager = NSFileManager.defaultManager()
        let languagesUrls = try filemanager.localizedStringsUrls().filter{extractLanguageFromURL($0)?.lowercaseString != "base"}
        if languagesUrls.count == 0 {throw Error.xcodeProjIsNotLocalized}
        
        for url in languagesUrls {
            try filemanager.createFileAtUrlIfNeeded(url, contents: nil, attributes: nil)
            guard let name = extractLanguageFromURL(url) else {continue}
            guard let dic = result[name] else {continue}
            try filemanager.createFileAtUrlIfNeeded(url, contents: nil, attributes: nil)
            let stringFile = try NSFileHandle(forUpdatingURL: url)
            try stringFile.injectUnique(
                self.forceful,
                pairs: dic,
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
            self.forceful,
            pairs:result,
            extractRule: LocalizedStringsExtractFromCSV(),
            injectRule: LocalizedStringsInjectInCSV()
        )
        CSVFile.closeFile()
    }
    
    func extractLanguageFromURL(url:NSURL) -> String? {
        return url.URLByDeletingLastPathComponent?.pathComponents?.last?.componentsSeparatedByString(".").first
    }
    
    func languageURLFromName(name:String) throws -> NSURL {
        let fileManager = NSFileManager.defaultManager()
        let srcRoot = try fileManager.srcRoot()
        return srcRoot.URLByAppendingPathComponent("\(name).lproj")
    }
    
    func run() throws -> String? {
        guard command == nil else {throw Error.invalidArgument(arg: command!)}
        var iterator = options?.enumerate().generate()
        var arr = [String]()
        while let item = iterator?.next() {
            guard let option = availableOptions?[item.element.0] else {throw Error.invalidArgument(arg: item.element.0)}
            if let s = try option.runable(item.element.1) {
                arr.append(s)
            }
        }
        
        return arr.nullify()?.joinWithSeparator("\n")
    }
}

struct LocalizedStringsExtractFromStringsFile:ExtractRule {
    typealias RawType = String
    typealias CanonicType = [String:String]
    func run(string:String) throws -> [String:String] {
        guard string.characters.count > 0 else {return [:]}
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
        let regex = "let (.+?) = NSBundle\\.mainBundle\\(\\)\\.localizedStringForKey\\(\"(.+?)\",.*?\\)"
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