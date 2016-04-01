//
//  main.swift
//  Conveyor
//
//  Created by Valentin Radu on 11/03/16.
//  Copyright © 2016 Valentin Radu. All rights reserved.
//
import Foundation

do {
    var project = try Project()
    let args = Array(NSProcessInfo.processInfo().arguments.dropFirst())
    guard args.count > 0 else {throw Error.noArguments}
    try project.parse(args)
    print(try project.run() ?? "")
}
catch let e as Error {
    exit(e)
}





