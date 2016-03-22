//
//  NSTextCheckingResult+Base.swift
//  Conveyor
//
//  Created by Valentin Radu on 21/03/16.
//  Copyright © 2016 Valentin Radu. All rights reserved.
//

import Foundation

extension String {
    public func substringWithRange(aRange: NSRange) -> String {
        let start = self.startIndex.advancedBy(aRange.location)
        let end = self.startIndex.advancedBy(NSMaxRange(aRange))
        return self.substringWithRange(start..<end)
    }
    
    public func lineRangeForRange(aRange: NSRange) -> Range<Index> {
        let start = self.startIndex.advancedBy(aRange.location)
        let end = self.startIndex.advancedBy(NSMaxRange(aRange))
        return self.lineRangeForRange(start..<end)
    }
    
    public var camelCaseString:String {
        let set = NSCharacterSet(charactersInString: "-_.")
        return self.componentsSeparatedByCharactersInSet(set).enumerate().map({$0.0 == 0 ? $0.1.lowercaseString : $0.1.lowercaseString.capitalizedString}).joinWithSeparator("") as String
    }
}