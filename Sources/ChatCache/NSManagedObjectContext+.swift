//
// NSManagedObjectContext.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import Foundation
import CoreData

internal extension NSManagedObjectContext {
    func perform(_ block: @escaping () throws -> Void, errorCompeletion: ((Error) -> Void)? = nil) {
        perform {
            do {
                try block()
            } catch {
                errorCompeletion?(error)
            }
        }
    }
}
