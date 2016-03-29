//
//  Common+CO.swift
//  Conveyor
//
//  Created by Valentin Radu on 22/03/16.
//  Copyright © 2016 Valentin Radu. All rights reserved.
//

import Foundation

protocol Action:CustomStringConvertible {
    var commands:[String:(Action, String)]? {get}
    var options:[String:(Int, (args:[String]) throws -> String, String)]? {get}
    var help:String {get}
}

extension Action {
    var help: String {
        var names = [String]()
        if let commands = self.commands where commands.count > 0 {
            names.append("Commands:")
            names.appendContentsOf(commands.map{key, item in return "\(key) : \(item.1)"} ?? [])
            names.append("")
        }
        
        if let options = self.options {
            names.append("Options:")
            names.appendContentsOf(options.map{key, item in return "\(key) : \(item.2)"} ?? [])
        }
        return names.joinWithSeparator("\r\n")
    }
    var description:String {
        return self.help
    }
}

extension Project {
    var description: String {
        var welcome = "\r\nConveyor 1.0. This tool is used to extract resources into extensions allowing the compiler to check them at compile time."
        welcome.appendContentsOf("\r\n\r\n")
        welcome.appendContentsOf(self.help)
        return welcome
    }
}

protocol SearchParam {
    func objectFilter(_:[String:AnyObject]) -> Bool
    func sanitizeRegex() -> String
    func findRegex() -> String
}

protocol ReplaceParam:SearchParam {
    func replaceRegex() -> String
    func forwardTransform(_:String) -> String
    func backwardTransform(_:String) -> String
}

struct Project:Action {
    let supportedFileTypes = ["sourcecode.swift", "sourcecode.cpp.cpp", "sourcecode.c.objc", "sourcecode.c.c", "sourcecode.cpp.objcpp", "sourcecode.c.h", "sourcecode.cpp.h", "sourcecode.objj.h"]
    let pbx:[String:AnyObject]
    private(set) var commands:[String:(Action, String)]?
    private(set) var options:[String:(Int, (args:[String]) throws -> String, String)]?
    init() throws {
        let fileManager = NSFileManager.defaultManager()
        guard let projPbxData = NSData(contentsOfURL: try fileManager.pbxProjectFileUrl()) else {throw Error.xcodePbxprojCantOpen}
        guard let projPbx = try NSPropertyListSerialization.propertyListWithData(projPbxData, options: NSPropertyListMutabilityOptions.Immutable, format: nil) as? [String:AnyObject] else {throw Error.xcodePbxprojUnsupportedFormat}
        pbx = projPbx
        
        commands = [
            "locs":(try LocalizedStrings(project: self), "Work with localized strings. Extract from project, inject into .strings files or .csv, etc.")
        ]
        options = ["-h":(0, {args in return self.description}, "Show this help page")]
    }
    
    func listObjects() throws -> [String:AnyObject] {
        guard let objects = pbx["objects"] as? [String:AnyObject] else {throw Error.xcodePbxprojUnsupportedFormat}
        return objects
    }
    
    func listSourceFiles() throws -> [String:AnyObject] {
        
        return try Dictionary(listObjects().filter{
            key, value in
            guard
                let isa = value["isa"] as? String,
                let explicitType = value["explicitFileType"] as? String?,
                let lastKnownType = value["lastKnownFileType"] as? String?
            where
                isa == "PBXFileReference" &&
                (self.supportedFileTypes.contains(explicitType ?? "") || self.supportedFileTypes.contains(lastKnownType ?? ""))
            else {return false}
            return true
        })
    }
    
    func replaceInObjects(param:ReplaceParam, dryRun:Bool) throws -> [(path:NSURL, replacements:[String:String])] {
            let fileManager = NSFileManager.defaultManager()
            let group = dispatch_group_create()
            let serialQueue = dispatch_queue_create("Serial", DISPATCH_QUEUE_SERIAL)
            let objects = try listSourceFiles()
            
            var result = [(path:NSURL, replacements:[String:String])]()
            
            for (_, value) in objects {
                guard
                    let value = value as? [String:AnyObject],
                    let path = value["path"] as? String
                else {continue}
                guard param.objectFilter(value) else {continue}
                let url = NSURL(fileURLWithPath: path, relativeToURL: try fileManager.srcRoot())
                
                dispatch_group_async(group, dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
                    do {
                        let file = try NSFileHandle(forUpdatingURL: url)
                        
                        let sanR = try file.sanitize(param.sanitizeRegex())
                        do {
                            guard sanR.count == 0 else { throw Error.failedSanitization(file: url.lastPathComponent ?? "", string: sanR) }
                        } catch let e as Error {
                            print(e)
                        }
                        
                        let r = try file.replace(param.findRegex(), replaceRegex: param.replaceRegex(), transform: param.forwardTransform, dryRun: dryRun)
                        dispatch_group_async(group, serialQueue) {
                            let r = (url, Dictionary(r.map{(param.backwardTransform($0.1), $0.0)}))
                            result.append(r)
                        }
                        file.closeFile()
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
}





