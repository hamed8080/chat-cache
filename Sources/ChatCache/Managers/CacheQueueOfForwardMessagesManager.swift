//
// CacheQueueOfForwardMessagesManager.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation
import ChatModels

public final class CacheQueueOfForwardMessagesManager: CoreDataProtocol {
    public typealias Entity = CDQueueOfForwardMessages
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
    
    public func insert(_ forward: Entity.Model) {
        insert(models: [forward])
    }

    public func delete(_ uniqueIds: [String]) {
        let predicate = NSPredicate(format: "uniqueIds CONTAINS %@", uniqueIds)
        batchDelete(context, entityName: Entity.name, predicate: predicate)
    }

    public func unsedForThread(_ threadId: Int?, _ count: Int?, _ offset: Int?, _ completion: @escaping ([Entity], Int) -> Void) {
        let threadIdPredicate = NSPredicate(format: "threadId == \(CDConversation.queryIdSpecifier)", threadId ?? -1)
        fetchWithOffset(entityName: Entity.name, count: count, offset: offset, predicate: threadIdPredicate, completion)
    }
}
