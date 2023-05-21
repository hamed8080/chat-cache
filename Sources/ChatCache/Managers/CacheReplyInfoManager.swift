//
// CacheReplyInfoManager.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation
import ChatModels

public final class CacheReplyInfoManager: CoreDataProtocol {
    public typealias Entity = CDReplyInfo
    public var context: NSManagedObjectContext
    public let logger: CacheLogDelegate

    required public init(context: NSManagedObjectContext, logger: CacheLogDelegate) {
        self.context = context
        self.logger = logger
    }

    public func insert(model: Entity.Model) {
        let entity = Entity.insertEntity(context)
        entity.update(model)

        if let participant = model.participant, let thread = model.participant?.conversation {
            CacheConversationManager(context: context, logger: logger).findOrCreateEntity(thread.id) { threadEntity in
                threadEntity?.update(thread)
                CacheParticipantManager(context: self.context, logger: self.logger).findOrCreateEntity(thread.id, participant.id) { participantEntity in
                    participantEntity?.update(participant)
                    participantEntity?.conversation = threadEntity
                    entity.participant = participantEntity
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
    
    public func first(_ participantId: Int?, _ repliedToMessageId: Int?, _ completion: @escaping (Entity?) -> Void) {
        context.perform {
            let predicate = NSPredicate(format: "\(CDParticipant.idName) == \(CDParticipant.queryIdSpecifier) AND repliedToMessageId == %i", participantId ?? -1, repliedToMessageId ?? -1)
            let req = Entity.fetchRequest()
            req.predicate = predicate
            req.fetchLimit = 1
            let reply = try self.context.fetch(req).first
            completion(reply)
        }
    }

    public func findOrCreate(_ participantId: Int?, _ replyToMessageId: Int?, _ completion: @escaping (Entity?) -> Void) {
        first(participantId, replyToMessageId) { message in
            completion(message ?? Entity.insertEntity(self.context))
        }
    }
}
