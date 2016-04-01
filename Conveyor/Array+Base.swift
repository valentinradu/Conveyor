//
//  Array+Base.swift
//  Conveyor
//
//  Created by Valentin Radu on 01/04/16.
//  Copyright © 2016 Valentin Radu. All rights reserved.
//

import Foundation

extension CollectionType {
    public func nullify() -> Self? {
        if self.count == self.startIndex.distanceTo(self.startIndex) {
            return nil
        }
        else {
            return self
        }
    }
}