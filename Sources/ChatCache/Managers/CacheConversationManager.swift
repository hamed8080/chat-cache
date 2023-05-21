//
// CacheConversationManager.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation
import ChatModels

public final class CacheConversationManager: CoreDataProtocol {
    public typealias Entity = CDConversation
    public var context: NSManagedObjectContext
    public let logger: CacheLogDelegate

    required public init(context: NSManagedObjectContext, logger: CacheLogDelegate) {
        self.context = context
        self.logger = logger
    }

    public func insert(model: Entity.Model) {
        do {
            let req = Entity.fetchRequest()
            req.predicate = NSPredicate(format: "\(Entity.idName) == \(Entity.queryIdSpecifier)", model.id ?? -1)
            var entity = try context.fetch(req).first
            if entity == nil {
                entity = Entity.insertEntity(context)
            }
            entity?.update(model)

            if let lastMessageVO = model.lastMessageVO {
                let req = CDMessage.fetchRequest()
                req.predicate = NSPredicate(format: "conversation.\(CDConversation.idName) == \(Entity.queryIdSpecifier) AND \(CDMessage.idName) == \(Entity.queryIdSpecifier)", model.id ?? -1, lastMessageVO.id ?? -1)
                var messageEntity = try context.fetch(req).first
                if messageEntity == nil {
                    messageEntity = CDMessage.insertEntity(context)
                    messageEntity?.update(lastMessageVO)
                }
                messageEntity?.conversation = entity
                messageEntity?.threadId = model.id as? NSNumber
                entity?.lastMessageVO = messageEntity

                if let participant = model.lastMessageVO?.participant {
                    let participantReq = CDParticipant.fetchRequest()
                    participantReq.predicate = NSPredicate(format: "conversation.\(CDConversation.idName) == \(Entity.queryIdSpecifier) AND \(CDParticipant.idName) == \(Entity.queryIdSpecifier)", model.id ?? -1, participant.id ?? -1)
                    var participantEntity = try context.fetch(participantReq).first
                    if participantEntity == nil {
                        participantEntity = CDParticipant.insertEntity(context)
                        participantEntity?.update(participant)
                    }
                    participantEntity?.conversation = entity
                    messageEntity?.participant = participantEntity
                }
            }

            model.pinMessages?.forEach { pinMessage in
                let pinMessageEntity = CDMessage.insertEntity(context)
                pinMessageEntity.update(pinMessage)
                pinMessageEntity.pinned = true
                pinMessageEntity.threadId = entity?.id
                pinMessageEntity.conversation = entity
                entity?.addToPinMessages(pinMessageEntity)
            }
        } catch {
            logger.log(message: error.localizedDescription, persist: true, error: nil)
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

    public func seen(threadId: Int, messageId: Int) {
        let predicate = idPredicate(id: threadId)
        let propertiesToUpdate = [
            "lastSeenMessageId": (messageId) as NSNumber,
            "lastSeenMessageTime": (Date().timeIntervalSince1970) as NSNumber,
            "lastSeenMessageNanos": (Date().timeIntervalSince1970) as NSNumber,
        ]
        update(propertiesToUpdate, predicate)
    }

    public func partnerDeliver(threadId: Int, messageId: Int, messageTime: UInt) {
        let predicate = idPredicate(id: threadId)
        let propertiesToUpdate: [String: Any] = [
            "partnerLastDeliveredMessageTime": messageTime,
            "partnerLastDeliveredMessageNanos": messageTime,
            "partnerLastDeliveredMessageId": messageId,
        ]
        update(propertiesToUpdate, predicate)
    }

    public func partnerSeen(threadId: Int, messageId: Int, messageTime: Int = 0) {
        let predicate = idPredicate(id: threadId)
        let propertiesToUpdate: [String: Any] = [
            "partnerLastSeenMessageTime": messageTime,
            "partnerLastSeenMessageNanos": messageTime,
            "partnerLastSeenMessageId": messageId,
            "partnerLastDeliveredMessageTime": messageTime,
            "partnerLastDeliveredMessageNanos": messageTime,
            "partnerLastDeliveredMessageId": messageId,
        ]
        update(propertiesToUpdate, predicate)
    }

    public func increamentUnreadCount(_ threadId: Int, _ completion: ((Int) -> Void)? = nil) {
        first(with: threadId) { entity in
            let unreadCount = (entity?.unreadCount?.intValue ?? 0) + 1
            self.update(["unreadCount": unreadCount], self.idPredicate(id: threadId))
            completion?(unreadCount)
        }
    }

    public func decreamentUnreadCount(_ threadId: Int, _ completion: ((Int) -> Void)? = nil) {
        first(with: threadId) { entity in
            let dbCount = entity?.unreadCount?.intValue ?? 0
            let decreamentCount = max(0, dbCount - 1)
            self.update(["unreadCount": decreamentCount], self.idPredicate(id: threadId))
            completion?(decreamentCount)
        }
    }

    public func setUnreadCountToZero(_ threadId: Int, _ completion: ((Int) -> Void)? = nil) {
        context.perform {
            self.update(["unreadCount": 0], self.idPredicate(id: threadId))
            completion?(0)
        }
    }

    public func fetch(_ req: FetchThreadRequest, _ completion: @escaping ([Entity], Int) -> Void) {
        let fetchRequest = Entity.fetchRequest()
        fetchRequest.fetchLimit = req.count
        fetchRequest.fetchOffset = req.offset
        var orFetchPredicatArray = [NSPredicate]()
        if let name = req.name, name != "" {
            let searchTitle = NSPredicate(format: "title CONTAINS[cd] %@", name)
            let searchDescriptions = NSPredicate(format: "descriptions CONTAINS[cd] %@", name)
            orFetchPredicatArray.append(searchTitle)
            orFetchPredicatArray.append(searchDescriptions)
        }

        if let threadIds = req.threadIds, threadIds.count > 0 {
            orFetchPredicatArray.append(NSPredicate(format: "\(Entity.idName) IN %@", threadIds))
        }

        if let isGroup = req.isGroup {
            let groupPredicate = NSPredicate(format: "group == %@", NSNumber(value: isGroup))
            orFetchPredicatArray.append(groupPredicate)
        }

        if let type = req.type {
            let thtreadTypePredicate = NSPredicate(format: "type == %i", type)
            orFetchPredicatArray.append(thtreadTypePredicate)
        }

        let archivePredicate = NSPredicate(format: "isArchive == %@", NSNumber(value: req.archived ?? false))
        orFetchPredicatArray.append(archivePredicate)
        let orCompound = NSCompoundPredicate(type: .and, subpredicates: orFetchPredicatArray)
        fetchRequest.predicate = orCompound

        let sortByTime = NSSortDescriptor(key: "time", ascending: false)
        let sortByPin = NSSortDescriptor(key: "pin", ascending: false)
        fetchRequest.sortDescriptors = [sortByPin, sortByTime]
        fetchRequest.relationshipKeyPathsForPrefetching = ["lastMessageVO"]
        context.perform {
            let threads = try self.context.fetch(fetchRequest)
            fetchRequest.fetchLimit = 0
            fetchRequest.fetchOffset = 0
            let count = try self.context.count(for: fetchRequest)
            completion(threads, count)
        }
    }

    public func fetchIds(_ completion: @escaping ([Int]) -> Void) {
        let req = NSFetchRequest<NSDictionary>(entityName: Entity.name)
        req.resultType = .dictionaryResultType
        req.propertiesToFetch = [Entity.idName]
        context.perform {
            let dic = try? self.context.fetch(req)
            let threadIds = dic?.flatMap(\.allValues).compactMap { $0 as? Int }
            completion(threadIds ?? [])
        }
    }

    public func archive(_ archive: Bool, _ threadId: Int?) {
        let predicate = idPredicate(id: threadId ?? -1)
        let propertiesToUpdate: [String: Any] = ["isArchive": NSNumber(booleanLiteral: archive)]
        update(propertiesToUpdate, predicate)
    }

    public func close(_ close: Bool, _ threadId: Int?) {
        let predicate = idPredicate(id: threadId ?? -1)
        let propertiesToUpdate: [String: Any] = ["closedThread": NSNumber(booleanLiteral: close)]
        update(propertiesToUpdate, predicate)
    }

    public func mute(_ mute: Bool, _ threadId: Int?) {
        let predicate = idPredicate(id: threadId ?? -1)
        let propertiesToUpdate: [String: Any] = ["mute": NSNumber(booleanLiteral: mute)]
        update(propertiesToUpdate, predicate)
    }

    public func pin(_ pin: Bool, _ threadId: Int?) {
        let predicate = idPredicate(id: threadId ?? -1)
        let propertiesToUpdate: [String: Any] = ["pin": NSNumber(booleanLiteral: pin)]
        update(propertiesToUpdate, predicate)
    }

    public func updateLastMessage(_ thread: Entity.Model) {
        first(with: thread.id ?? -1) { entity in
            entity?.lastMessage = thread.lastMessage
            if let lastMessageVO = thread.lastMessageVO {
                entity?.lastMessageVO?.update(lastMessageVO)
            }
        }
    }

    public func updateLastMessage(_ threadId: Int?, _ text: String) {
        let predicate = idPredicate(id: threadId ?? -1)
        let propertiesToUpdate: [String: Any] = ["lastMessage": text]
        update(propertiesToUpdate, predicate)
    }

    public func setLastMessageVO(_ message: Message) {
        let threadId = message.threadId ?? -1
        let messageId = message.id ?? -1
        let req = Entity.fetchRequest()
        req.predicate = idPredicate(id: threadId)
        let messageReq = CDMessage.fetchRequest()
        messageReq.predicate = NSPredicate(format: "conversation.\(CDConversation.idName) == \(Entity.queryIdSpecifier) AND \(CDMessage.idName) == \(Entity.queryIdSpecifier)", threadId, messageId)
        context.perform {
            if let threadEntity = try self.context.fetch(req).first, let messageEntity = try self.context.fetch(messageReq).first {
                threadEntity.lastMessageVO = messageEntity
                threadEntity.lastMessage = messageEntity.message
                messageEntity.message = message.message
                self.save()
            }
        }
    }

    public func changeThreadType(_ thread: Entity.Model?) {
        let predicate = idPredicate(id: thread?.id ?? -1)
        let propertiesToUpdate: [String: Any] = ["type": thread?.type?.rawValue ?? -1]
        update(propertiesToUpdate, predicate)
    }

    public func allUnreadCount(_ completion: @escaping (Int) -> Void) {
        context.perform {
            let col = NSExpression(forKeyPath: "unreadCount")
            let exp = NSExpression(forFunction: "sum:", arguments: [col])
            let sumDesc = NSExpressionDescription()
            sumDesc.expression = exp
            sumDesc.name = "sum"
            sumDesc.expressionResultType = .integer64AttributeType
            let req = NSFetchRequest<NSDictionary>(entityName: Entity.name)
            req.propertiesToFetch = [sumDesc]
            req.returnsObjectsAsFaults = false
            req.resultType = .dictionaryResultType
            let dic = try self.context.fetch(req).first as? [String: Int]
            let allUnreadCount = dic?["sum"] ?? 0
            completion(allUnreadCount)
        }
    }

    public func delete(_ threadId: Int) {
        let predicate = idPredicate(id: threadId)
        batchDelete(context, entityName: Entity.name, predicate: predicate)
    }

    public func updateThreadsUnreadCount(_ resp: [String: Int]) {
        resp.forEach { key, value in
            let predicate = idPredicate(id: Int(key) ?? -1)
            update(["unreadCount": value], predicate)
        }
    }

    public func threadsUnreadcount(_ threadIds: [Int], _ completion: @escaping ([String: Int]) -> Void) {
        let req = NSFetchRequest<NSDictionary>(entityName: Entity.name)
        req.resultType = .dictionaryResultType
        req.propertiesToFetch = ["id", "unreadCount"]
        req.predicate = NSPredicate(format: "\(Entity.idName) IN %@", threadIds)
        context.perform {
            let rows = try? self.context.fetch(req)
            var result: [String: Int] = [:]
            rows?.forEach { dic in
                var threadId = 0
                var unreadCount = 0
                dic.forEach { key, value in
                    if key as? String == Entity.idName {
                        threadId = value as? Int ?? 0
                    } else if key as? String == "unreadCount" {
                        unreadCount = value as? Int ?? 0
                    }
                }
                result[String(threadId)] = unreadCount
            }
            completion(result)
        }
    }

    func findOrCreateEntity(_ threadId: Int?, _ completion: @escaping (Entity?) -> Void) {
        first(with: threadId ?? -1) { thread in
            completion(thread ?? Entity.insertEntity(self.context))
        }
    }
}
