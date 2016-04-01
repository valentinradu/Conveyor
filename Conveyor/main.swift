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
    try project.parse(Array(NSProcessInfo.processInfo().arguments.dropFirst()))
    try project.run()
}
catch let e as Error {
    exit(e)
}





