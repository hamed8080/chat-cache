//
// CacheConversationManager.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation
import ChatModels

public final class CacheConversationManager: BaseCoreDataManager<CDConversation> {

    public override func insert(model: Entity.Model, context: NSManagedObjectContext) {
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
    
    public func setUnreadCount(action: CacheUnreadCountAction, threadId: Int, completion: ((Int) -> Void)? = nil) {
        first(with: threadId) { entity in
            var cachedThreadCount = entity?.unreadCount?.intValue ?? 0
            switch action {
            case .increase:
                cachedThreadCount += 1
                break
            case .decrease:
                cachedThreadCount = max(0, cachedThreadCount - 1)
                break
            case let .set(count):
                cachedThreadCount = max(0, count)
                break
            }
            self.update(["unreadCount": cachedThreadCount], self.idPredicate(id: threadId))
            completion?(cachedThreadCount)
        }
    }

    public func fetch(_ req: FetchThreadRequest, _ completion: @escaping ([Entity], Int) -> Void) {
        let fetchRequest = Entity.fetchRequest()
        fetchRequest.fetchLimit = req.count
        fetchRequest.fetchOffset = req.offset
        var orFetchPredicatArray = [NSPredicate]()
        if let title = req.title, title != "" {
            let searchTitle = NSPredicate(format: "%K CONTAINS[cd] %@", #keyPath(CDConversation.title), title)
            orFetchPredicatArray.append(searchTitle)
        }

        if let desc = req.description {
            let searchDescriptions = NSPredicate(format: "%K CONTAINS[cd] %@", #keyPath(CDConversation.descriptions) , desc)
            orFetchPredicatArray.append(searchDescriptions)
        }

        if let threadIds = req.threadIds, threadIds.count > 0 {
            orFetchPredicatArray.append(NSPredicate(format: "%K IN %@", #keyPath(CDConversation.id), threadIds))
        }

        if let isGroup = req.isGroup {
            let groupPredicate = NSPredicate(format: "%K == %@", #keyPath(CDConversation.group), NSNumber(value: isGroup))
            orFetchPredicatArray.append(groupPredicate)
        }

        if let type = req.type {
            let thtreadTypePredicate = NSPredicate(format: "%K == %i", #keyPath(CDConversation.type), type)
            orFetchPredicatArray.append(thtreadTypePredicate)
        }

        if let archived = req.archived {
            let keyPath = #keyPath(CDConversation.isArchive)
            let archivePredicate = NSPredicate(format: "%K == %@ OR %K == %@", keyPath, NSNumber(value: archived), keyPath, NSNull())
            orFetchPredicatArray.append(archivePredicate)
        }
        let orCompound = NSCompoundPredicate(type: .and, subpredicates: orFetchPredicatArray)
        fetchRequest.predicate = orCompound

        let sortByTime = NSSortDescriptor(key: "time", ascending: false)
        let sortByPin = NSSortDescriptor(key: "pin", ascending: false)
        fetchRequest.sortDescriptors = [sortByPin, sortByTime]
        fetchRequest.relationshipKeyPathsForPrefetching = ["lastMessageVO"]
        viewContext.perform {
            let threads = try self.viewContext.fetch(fetchRequest)
            fetchRequest.fetchLimit = 0
            fetchRequest.fetchOffset = 0
            let count = try self.viewContext.count(for: fetchRequest)
            completion(threads, count)
        }
    }

    public func fetchIds(_ completion: @escaping ([Int]) -> Void) {
        let req = NSFetchRequest<NSDictionary>(entityName: Entity.name)
        req.resultType = .dictionaryResultType
        req.propertiesToFetch = [Entity.idName]
        viewContext.perform {
            let dic = try self.viewContext.fetch(req)
            let threadIds = dic.flatMap(\.allValues).compactMap { $0 as? Int }
            completion(threadIds)
        }
    }

    public func archive(_ archive: Bool, _ threadId: Int) {
        let predicate = idPredicate(id: threadId)
        let propertiesToUpdate: [String: Any] = ["isArchive": NSNumber(booleanLiteral: archive)]
        update(propertiesToUpdate, predicate)
    }

    public func close(_ close: Bool, _ threadId: Int) {
        let predicate = idPredicate(id: threadId)
        let propertiesToUpdate: [String: Any] = ["closedThread": NSNumber(booleanLiteral: close)]
        update(propertiesToUpdate, predicate)
    }

    public func mute(_ mute: Bool, _ threadId: Int) {
        let predicate = idPredicate(id: threadId)
        let propertiesToUpdate: [String: Any] = ["mute": NSNumber(booleanLiteral: mute)]
        update(propertiesToUpdate, predicate)
    }

    public func pin(_ pin: Bool, _ threadId: Int) {
        let predicate = idPredicate(id: threadId)
        let propertiesToUpdate: [String: Any] = ["pin": NSNumber(booleanLiteral: pin)]
        update(propertiesToUpdate, predicate)
    }


    /// Insert if there is no conversation or message object, and update if there is a message or thread entity.
    public func replaceLastMessage(_ model: Entity.Model) throws {
        guard let threadId = model.id, let lastMessageVO = model.lastMessageVO
        else { throw NSError(domain: "The threadId or LastMessageVO is nil.", code: 0) }
        first(with: threadId) { entity in
            if let entity = entity {
                self.updateLastMessage(entity: entity, lastMessageVO: lastMessageVO)
            } else {
                // Insert
                self.insert(models: [model])
            }
            self.saveViewContext()
        }
    }

    /// We use uniqueId of message to get a message if it the sender were me and if so, in sendMessage method we have added an entity inside message table without an 'Message.id'
    /// and it will lead to problem such as dupicate message row.
    private func updateLastMessage(entity: CDConversation, lastMessageVO: Message) {
        let context = viewContext
        entity.lastMessage = lastMessageVO.message
        let messageReq = CDMessage.fetchRequest()
        messageReq.predicate = NSPredicate(format: "%K == %@ OR %K == %@", #keyPath(CDMessage.id), lastMessageVO.id as? NSNumber ?? -1, #keyPath(CDMessage.uniqueId), lastMessageVO.uniqueId ?? "")
        if let messageEntity = try? context.fetch(messageReq).first {
            messageEntity.update(lastMessageVO)
        } else {
            let insertMessageEntity = CDMessage.insertEntity(context)
            insertMessageEntity.update(lastMessageVO)
            entity.lastMessageVO = insertMessageEntity
        }
    }

    public func changeThreadType(_ threadId: Int, _ type: ThreadTypes) {
        let predicate = idPredicate(id: threadId)
        let propertiesToUpdate: [String: Any] = ["type": type.rawValue]
        update(propertiesToUpdate, predicate)
    }

    public func allUnreadCount(_ completion: @escaping (Int) -> Void) {
        viewContext.perform {
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
            if let dic = try self.viewContext.fetch(req).first as? [String: Int], let sum = dic["sum"] {
                completion(sum)
            } else {
                completion(0)
            }
        }
    }

    public func delete(_ threadId: Int) {
        let predicate = idPredicate(id: threadId)
        batchDelete(predicate: predicate)
    }

    public func updateThreadsUnreadCount(_ resp: [String: Int]) {
        for (key, value) in resp {
            if let threadId = Int(key) {
                setUnreadCount(action: .set(value), threadId: threadId)
            }
        }
    }

    public func threadsUnreadcount(_ threadIds: [Int], _ completion: @escaping ([String: Int]) -> Void) {
        let req = NSFetchRequest<NSDictionary>(entityName: Entity.name)
        req.resultType = .dictionaryResultType
        req.propertiesToFetch = ["id", "unreadCount"]
        req.predicate = NSPredicate(format: "\(Entity.idName) IN %@", threadIds)
        viewContext.perform {
            let rows = try self.viewContext.fetch(req)
            let dictionary: [(String, Int)] = rows.compactMap { dic in
                guard let threadId = dic[Entity.idName] as? Int, let unreadCount = dic["unreadCount"] as? Int else { return nil }
                return (String(threadId), unreadCount)
            }
            let result = dictionary.reduce(into: [:]) { $0[$1.0] = $1.1 }
            completion(result)
        }
    }

    func findOrCreateEntity(_ threadId: Int?, _ context: NSManagedObjectContext, _ completion: @escaping (Entity?) -> Void) {
        first(with: threadId ?? -1, context: context) { thread in
            completion(thread ?? Entity.insertEntity(context))
        }
    }
}
