//
//  Dictionary+Init.swift
//  CustomList
//
//  Created by Valentin Radu on 16/02/16.
//  Copyright © 2016 Valentin Radu. All rights reserved.
//

import Foundation

extension Dictionary {
    init<S: SequenceType where S.Generator.Element == Element> (_ seq: S) {
        self.init()
        for (k,v) in seq {
            self[k] = v
        }
    }
    mutating public func mergeInPlace<T: SequenceType where T.Generator.Element == Element>(seq:T) {
        for (k,v) in seq {
            self[k] = v
        }
    }
}