//
// CacheTagManager.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation
import ChatModels

public final class CacheTagManager: CoreDataProtocol {
    public typealias Entity = CDTag
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

    public func getTags(_ completion: @escaping ([Entity]) -> Void) {
        context.perform {
            let req = Entity.fetchRequest()
            let tags = try self.context.fetch(req)
            completion(tags)
        }
    }

    public func delete(_ id: Int?) {
        let predicate = idPredicate(id: id ?? -1)
        batchDelete(context, entityName: Entity.name, predicate: predicate)
    }
}
