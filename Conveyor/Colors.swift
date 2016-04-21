//
//  Colors.swift
//  Conveyor
//
//  Created by Valentin Radu on 04/04/16.
//  Copyright © 2016 Valentin Radu. All rights reserved.
//

import Foundation
import Cocoa

class Colors:Action, Context {
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
            "-clr-ex":OptionDescription(runable: clrex, description: "Get colors from all palettes into the extension.", priority: 3)
        ]
        availableOptions?.mergeInPlace(defaultOptions())
    }
    func clrex(args:[String]) throws -> String {
        let filemanager = NSFileManager.defaultManager()
        let palettes = Dictionary(try (try filemanager.colorPalettesUrls())
            .flatMap{
                (url:NSURL) -> (String, [String:String])? in
                let filemanager = NSFileManager.defaultManager()
                let installUrl = NSURL(fileURLWithPath:("~/Library/Colors" as NSString).stringByExpandingTildeInPath).URLByAppendingPathComponent(url.lastPathComponent!)
                
                _ = try? filemanager.removeItemAtURL(installUrl)
                try filemanager.copyItemAtURL(url, toURL: installUrl)
        
                let name = url.URLByDeletingPathExtension!.lastPathComponent!
                guard let list = NSColorList(named: name)
                else {assertionFailure(); return nil}
                
                let colors = list.allKeys.map{
                    [unowned list] (key:String) -> (String, String) in
                    let hex = list.colorWithKey(key)!.hex()
                    return (key, hex)
                }
                return (name.camelCaseString, Dictionary(colors))
            }
        )
        try putResultsToExtensionFile(palettes)
        return "Found \(palettes.count) palettes. Successfully insterted them into the extension."
    }
    
    func putResultsToExtensionFile(result:[String:[String:String]]) throws {
        let filemanager = NSFileManager.defaultManager()
        try filemanager.createFileAtUrlIfNeeded(filemanager.colorsExtensionUrl(), contents: nil, attributes: nil)
        let extensionFile = try NSFileHandle(forUpdatingURL: try filemanager.colorsExtensionUrl())
        try extensionFile.injectUnique(
            self.forceful,
            pairs: result,
            extractRule: ColorsExtractFromExtension(),
            injectRule: ColorsInjectInExtension()
        )
        extensionFile.closeFile()
    }
    
    struct ColorsExtractFromExtension:ExtractRule {
        typealias RawType = String
        typealias CanonicType = [String:[String:String]]
        func run(string:RawType) throws -> CanonicType {
            let nameRegex = "CWPalette\\(name:\\s\"(.+)\",\\sdic:\\[\\n((.|\\n)+?)\\]\\)"
            let reg = try NSRegularExpression(pattern: nameRegex, options: [])
            let searchResults = reg.matchesInString(string, options: .ReportCompletion, range: NSRange(location: 0, length: string.characters.count))
            
            return Dictionary(try searchResults.flatMap{
                (r:NSTextCheckingResult) throws -> (String, [String : String]) in
                
                let colorsStrings = string.substringWithRange(r.rangeAtIndex(2))
                let colorsRegex = "\"(.+?)\":\\sUIColor\\(red:\\s(.+?),\\sgreen:\\s(.+?),\\sblue:\\s(.+?),\\salpha:\\s(.+?)\\)"
                let reg = try NSRegularExpression(pattern: colorsRegex, options: [])
                
                let dic = Dictionary(colorsStrings.componentsSeparatedByString(",\n").flatMap {
                    (line:String) -> [(String, String)] in
                    let colorsResults = reg.matchesInString(line, options: .ReportCompletion, range: NSRange(location: 0, length: line.characters.count));
                    return colorsResults.flatMap {
                        (cr:NSTextCheckingResult) -> (String, String)? in
                        let name = line.substringWithRange(cr.rangeAtIndex(1))
                        guard let red = Float(line.substringWithRange(cr.rangeAtIndex(2))) else {return nil}
                        guard let green = Float(line.substringWithRange(cr.rangeAtIndex(3))) else {return nil}
                        guard let blue = Float(line.substringWithRange(cr.rangeAtIndex(4))) else {return nil}
                        guard let alpha = Float(line.substringWithRange(cr.rangeAtIndex(5))) else {return nil}
                        
                        let color = NSColor(red: CGFloat(red), green: CGFloat(Float(green)), blue: CGFloat(Float(blue)), alpha: CGFloat(Float(alpha)))
                        return (name, color.hex())
                    }
                })
                
                return (String(string.substringWithRange(r.rangeAtIndex(1))).camelCaseString, dic)
            })
        }
    }
    
    struct ColorsInjectInExtension: InjectRule {
        typealias RawType = String
        typealias CanonicType = [String:[String:String]]
        func run(dic:CanonicType) throws -> RawType {
            let palettes = Array<String>(dic.map{
                name, colors in
                let colors = Array<String>(colors.map {
                    name, hex in
                    let color = NSColor(hex:hex)
                    return String(format:TemplateColorExtensionDicItem, name.camelCaseString, String(color.redComponent), String(color.greenComponent), String(color.blueComponent), String(color.alphaComponent))
                })
                return String(format:TemplateColorExtensionPaletteItem, name.camelCaseString, colors.joinWithSeparator(",\n"))
            })
            
            let colors = Dictionary(dic.flatMap{Dictionary($0.1.map{($0.camelCaseString, $1)})})
            
            let lets = colors.map {
                name, color in
                return String(format:TemplateColorExtensionLetItem, name.camelCaseString)
            }
            let inits = colors.map {
                name, color in
                return String(format:TemplateColorExtensionInitItem, name.camelCaseString, name.camelCaseString)
            }
            return String(format:TemplateColorExtension, palettes.joinWithSeparator(",\n"), lets.joinWithSeparator("\n"), inits.joinWithSeparator("\n"))
        }
    }
}





