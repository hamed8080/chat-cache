//
// CacheParticipantManager.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation
import ChatModels

public final class CacheParticipantManager: BaseCoreDataManager<CDParticipant> {

    public func insert(model: Conversation) {
        guard let threadId = model.id else { return }
        let cmThread = BaseCoreDataManager<CDConversation>(container: container, logger: logger)
        self.insertObjects() { context in
            let threadEntity: CDConversation = cmThread.findOrCreate(threadId, context)
            threadEntity.update(model)
            model.participants?.forEach { participant in
                let participantEntity = Entity.insertEntity(context)
                participantEntity.conversation = threadEntity
                participantEntity.update(participant)
                threadEntity.addToParticipants(participantEntity)
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
        NSPredicate(format: "conversation.\(CDConversation.idName) == \(CDConversation.queryIdSpecifier) AND \(Entity.idName) == \(Entity.queryIdSpecifier)", threadId, participantId)
    }

    public func getThreadParticipants(_ threadId: Int, _ count: Int?, _ offset: Int?, _ completion: @escaping ([Entity], Int) -> Void) {
        let predicate = NSPredicate(format: "conversation.\(CDConversation.idName) == \(CDConversation.queryIdSpecifier)", threadId)
        fetchWithOffset(count: count, offset: offset, predicate: predicate, completion)
    }

    public func delete(_ models: [Entity.Model], _ threadId: Int) {
        let ids = models.compactMap(\.id)
        let predicate = NSPredicate(format: "%K IN %@ AND %K == %i",
                                    #keyPath(CDParticipant.id), ids,
                                    #keyPath(CDParticipant.conversation.id), threadId)
        batchDelete(predicate: predicate)
    }

    /// Attach a participant entity to a message entity as well as set a conversation entity over the participant entity.
    func attach(messageEntity: CDMessage, threadEntity: CDConversation, lastMessageVO: Message, threadId: Int, context: NSManagedObjectContextProtocol) {
        if let participant = lastMessageVO.participant, let participantId = participant.id {
            let entity = Entity.findOrCreate(threadId: threadId, participantId: participantId, context: context)
            messageEntity.participant = entity
            entity.conversation = threadEntity
        }
    }
}
