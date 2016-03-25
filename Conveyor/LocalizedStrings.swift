//
//  LocalizedStrings.swift
//  Conveyor
//
//  Created by Valentin Radu on 22/03/16.
//  Copyright © 2016 Valentin Radu. All rights reserved.
//

import Foundation

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
            }.joinWithSeparator("\n")
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