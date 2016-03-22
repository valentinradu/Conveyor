//
//  LocalizedStrings.swift
//  Conveyor
//
//  Created by Valentin Radu on 22/03/16.
//  Copyright © 2016 Valentin Radu. All rights reserved.
//

import Foundation

struct LocalizedStrings:SearchParam, ReplaceParam, ExtractRule, InjectRule {
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
    func localizedStringWrapper(strings:() -> [String]) -> String  {
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
    func run(string:String) throws -> [String:String] {
        let regex = "let (.+?) = NSLocalizedString\\(\"(.+?)\",.*?\\)"
        let r = try NSRegularExpression(pattern: regex, options: [])
        let searchResults = r.matchesInString(string, options: .ReportCompletion, range: NSRange(location: 0, length: string.characters.count))
        return Dictionary(searchResults.map{
            (r:NSTextCheckingResult) -> (String, String) in
            return (string.substringWithRange(r.rangeAtIndex(1)), string.substringWithRange(r.rangeAtIndex(2)))
            })
    }
    func run(p:[String:String]) throws -> String {
        let result = localizedStringWrapper {
            return p.flatMap {
                s in
                guard s.0.characters.count > 0 else {return nil}
                return "let \(s.0) = NSLocalizedString(\"\(s.1)\", comment: \"\")"
            }
        }
        
        return result
    }
}