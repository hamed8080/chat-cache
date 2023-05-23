//
// CacheMutualGroupManager.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation
import ChatModels

public final class CacheMutualGroupManager: BaseCoreDataManager<CDMutualGroup> {

    public override func insert(model: Entity.Model, context: NSManagedObjectContext) {
        let entity = Entity.insertEntity(context)
        entity.update(model)
        model.conversations?.forEach { thread in
            CacheConversationManager(container: container, logger: logger).findOrCreateEntity(thread.id ?? -1, context) { threadEntity in
                if let threadEntity = threadEntity {
                    threadEntity.update(thread)
                    entity.addToConversations(threadEntity)
                }
            }
        }
    }

    public func insert(_ threads: [Conversation], idType: InviteeTypes = .unknown, mutualId: String?) {
        let model = Entity.Model(idType: idType , mutualId: mutualId, conversations: threads)
        insert(models: [model])
    }

    public func mutualGroups(_ id: String?, _ completion: @escaping ([Entity]) -> Void) {
        viewContext.perform {
            let req = Entity.fetchRequest()
            req.predicate = NSPredicate(format: "mutualId == %@", id ?? "")
            let mutuals = try self.viewContext.fetch(req)
            completion(mutuals)
        }
    }
}
