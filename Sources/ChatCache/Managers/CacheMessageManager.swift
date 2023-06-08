//
// CacheMessageManager.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation
import ChatModels

public final class CacheMessageManager: BaseCoreDataManager<CDMessage> {
    func updateRelations(_ entity: Entity, _ model: Entity.Model, context: NSManagedObjectContextProtocol) throws {
        entity.threadId = entity.conversation?.id ?? (model.conversation?.id as? NSNumber)
        try updateParticipant(entity, model, context)
        try updateForwardInfo(entity, model, context)
        updateReplyInfo(entity, model, context)
    }

    func updateParticipant(_ entity: Entity, _ model: Entity.Model, _ context: NSManagedObjectContextProtocol) throws {
        if let participant = model.participant {
            let req = CDParticipant.fetchRequest()
            req.predicate = NSPredicate(format: "conversation.\(CDConversation.idName) == \(CDConversation.queryIdSpecifier) AND \(CDParticipant.idName) == \(Entity.queryIdSpecifier)", entity.conversation?.id?.intValue ?? -1, participant.id ?? -1)
            var participnatEntity = try context.fetch(req).first
            if participnatEntity == nil {
                participnatEntity = CDParticipant.insertEntity(context)
                participnatEntity?.update(participant)
            }
            entity.participant = participnatEntity
            participnatEntity?.conversation = entity.conversation
        }
    }

    func updateReplyInfo(_ entity: Entity, _ model: Entity.Model, _ context: NSManagedObjectContextProtocol) {
        if let replyInfoModel = model.replyInfo {
            let replyInfoEntity = CDReplyInfo.insertEntity(context)
            replyInfoEntity.repliedToMessageId = replyInfoModel.repliedToMessageId as? NSNumber
            replyInfoEntity.participant?.id = model.replyInfo?.participant?.id as? NSNumber
            replyInfoEntity.update(replyInfoModel)
            entity.replyInfo = replyInfoEntity
        }
    }

    func updateForwardInfo(_ entity: Entity, _ model: Entity.Model, _ context: NSManagedObjectContextProtocol) throws {
        if let forwardInfoModel = model.forwardInfo {
            let forwardInfoEntity = CDForwardInfo.insertEntity(context)
            forwardInfoEntity.messageId = model.id as? NSNumber
            forwardInfoEntity.participant = entity.participant

            if let conversation = forwardInfoModel.conversation {
                let req = CDConversation.fetchRequest()
                req.predicate = NSPredicate(format: "\(CDConversation.idName) == \(CDConversation.queryIdSpecifier)", conversation.id ?? -1)
                var threadEntity = try context.fetch(req).first
                if threadEntity == nil {
                    threadEntity = CDConversation.insertEntity(context)
                    threadEntity?.update(conversation)
                }
                forwardInfoEntity.conversation = threadEntity
            }
            entity.forwardInfo = forwardInfoEntity
        }
    }

    func insertOrUpdateConversation(_ threadModel: Conversation, _ context: NSManagedObjectContextProtocol) throws -> CDConversation? {
        let req = CDConversation.fetchRequest()
        req.predicate = NSPredicate(format: "\(CDConversation.idName) == \(CDConversation.queryIdSpecifier)", threadModel.id ?? -1)
        var threadEntity = try context.fetch(req).first
        if threadEntity == nil {
            threadEntity = CDConversation.insertEntity(context)
            threadEntity?.update(threadModel)
        }
        return threadEntity
    }

    public override func insert(models: [Entity.Model]) {
        insertObjects() { [weak self] context in
            if let threadModel = models.first?.conversation {
                let threadEntity = try self?.insertOrUpdateConversation(threadModel, context)
                try models.forEach { model in
                    if model.id == threadEntity?.lastMessageVO?.id?.intValue {
                        threadEntity?.lastMessageVO?.update(model)
                    } else {
                        let entity = Entity.insertEntity(context)
                        entity.update(model)
                        entity.conversation = threadEntity
                        threadEntity?.lastMessageVO = entity
                        try self?.updateRelations(entity, model, context: context)
                    }
                }
            }
        }
    }

    public func delete(_ threadId: Int?, _ messageId: Int?) {
        let predicate = predicate(threadId, messageId)
        batchDelete(predicate: predicate)
    }

    public func delete(_ messageId: Int?) {
        let predicate = idPredicate(id: messageId ?? -1)
        batchDelete(predicate: predicate)
    }

    public func pin(_ pin: Bool, _ threadId: Int?, _ messageId: Int?) {
        let predicate = predicate(threadId, messageId)
        let propertiesToUpdate = ["pinned": NSNumber(booleanLiteral: pin)]
        update(propertiesToUpdate, predicate)
    }

    /// Set seen only for prior messages where the owner of the message is not me.
    /// We should do that because we need to distinguish between messages that came from the partner or messages sent by myself.
    /// Also we should set delivered to true because when we have seen a message for 100% we have received the message as well.
    /// Also we need to set lastSeenMessageId and time and nano time in the conversation entity to keep it synced.
    public func seen(threadId: Int, messageId: Int, userId: Int) {
        let predicate = NSPredicate(format: "threadId == %i AND \(Entity.idName) <= \(Entity.queryIdSpecifier) AND (seen = nil OR seen == NO) AND ownerId != %i", threadId, messageId, userId)
        let propertiesToUpdate = ["seen": NSNumber(booleanLiteral: true), "delivered": NSNumber(booleanLiteral: true)]
        update(propertiesToUpdate, predicate)
        let cmConversation = CacheConversationManager(container: container, logger: logger)
        cmConversation.seen(threadId: threadId, messageId: messageId)
    }

    // We don't join with the conversation.id because it leads to a crash when batch updating due to lack of relation update query support in a predicate in batch mode.
    public func predicate(_ threadId: Int?, _ messageId: Int?) -> NSPredicate {
        let threadId = threadId ?? -1
        let messageId = messageId ?? -1
        return NSPredicate(format: "threadId == \(CDConversation.queryIdSpecifier) AND \(Entity.idName) == \(Entity.queryIdSpecifier)", threadId, messageId)
    }

    public func joinPredicate(_ threadId: Int?, _ messageId: Int?) -> NSPredicate {
        let threadId = threadId ?? -1
        let messageId = messageId ?? -1
        return NSPredicate(format: "(conversation.id == \(CDConversation.queryIdSpecifier) OR threadId == \(CDConversation.queryIdSpecifier)) AND \(Entity.idName) == \(Entity.queryIdSpecifier)", threadId, threadId, messageId)
    }

    public func partnerDeliver(threadId: Int, messageId: Int, messageTime: UInt = 0) {
        let predicate = NSPredicate(format: "threadId == \(CDConversation.queryIdSpecifier) AND \(Entity.idName) <= \(Entity.queryIdSpecifier) AND (delivered = nil OR delivered == NO)", threadId, messageId)
        let propertiesToUpdate = ["delivered": NSNumber(booleanLiteral: true)]
        update(propertiesToUpdate, predicate)
        let cm = CacheConversationManager(container: container, logger: logger)
        cm.partnerDeliver(threadId: threadId, messageId: messageId, messageTime: messageTime)
    }

    public func partnerSeen(threadId: Int, messageId: Int) {
        let predicate = NSPredicate(format: "threadId == \(CDConversation.queryIdSpecifier) AND \(Entity.idName) <= \(Entity.queryIdSpecifier) AND (seen = nil OR seen == NO)", threadId, messageId)
        let propertiesToUpdate = ["seen": NSNumber(booleanLiteral: true), "delivered": NSNumber(booleanLiteral: true)]
        update(propertiesToUpdate, predicate)
        let cm = CacheConversationManager(container: container, logger: logger)
        cm.partnerSeen(threadId: threadId, messageId: messageId)
    }

    public func predicateArray(_ req: FetchMessagesRequest) -> NSCompoundPredicate {
        var predicateArray = [NSPredicate]()
        predicateArray.append(NSPredicate(format: "threadId == \(CDConversation.queryIdSpecifier)", req.threadId))
        if let messageId = req.messageId {
            predicateArray.append(NSPredicate(format: "\(Entity.idName) == \(Entity.queryIdSpecifier)", messageId))
        }
        if let uniqueIds = req.uniqueIds {
            predicateArray.append(NSPredicate(format: "uniqueId IN %@", uniqueIds))
        }
        if let formTime = req.fromTime as? NSNumber {
            predicateArray.append(NSPredicate(format: "time >= %@", formTime))
        }
        if let toTime = req.toTime as? NSNumber {
            predicateArray.append(NSPredicate(format: "time <= %@", toTime))
        }
        if let query = req.query, query != "" {
            predicateArray.append(NSPredicate(format: "message CONTAINS[cd] %@", query))
        }
        if let messageType = req.messageType {
            predicateArray.append(NSPredicate(format: "messageType == %i", messageType))
        }
        return NSCompoundPredicate(type: .and, subpredicates: predicateArray)
    }

    public func find(_ threadId: Int?, _ messageId: Int?, _ completion: @escaping (Entity?) -> Void) {
        viewContext.perform {
            let req = Entity.fetchRequest()
            req.predicate = self.joinPredicate(threadId, messageId)
            let message = try self.viewContext.fetch(req).first
            completion(message)
        }
    }

    public func fecthMessage(threadId: Int?, messageId: Int?) throws -> Entity? {
        let req = Entity.fetchRequest()
        req.predicate = predicate(threadId, messageId)
        return try viewContext.fetch(req).first
    }

    public func fetch(_ req: FetchMessagesRequest, _ completion: @escaping ([Entity], Int) -> Void) {
        viewContext.perform {
            let fetchRequest = Entity.fetchRequest()
            let sortByTime = NSSortDescriptor(key: "time", ascending: (req.order == Ordering.asc.rawValue) ? true : false)
            fetchRequest.sortDescriptors = [sortByTime]
            fetchRequest.predicate = self.predicateArray(req)
            let totalCount = (try? self.viewContext.count(for: fetchRequest)) ?? 0
            fetchRequest.fetchOffset = req.offset
            fetchRequest.fetchLimit = req.count
            let messages = (try? self.viewContext.fetch(fetchRequest)) ?? []
            completion(messages, totalCount)
        }
    }

    public func getMentions(threadId: Int, offset: Int = 0, count: Int = 25, _ completion: @escaping ([Entity], Int) -> Void) {
        let predicate = NSPredicate(format: "threadId == \(CDConversation.queryIdSpecifier)", threadId)
        fetchWithOffset(count: count, offset: offset, predicate: predicate, completion)
    }

    public func clearHistory(threadId: Int?) {
        let predicate = NSPredicate(format: "threadId == \(CDConversation.queryIdSpecifier)", threadId ?? -1)
        batchDelete(predicate: predicate)
    }

    public func findOrCreate(threadId: Int, message: Message, context: NSManagedObjectContext) -> CDMessage {
        let req = CDMessage.fetchRequest()
        req.predicate = joinPredicate(threadId, message.id ?? -1)
        var entity = try? context.fetch(req).first
        if entity == nil {
            entity = CDMessage.insertEntity(context)
            entity?.update(message)
        }
        return entity!
    }
}
