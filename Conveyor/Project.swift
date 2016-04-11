//
//  Common+CO.swift
//  Conveyor
//
//  Created by Valentin Radu on 22/03/16.
//  Copyright © 2016 Valentin Radu. All rights reserved.
//

//Strings
//Colors
//Notifications
//Images
//Selectors


import Foundation

protocol Api {
    var availableCommands:[String:(protocol<Action,Context>, String)]? {set get}
    var availableOptions:[String:OptionDescription]? {set get}
}

protocol Context:Api {
    var options:[(String, [String])]? {set get}
    var command:String? {set get}
    var otherArgs:[String]? {set get}
    mutating func parse(rawArgs:[String]?) throws
}

extension Context {
    mutating func parse(rawArgs:[String]?) throws {
        
        if let rawArgs = rawArgs where rawArgs.count > 0 {
            var enumerator = rawArgs.enumerate().generate()
            func p(i:Int, arg:String) throws {
                
                if (self.availableCommands ?? [:]).keys.contains(arg) {
                    self.command = arg
                    while let (_, jarg) = enumerator.next() {
                        if self.otherArgs == nil {self.otherArgs = []}
                        self.otherArgs?.append(jarg)
                    }
                    return
                }
                
                if (self.availableOptions ?? [:]).keys.contains(arg) {
                    let all = Array((self.availableCommands ?? [:]).keys) + Array((self.availableOptions ?? [:]).keys)
                    
                    if i < rawArgs.count - 1 && !all.contains(rawArgs[i.successor()]) {
                        var o = [String]()
                        while let (j, jarg) = enumerator.next() {
                            if !all.contains(rawArgs[j]) {
                                o.append(jarg)
                            }
                            else {
                                try p(j, arg: jarg)
                                break
                            }
                        }
                        if o.count > 0 {
                            if self.options == nil {self.options = []}
                            self.options?.append((arg, o))
                        }
                    }
                    else {
                        if self.options == nil {self.options = []}
                        self.options?.append((arg, []))
                        if let next = enumerator.next() {
                            try p(next.index, arg: next.element)
                        }
                    }
                    return
                }
                
                throw Error.invalidArgument(arg: arg)
            }
            try p(0, arg: enumerator.next()!.element)
        }
        else {
            command = nil
            options = [("-h", [])]
        }
        
        for option in options ?? [] {
            if let desc = self.availableOptions?[option.0] {
                guard desc.paramCount.contains(option.1.count) else {throw Error.wrongArgumentsCount(arg: option.0, given: option.1.count, expected: desc.paramCount)}
                if let samePriority = self.options?
                    .map({($0.0, self.availableOptions![$0.0]!.priority)})
                    .filter({$0.1 == desc.priority && $0.0 != option.0}).first {
                    throw Error.samePriorityArgs(arg1: option.0, arg2: samePriority.0)
                }
            }
        }
        
        if let o = self.options where o.count > 0 {
            self.options = o.map({
                    item in
                    return (item, self.availableOptions![item.0]!.priority)
                })
                .sort({
                    return $0.0.1 < $0.1.1
                })
                .map({
                    (arg:(String, [String]), priority:Int) in
                    return arg
                })
        }   
    }
}
typealias OptionsReturn = ([String]) throws -> String?
protocol Runable:Api, CustomStringConvertible {
    var help:String {get}
    func run() throws -> String?
}
protocol Action:Runable {
    var forceful:Bool {set get}
    var testFirst:Bool {set get}
    func checkTest() throws
}
protocol Command:Runable {}

extension Action where Self:Context, Self:AnyObject {
    func checkTest() throws {
        let selfPriority = availableOptions!["-t"]!.priority
        let higherPriorities = options!.flatMap({
            (pair:(String, [String])) -> Int? in
            guard let other = availableOptions?[pair.0] where other.priority > selfPriority else {return nil}
            return other.priority
        })
        guard higherPriorities.count > 0 else {
            throw Error.flagPairsNotSatisfied(flag: "-t")
        }
    }
    func defaultOptions() -> [String:OptionDescription] {
        return [
        "-h":OptionDescription(runable: {_ in return self.description}, description: "Show this help page", priority: 0),
        "-t":OptionDescription(runable: {[weak self] _ in try self?.checkTest(); self?.testFirst = true; return nil}, description: "First makes a search on the source files, indicating any issues and showing all the valid tokens found.", priority: 1),
        "-f":OptionDescription(runable: {[weak self] _ in self?.forceful = true; return nil}, description: "Overwrite the tokens already present in the target file.", priority: 2)
        ]
    }
    func run() throws -> String? {
        guard command == nil else {throw Error.invalidArgument(arg: command!)}
        var iterator = options?.enumerate().generate()
        var arr = [String]()
        while let item = iterator?.next() {
            guard let option = availableOptions?[item.element.0] else {throw Error.invalidArgument(arg: item.element.0)}
            if let s = try option.runable(item.element.1) {
                arr.append(s)
            }
        }
        
        return arr.nullify()?.joinWithSeparator("\n")
    }
}

extension Runable {
    var help: String {
        var names = [String]()
        if let commands = self.availableCommands where commands.count > 0 {
            names.append("Commands:")
            names.appendContentsOf(commands.map{key, item in return "\(key) : \(item.1)"} ?? [])
            names.append("")
        }
        
        if let options = self.availableOptions {
            names.append("Options:")
            names.appendContentsOf(options.map{key, item in return "\(key) : \(item.description)"} ?? [])
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

struct OptionDescription {
    var priority:Int
    var paramCount:Range<Int>
    var description:String
    var runable:OptionsReturn
    
    init(runable r:OptionsReturn, description d:String, priority prt:Int = 0, paramCount pc:Range<Int> = 0...0) {
        runable = r
        priority = prt
        description = d
        paramCount = pc
    }
}

class Project:Command, Context {
    let supportedFileTypes = ["sourcecode.swift", "sourcecode.cpp.cpp", "sourcecode.c.objc", "sourcecode.c.c", "sourcecode.cpp.objcpp", "sourcecode.c.h", "sourcecode.cpp.h", "sourcecode.objj.h"]
    let pbx:[String:AnyObject]
    var command:String?
    var options:[(String, [String])]?
    var otherArgs:[String]?
    var availableCommands:[String:(protocol<Action,Context>, String)]?
    var availableOptions:[String:OptionDescription]?
    init() throws {
        let fileManager = NSFileManager.defaultManager()
        guard let projPbxData = NSData(contentsOfURL: try fileManager.pbxProjectFileUrl()) else {throw Error.xcodePbxprojCantOpen}
        guard let projPbx = try NSPropertyListSerialization.propertyListWithData(projPbxData, options: NSPropertyListMutabilityOptions.Immutable, format: nil) as? [String:AnyObject] else {throw Error.xcodePbxprojUnsupportedFormat}
        pbx = projPbx
        
        availableCommands = [
            "locs":(try LocalizedStrings(project:self), "Work with localized strings. Extract from project, inject into .strings files or .csv."),
            "colors":(try Colors(project:self), "Import colors from all .clr palette files found in the project.")
        ]
        availableOptions = ["-h":OptionDescription(runable: {_ in return self.description}, description: "Show this help page")]
    }
    
    func run() throws -> String?{
        if let command = self.command {
            guard var action = availableCommands?[command]?.0 else {throw Error.invalidArgument(arg: command)}
            try action.parse(otherArgs)
            return try action.run()
        }
        if let options = self.options {
            var actions = [(OptionsReturn, [String])]()
            for (key, value) in options {
                guard let action = availableOptions?[key]?.runable else {throw Error.invalidArgument(arg: key)}
                actions.append((action, value))
            }
            
            return try actions.reduce([String](), combine: {
                (result:[String], action:(OptionsReturn, [String])) -> [String] in
                guard let s = try action.0(action.1) else {return result}
                return result + [s]
            }).nullify()?.joinWithSeparator("\n")
        }
        guard command != nil || options != nil else {assertionFailure(); throw Error.unknownError/*the input was sanitize already, this should never happen*/}
        return nil
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





