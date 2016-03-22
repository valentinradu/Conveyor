//
//  Common+CO.swift
//  Conveyor
//
//  Created by Valentin Radu on 22/03/16.
//  Copyright © 2016 Valentin Radu. All rights reserved.
//

import Foundation

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

struct Project {
    let supportedFileTypes = ["sourcecode.swift", "sourcecode.cpp.cpp", "sourcecode.c.objc", "sourcecode.c.c", "sourcecode.cpp.objcpp", "sourcecode.c.h", "sourcecode.cpp.h", "sourcecode.objj.h"]
    let pbx:[String:AnyObject]
    init() throws {
        let fileManager = NSFileManager.defaultManager()
        guard let projPbxData = NSData(contentsOfURL: try fileManager.pbxProjectFileUrl()) else {throw Error.xcodePbxprojCantOpen}
        guard let projPbx = try NSPropertyListSerialization.propertyListWithData(projPbxData, options: NSPropertyListMutabilityOptions.Immutable, format: nil) as? [String:AnyObject] else {throw Error.xcodePbxprojUnsupportedFormat}
        pbx = projPbx
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
    
    func replaceInObjects(param:ReplaceParam) throws -> [(path:NSURL, replacements:[String:String])] {
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
                        
                        do {try file.sanitize(param.sanitizeRegex())}
                        catch let e as Error {print(e, " \(url.lastPathComponent ?? "")")}
                        
                        let r = try file.replace(param.findRegex(), replaceRegex: param.replaceRegex(), transform: param.forwardTransform)
                        dispatch_group_async(group, serialQueue) {
                            let r = (url, Dictionary(r.map{(param.backwardTransform($0.1), $0.0)}))
                            result.append(r)
                        }
                        file.closeFile()
                    }
                    catch let e as CustomStringConvertible {
                        print(e, " \(url.lastPathComponent ?? "")")
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





