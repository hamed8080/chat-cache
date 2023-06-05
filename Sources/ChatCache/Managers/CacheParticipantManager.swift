//
// CacheParticipantManager.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation
import ChatModels

public final class CacheParticipantManager: BaseCoreDataManager<CDParticipant> {

    public override func insert(model: Entity.Model, context: NSManagedObjectContext) {
        let entity = Entity.insertEntity(context)
        entity.update(model)
        CacheConversationManager(container: container, logger: logger).findOrCreateEntity(model.conversation?.id ?? -1, context) { threadEntity in
            threadEntity?.addToParticipants(entity)
        }
    }

    public func insert(model: Conversation?) {
        self.insertObjects() { context in
            CacheConversationManager(container: self.container, logger: self.logger).findOrCreateEntity(model?.id ?? -1, context) { threadEntity in
                if let threadEntity = threadEntity {
                    model?.participants?.forEach { participant in
                        let participantEntity = Entity.insertEntity(context)
                        participantEntity.update(participant)
                        threadEntity.addToParticipants(participantEntity)
                    }
                }
            }
        }
    }

    public func first(_ threadId: Int, _ participantId: Int, _ completion: @escaping (CDParticipant?) -> Void) {
        viewContext.perform {
            let req = CDParticipant.fetchRequest()
            req.predicate = self.predicate(threadId, participantId)
            let participant = try self.viewContext.fetch(req).first
            completion(participant)
        }
    }

    func predicate(_ threadId: Int, _ participantId: Int) -> NSPredicate {
        NSPredicate(format: "conversation.\(CDConversation.idName) == \(CDConversation.queryIdSpecifier) AND \(Entity.idName) == \(Entity.queryIdSpecifier)", threadId, threadId, participantId)
    }

    public func getParticipantsForThread(_ threadId: Int?, _ count: Int?, _ offset: Int?, _ completion: @escaping ([Entity], Int) -> Void) {
        let predicate = NSPredicate(format: "conversation.\(CDConversation.idName) == \(CDConversation.queryIdSpecifier)", threadId ?? -1)
        fetchWithOffset(count: count, offset: offset, predicate: predicate, completion)
    }

    public func delete(_ models: [Entity.Model]) {
        let ids = models.compactMap(\.id)
        let predicate = NSPredicate(format: "\(Entity.idName) IN %@", ids)
        batchDelete(predicate: predicate)
    }

    public func findOrCreateEntity(_ threadId: Int?, _ participantId: Int?, _ completion: @escaping (Entity?) -> Void) {
        first(threadId ?? -1, participantId ?? -1) { participant in
            completion(participant ?? Entity.insertEntity(self.viewContext))
        }
    }
}
