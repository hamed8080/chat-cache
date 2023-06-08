//
// CacheParticipantManager.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation
import ChatModels

public final class CacheParticipantManager: BaseCoreDataManager<CDParticipant> {

    public override func insert(model: Entity.Model, context: NSManagedObjectContextProtocol) {
        let entity = Entity.insertEntity(context)
        entity.update(model)
        let cmThread = BaseCoreDataManager<CDConversation>(container: container, logger: logger)
        cmThread.findOrCreate(model.conversation?.id ?? -1) { (threadEntity: CDConversation) in
            threadEntity.addToParticipants(entity)
        }
    }

    public func insert(model: Conversation?) {
        let cmThread = BaseCoreDataManager<CDConversation>(container: container, logger: logger)
        self.insertObjects() { context in
            cmThread.findOrCreate(model?.id ?? -1) { (threadEntity: CDConversation) in
                model?.participants?.forEach { participant in
                    let participantEntity = Entity.insertEntity(context)
                    participantEntity.update(participant)
                    threadEntity.addToParticipants(participantEntity)
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
        NSPredicate(format: "conversation.\(CDConversation.idName) == \(CDConversation.queryIdSpecifier) AND \(Entity.idName) == \(Entity.queryIdSpecifier)", threadId, participantId)
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

    /// Attach a participant entity to a message entity as well as set a conversation entity over the participant entity.
    func attach(messageEntity: CDMessage, threadEntity: CDConversation, lastMessageVO: Message, threadId: Int, context: NSManagedObjectContextProtocol) {
        if let participant = lastMessageVO.participant {
            let entity = findOrCreate(participant: participant, threadId: threadId, context: context)
            messageEntity.participant = entity
            entity.conversation = threadEntity
        }
    }

    private func findOrCreate(participant: Participant, threadId: Int, context: NSManagedObjectContextProtocol) -> CDParticipant {
        let participantReq = CDParticipant.fetchRequest()
        participantReq.predicate = predicate(threadId, participant.id ?? -1)
        let entity = (try? context.fetch(participantReq).first) ?? CDParticipant.insertEntity(context)
        entity.update(participant)
        return entity
    }

    private func attachToMessageEntity(entity: CDParticipant, messageEntity: CDMessage) {
        messageEntity.participant = entity
    }

    private func attachConversationToEntity(entity: CDParticipant, conversationEntity: CDConversation) {
        entity.conversation = conversationEntity
    }
}
