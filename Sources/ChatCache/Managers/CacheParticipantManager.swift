//
// CacheParticipantManager.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation
import ChatModels

public final class CacheParticipantManager: CoreDataProtocol {
    public typealias Entity = CDParticipant
    public var context: NSManagedObjectContext
    public let logger: CacheLogDelegate

    required public init(context: NSManagedObjectContext, logger: CacheLogDelegate) {
        self.context = context
        self.logger = logger
    }

    public func insert(model: Entity.Model) {
        let entity = Entity.insertEntity(context)
        entity.update(model)
        CacheConversationManager(context: context, logger: logger).findOrCreateEntity(model.conversation?.id ?? -1) { threadEntity in
            threadEntity?.addToParticipants(entity)
        }
    }

    public func insert(model: Conversation?) {
        CacheConversationManager(context: context, logger: logger).findOrCreateEntity(model?.id ?? -1) { threadEntity in
            self.insertObjects(self.context) { _ in
                if let threadEntity = threadEntity {
                    model?.participants?.forEach { participant in
                        let participantEntity = Entity.insertEntity(self.context)
                        participantEntity.update(participant)
                        threadEntity.addToParticipants(participantEntity)
                    }
                }
            }
        }
    }

    public func first(_ threadId: Int, _ participantId: Int, _ completion: @escaping (CDParticipant?) -> Void) {
        context.perform {
            let req = CDParticipant.fetchRequest()
            req.predicate = self.predicate(threadId, participantId)
            let participant = try self.context.fetch(req).first
            completion(participant)
        }
    }

    func predicate(_ threadId: Int, _ participantId: Int) -> NSPredicate {
        NSPredicate(format: "conversation.\(CDConversation.idName) == \(CDConversation.queryIdSpecifier) AND \(Entity.idName) == \(Entity.queryIdSpecifier)", threadId, threadId, participantId)
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

    public func getParticipantsForThread(_ threadId: Int?, _ count: Int?, _ offset: Int?, _ completion: @escaping ([Entity], Int) -> Void) {
        let predicate = NSPredicate(format: "conversation.\(CDConversation.idName) == \(CDConversation.queryIdSpecifier)", threadId ?? -1)
        fetchWithOffset(entityName: Entity.name, count: count, offset: offset, predicate: predicate, completion)
    }

    public func delete(_ models: [Entity.Model]) {
        let ids = models.compactMap(\.id)
        let predicate = NSPredicate(format: "\(Entity.idName) IN %@", ids)
        batchDelete(context, entityName: Entity.name, predicate: predicate)
    }

    public func findOrCreateEntity(_ threadId: Int?, _ participantId: Int?, _ completion: @escaping (Entity?) -> Void) {
        first(threadId ?? -1, participantId ?? -1) { participant in
            completion(participant ?? Entity.insertEntity(self.context))
        }
    }
}
