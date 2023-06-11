//
// CacheReplyInfoManager.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation
import ChatModels

public final class CacheReplyInfoManager: BaseCoreDataManager<CDReplyInfo> {

    public override func insert(model: Entity.Model, context: NSManagedObjectContextProtocol) {
        let entity = Entity.insertEntity(context)
        entity.update(model)

        if let participant = model.participant, let thread = model.participant?.conversation {
            let cmThread = BaseCoreDataManager<CDConversation>(container: container, logger: logger)
            let threadEntity: CDConversation = cmThread.findOrCreate(thread.id ?? -1, context)
            threadEntity.update(thread)
            CacheParticipantManager(container: self.container, logger: self.logger).findOrCreateEntity(thread.id, participant.id) { participantEntity in
                participantEntity?.update(participant)
                participantEntity?.conversation = threadEntity
                entity.participant = participantEntity
            }
        }
    }

    public func first(_ participantId: Int?, _ repliedToMessageId: Int?, _ completion: @escaping (Entity?) -> Void) {
        viewContext.perform {
            let predicate = NSPredicate(format: "\(CDParticipant.idName) == \(CDParticipant.queryIdSpecifier) AND repliedToMessageId == %i", participantId ?? -1, repliedToMessageId ?? -1)
            let req = Entity.fetchRequest()
            req.predicate = predicate
            req.fetchLimit = 1
            let reply = try self.viewContext.fetch(req).first
            completion(reply)
        }
    }

    public func findOrCreate(_ participantId: Int?, _ replyToMessageId: Int?, _ completion: @escaping (Entity?) -> Void) {
        first(participantId, replyToMessageId) { message in
            completion(message ?? Entity.insertEntity(self.viewContext))
        }
    }
}
