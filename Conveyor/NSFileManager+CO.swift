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
    func contentsOfLocalizedDirectories() throws -> [NSURL] {
        guard let languages = Optional(
            try self.contentsOfDirectoryAtURL(try self.srcRoot()).filter({$0.pathExtension == "lproj"}))
        where languages.count > 0 else {throw Error.xcodeProjIsNotLocalized}
        return languages
    }
    func localizedStringsUrls() throws -> [NSURL] {
        return try self.contentsOfLocalizedDirectories().map{NSURL(fileURLWithPath: "Strings.strings", relativeToURL: $0)}
    }
    func localizedStringsExtensionUrl() throws -> NSURL {
        return NSURL(fileURLWithPath: "String+Localized.swift", relativeToURL: try self.srcRoot())
    }
    func localizedStringsCSVUrl() throws -> NSURL {
        return NSURL(fileURLWithPath: "Strings.csv", relativeToURL: try self.srcRoot())
    }
    func createFileAtUrlIfNeeded(url:NSURL, contents:NSData?, attributes:[String : AnyObject]?) throws {
        guard let path = url.path else {throw Error.urlNotFound}
        if !fileExistsAtPath(path) {
            guard self.createFileAtPath(path, contents: contents, attributes: attributes) == true else {throw Error.cantCreateFile}
        }
    }
}


















