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

do {
    let filemanager = NSFileManager.defaultManager()
    let project = try Project()
    let localizedStrings = LocalizedStrings()
    let localizedStringsResult = Dictionary(try project.replaceInObjects(localizedStrings).flatMap{$0.replacements})
    let localizedExtensionFile = try NSFileHandle(forUpdatingURL: try filemanager.localizedStringsExtensionUrl(), createIfNeeded: true)
    try localizedExtensionFile.injectUnique(localizedStringsResult, rule: localizedStrings)
    localizedExtensionFile.closeFile()
}
catch let e as Error {
    exit(e)
}





