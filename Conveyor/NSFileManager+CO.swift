//
//  NSFileManager.swift
//  Conveyor
//
//  Created by Valentin Radu on 11/03/16.
//  Copyright © 2016 Valentin Radu. All rights reserved.
//

import Foundation

extension NSFileManager {
    func pbxProjectFileUrl() throws -> NSURL {
        guard let url = try contentsOfProjectPackage().filter({$0.pathExtension == "pbxproj"}).first else {throw Error.xcodePbxprojNotFound}
        return url
    }
    func srcRoot() throws -> NSURL {
        guard let url = try contentsOfCurrentDirectory().filter({$0.pathExtension == "xcodeproj"}).first?.URLByDeletingPathExtension else {throw Error.xcodeProjNotFound}
        return url
    }
    func contentsOfProjectPackage() throws -> [NSURL] {
        guard let url = try contentsOfCurrentDirectory().filter({$0.pathExtension == "xcodeproj"}).first else {throw Error.xcodeProjNotFound}
        let urls = try self.contentsOfDirectoryAtURL(url)
        return urls
    }
    func contentsOfCurrentDirectory() throws -> [NSURL] {
        let urls = try self.contentsOfDirectoryAtURL(NSURL(fileURLWithPath: self.currentDirectoryPath))
        return urls
    }
    func contentsOfDirectoryAtURL(url:NSURL) throws -> [NSURL] {
        return try contentsOfDirectoryAtURL(url, includingPropertiesForKeys: [NSURLIsDirectoryKey, NSURLIsPackageKey], options: [.SkipsHiddenFiles, .SkipsSubdirectoryDescendants])
    }
    func openStringFileAtURL(url:NSURL, createIfNeeded:Bool, append:Bool, transform:String throws -> String) throws {
        if createIfNeeded && !self.fileExistsAtPath(url.path!) {
            self.createFileAtPath(url.path!, contents: nil, attributes: nil)
        }
        
        guard let data = NSMutableData(contentsOfURL: url) else {throw Error.cantOpenFile(file: url.path!)}
        guard let string = String(data: data, encoding: NSUTF8StringEncoding) else {throw Error.cantOpenFile(file: url.path!)}
        let result = try transform(string)
        
        if let oData = result.dataUsingEncoding(NSUTF8StringEncoding) {
            let handle = try NSFileHandle(forUpdatingURL: url)
            if append {
                handle.seekToEndOfFile()
            }
            else {
                handle.seekToFileOffset(0)
            }
            handle.writeData(oData)
            handle.truncateFileAtOffset(UInt64(oData.length))
            handle.closeFile()
        }
    }
}


















