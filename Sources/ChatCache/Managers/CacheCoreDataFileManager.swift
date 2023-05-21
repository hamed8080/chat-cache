//
// CacheCoreDataFileManager.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation
import ChatModels

public final class CacheCoreDataFileManager: CoreDataProtocol {
    public typealias Entity = CDFile
    public var context: NSManagedObjectContext
    public let logger: CacheLogDelegate

    required public init(context: NSManagedObjectContext, logger: CacheLogDelegate) {
        self.context = context
        self.logger = logger
    }
    
    public func update(_ propertiesToUpdate: [String: Any], _ predicate: NSPredicate) {
        // batch update request
        batchUpdate(context) { bgTask in
            let batchRequest = NSBatchUpdateRequest(entityName: Entity.name)
            batchRequest.predicate = predicate
            batchRequest.propertiesToUpdate = propertiesToUpdate
            batchRequest.resultType = .updatedObjectIDsResultType
            _ = try? bgTask.execute(batchRequest)
        }
    }
}
