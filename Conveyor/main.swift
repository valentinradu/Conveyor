//
//  main.swift
//  Conveyor
//
//  Created by Valentin Radu on 11/03/16.
//  Copyright © 2016 Valentin Radu. All rights reserved.
//

/*Dependencies
*/

import Foundation

let supportedFileTypes = ["sourcecode.swift", "sourcecode.cpp.cpp", "sourcecode.c.objc", "sourcecode.c.c", "sourcecode.cpp.objcpp", "sourcecode.c.h", "sourcecode.cpp.h", "sourcecode.objj.h"]
let camelCase = {
    (string:String) -> String in
    let set = NSCharacterSet(charactersInString: "-_.")
    return string.componentsSeparatedByCharactersInSet(set).enumerate().map({$0.0 == 0 ? $0.1.lowercaseString : $0.1.lowercaseString.capitalizedString}).joinWithSeparator("") as String
}

//Localized strings
let localizedStringWrapper = {
    (strings:() -> [String]) in
    return ["//This file was automatically generated with Conveyor Resource Manager. Manually modifying it is probably a bad idea.",
            "import Foundation",
            "struct LocalizedStrings {",
                strings().joinWithSeparator("\n"),
            "}",
            "extension String {",
                "static var localized:LocalizedStrings {",
                    "return LocalizedStrings()",
                "}",
            "}"].joinWithSeparator("\n")
}
let localizedStringFindRegex = "NSLocalizedString\\s*\\(\\s*\"(\\w*)\".*?\\)"
let localizedStringSanitize = "NSLocalizedString\\s*\\(\\s*((\"(?=.*?\\\\\\())|(?!\")).*?\\)"
let localizedStringReplaceRegex = "$1"
let localizedStringObjectFilter = {
    (value:[String:AnyObject]) -> Bool in
    
    guard let isa = value["isa"] as? String, let explicitType = value["explicitFileType"] as? String?, let lastKnownType = value["lastKnownFileType"] as? String? else {return false}
    guard isa == "PBXFileReference" && (supportedFileTypes.contains(explicitType ?? "") || supportedFileTypes.contains(lastKnownType ?? "")) else {return false}
    
    return true
}
let localizedStringForwardTransform = {
    (s:String) in
    return "String.localized.\(camelCase(s))"
}
let localizedStringBackwardTransform = {
    (s:String) in
    return s.stringByReplacingCharactersInRange(s.rangeOfString("String.localized.")!, withString: "")
}
let localizedExtensionExtract = {
    (string:String) throws -> [String:String] in
    let regex = "let (.+?) = NSLocalizedString\\(\"(.+?)\",.*?\\)"
    let r = try NSRegularExpression(pattern: regex, options: [])
    let searchResults = r.matchesInString(string, options: .ReportCompletion, range: NSRange(location: 0, length: string.characters.count))
    return Dictionary(searchResults.map{
        (r:NSTextCheckingResult) -> (String, String) in
        return (string.substringWithRange(r.rangeAtIndex(1)), string.substringWithRange(r.rangeAtIndex(2)))
    })
}
let localizedExtensionInject = {
    (p:[String:String]) throws -> String in
    
    p.map{k, v in return ()}
    let result = localizedStringWrapper {
        return zip(values, keys).flatMap {
            s in
            guard s.0.characters.count > 0 else {return nil}
            return "let \(s.0) = NSLocalizedString(\"\(s.1)\", comment: \"\")"
        }
    }
    
    return result
}

func sanitize(filename:String, regex:String, string:String) throws {
    let r = try NSRegularExpression(pattern: regex, options: [])
    let results = r.matchesInString(string, options: .ReportCompletion, range: NSRange(location: 0, length: string.characters.count))
    
    let t = results.map {
        (result:NSTextCheckingResult) -> (String, String, Int) in
        
        let range = result.rangeAtIndex(0)
        var lineRange = string.lineRangeForRange(range)
        var count = 1
        while string.startIndex != lineRange.startIndex {
            lineRange = string.lineRangeForRange(lineRange.startIndex.advancedBy(-1)..<lineRange.startIndex)
            count++
        }
        
        return (string.substringWithRange(range), filename, count)
    }
    
    guard t.count == 0 else {throw Error.notAStringLiteral(data: t)}
}

func replace(filename:String, findRegex:String, replaceRegex:String, transform:String->String, string:String) throws -> (result:String, pairs:[String:String]) {
    var string = string
    let r = try NSRegularExpression(pattern: findRegex, options: [])
    let results = r.matchesInString(string, options: .ReportCompletion, range: NSRange(location: 0, length: string.characters.count))
    guard results.count > 0 else {throw Error.patternNotFound(file: filename)}
    
    var offset = 0
    var replacements = [String:String]()
    for result in results {
        var range = result.range
        range.location += offset
        let match = r.replacementStringForResult(result, inString: string, offset: offset, template: replaceRegex)
        let replacement = "\(transform(match))"
        let start = string.startIndex.advancedBy(range.location)
        let end = string.startIndex.advancedBy(range.location + range.length)
        string.replaceRange(start..<end, with: replacement)
        offset += replacement.characters.count - range.length
        replacements[match] = replacement
    }
    return (string, replacements)
}

func listProjectObjects() throws -> [String:AnyObject] {
    let fileManager = NSFileManager.defaultManager()
    guard let projPbxData = NSData(contentsOfURL: try fileManager.pbxProjectFileUrl()) else {throw Error.xcodePbxprojCantOpen}
    guard let projPbx = try NSPropertyListSerialization.propertyListWithData(projPbxData, options: NSPropertyListMutabilityOptions.Immutable, format: nil) as? [String:AnyObject] else {throw Error.xcodePbxprojUnsupportedFormat}
    guard let objects = projPbx["objects"] as? [String:AnyObject] else {throw Error.xcodePbxprojUnsupportedFormat}
    return objects
}

func replaceInProjectObjects(filter:[String:AnyObject] -> Bool,
                             sanitizeRegex:String,
                             findRegex:String,
                             replaceRegex:String,
                             forwardTransform:String->String,
                             backwardTransform:String->String) throws -> [(path:NSURL, replacements:[String:String])] {
    let group = dispatch_group_create()
    let serialQueue = dispatch_queue_create("Serial", DISPATCH_QUEUE_SERIAL)
    let objects = try listProjectObjects()
    
    var result = [(path:NSURL, replacements:[String:String])]()
    
    for (_, value) in objects {
        guard let value = value as? [String:AnyObject] else {continue}
        guard filter(value) else {continue}
        guard let path = value["path"] as? String else {continue}
        let fileManager = NSFileManager.defaultManager()
        let url = NSURL(fileURLWithPath: path, relativeToURL: try fileManager.srcRoot())
        
        
        dispatch_group_async(group, dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
            
            do {
                try fileManager.openStringFileAtURL(url, createIfNeeded: false, append: false) {
                    string in
                    do {
                        try sanitize(url.lastPathComponent!, regex: sanitizeRegex, string:string)
                    }
                    catch let e as Error {
                        print(e)
                    }
                    let r = try replace(url.lastPathComponent!,
                        findRegex:findRegex,
                        replaceRegex: replaceRegex,
                        transform: forwardTransform,
                        string:string)
                    
                    dispatch_group_async(group, serialQueue) {
                        let r = (url, Dictionary(r.pairs.map{($0.0, backwardTransform($0.1))}))
                        result.append(r)
                    }
                    
                    return r.result
                }
            }
            catch let e as CustomStringConvertible {
                print(e)
            }
            catch {
                assertionFailure()
                print(NSLocalizedString("unknown_error", comment: ""))
            }
        }
    }
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
    return result
}

func updateFile(url:NSURL,
                extract:String throws -> [String:String],
                pairs:[String:String],
                inject:[String:String] throws -> String) throws {
    let fileManager = NSFileManager.defaultManager()
    try fileManager.openStringFileAtURL(url, createIfNeeded: true, append: false) {
        string in
        
        let e = try extract(string)
        var values = Array(pairs.values)
        values.appendContentsOf(e.values)
        var keys = Array(pairs.keys)
        keys.appendContentsOf(e.keys)
        values = Array(Set(values)).sort({return $0 > $1})
        keys = Array(Set(keys)).sort({return $0 > $1})
        
        return try inject(Dictionary(zip(keys, values)))
    }
}

do {
    
    let fileManager = NSFileManager.defaultManager()
    let localizedStringsResult = try replaceInProjectObjects(localizedStringObjectFilter,
                                                             sanitizeRegex: localizedStringSanitize,
                                                             findRegex: localizedStringFindRegex,
                                                             replaceRegex: localizedStringReplaceRegex,
                                                             forwardTransform: localizedStringForwardTransform,
                                                             backwardTransform: localizedStringBackwardTransform)
    let localizedStringsPairs = Dictionary(localizedStringsResult.flatMap{$0.replacements})
    //guard let languages = Optional(try fileManager.contentsOfDirectoryAtURL(try fileManager.srcRoot()).filter({$0.pathExtension == "lproj"}).map({$0})) where languages.count > 0 else {throw Error.xcodeProjIsNotLocalized}
    
    let extensionFileURL = NSURL(fileURLWithPath: "String+Localized.swift", relativeToURL: try fileManager.srcRoot())
    try updateFile(extensionFileURL, extract: localizedExtensionExtract, pairs: localizedStringsPairs, inject: localizedExtensionInject)
    
}
catch let e as Error {
    exit(e)
}





