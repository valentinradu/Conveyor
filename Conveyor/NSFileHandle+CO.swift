//
//  UTF8File.swift
//  Conveyor
//
//  Created by Valentin Radu on 22/03/16.
//  Copyright © 2016 Valentin Radu. All rights reserved.
//

import Foundation

protocol Rule {
    associatedtype RawType
    associatedtype CanonicType
}

protocol ExtractRule:Rule {
    func run(_:RawType) throws -> CanonicType
}

protocol InjectRule:Rule {
    func run(_:CanonicType) throws -> RawType
}

extension NSFileHandle {
    
    func writeData(data:NSData, offset:UInt64) {
        seekToFileOffset(offset)
        writeData(data)
    }
    
    func writeString(string:String, offset:UInt64) throws -> NSData {
        guard let data = string.dataUsingEncoding(NSUTF8StringEncoding) else {throw Error.invalidData}
        writeData(data, offset: offset)
        return data
    }
    
    func string(offset:UInt64) throws -> String {
        seekToFileOffset(offset)
        guard let string = String(data: readDataToEndOfFile(), encoding: NSUTF8StringEncoding) else {throw Error.invalidFile}
        return string
    }
    
    func sanitize(regex:String) throws -> [(String, Int)] {
        let string = try self.string(0)
        let r = try NSRegularExpression(pattern: regex, options: [])
        let results = r.matchesInString(string, options: .ReportCompletion, range: NSRange(location: 0, length: string.characters.count))
        
        let t = results.map {
            (result:NSTextCheckingResult) -> (String, Int) in
            
            let range = result.rangeAtIndex(0)
            var lineRange = string.lineRangeForRange(range)
            var count = 1
            while string.startIndex != lineRange.startIndex {
                lineRange = string.lineRangeForRange(lineRange.startIndex.advancedBy(-1)..<lineRange.startIndex)
                count += 1
            }
            
            return (string.substringWithRange(range), count)
        }
        return t
    }
    
    func replace(findRegex:String, replaceRegex:String, transform:String->String, dryRun:Bool) throws -> [String:String] {
        var string = try self.string(0)
        let r = try NSRegularExpression(pattern: findRegex, options: [])
        let results = r.matchesInString(string, options: .ReportCompletion, range: NSRange(location: 0, length: string.characters.count))
        guard results.count > 0 else {throw Error.patternNotFound}
        
        var offset = 0
        var replacements = [String:String]()
        for result in results {
            var range = result.range
            range.location += offset
            let match = r.replacementStringForResult(result, inString: string, offset: offset, template: replaceRegex)
            let replacement = "\(transform(match))"
            let start = string.startIndex.advancedBy(range.location)
            let end = string.startIndex.advancedBy(range.location + range.length)
            if !dryRun {
                string.replaceRange(start..<end, with: replacement)
                offset += replacement.characters.count - range.length
            }
            replacements[match] = replacement
        }
        
        self.truncateFileAtOffset(UInt64(try self.writeString(string, offset: 0).length))
        
        return replacements
    }
    
    func extract<T:ExtractRule where T.RawType == String>(rule:T) throws -> T.CanonicType {
        let string = try self.string(0)
        return try rule.run(string)
    }
    
    func inject<T:InjectRule where T.RawType == String>(pairs:T.CanonicType, rule:T) throws {
        guard let data = try rule.run(pairs).dataUsingEncoding(NSUTF8StringEncoding) else {throw Error.invalidData}
        writeData(data, offset: 0)
        self.truncateFileAtOffset(UInt64(data.length))
    }
    
    func injectUnique<T:ExtractRule, V:InjectRule, U:Hashable, X where T.RawType == V.RawType, T.CanonicType == V.CanonicType, T.RawType == String, T.CanonicType == Dictionary<U, X>>
        (override:Bool, pairs:T.CanonicType, extractRule:T, injectRule:V) throws {
        guard pairs.count > 0 else {return}
        let other = try extract(extractRule)
        
        var left, right : [U : X]
        if override {
            left = other
            right = pairs
        }
        else {
            left = pairs
            right = other
        }
        
        left.mergeInPlace(right)
        try inject(left, rule: injectRule)
    }
}









