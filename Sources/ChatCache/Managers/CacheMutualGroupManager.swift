//
// CacheMutualGroupManager.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation
import ChatModels

public final class CacheMutualGroupManager: CoreDataProtocol {
    public typealias Entity = CDMutualGroup
    public var context: NSManagedObjectContext
    public let logger: CacheLogDelegate

    required public init(context: NSManagedObjectContext, logger: CacheLogDelegate) {
        self.context = context
        self.logger = logger
    }

    public func insert(model: Entity.Model) {
        let entity = Entity.insertEntity(context)
        entity.update(model)
        model.conversations?.forEach { thread in
            CacheConversationManager(context: context, logger: logger).findOrCreateEntity(thread.id ?? -1) { threadEntity in
                if let threadEntity = threadEntity {
                    threadEntity.update(thread)
                    entity.addToConversations(threadEntity)
                }
            }
        }
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

    public func insert(_ threads: [Conversation], idType: InviteeTypes = .unknown, mutualId: String?) {
        let model = Entity.Model(idType: idType , mutualId: mutualId, conversations: threads)
        insert(models: [model])
    }

    public func mutualGroups(_ id: String?, _ completion: @escaping ([Entity]) -> Void) {
        context.perform {
            let req = Entity.fetchRequest()
            req.predicate = NSPredicate(format: "mutualId == %@", id ?? "")
            let mutuals = try self.context.fetch(req)
            completion(mutuals)
        }
    }
}
