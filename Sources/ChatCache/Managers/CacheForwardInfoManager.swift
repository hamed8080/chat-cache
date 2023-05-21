//
// CacheForwardInfoManager.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation
import ChatModels

public final class CacheForwardInfoManager: CoreDataProtocol {
    public typealias Entity = CDForwardInfo
    public var context: NSManagedObjectContext
    public let logger: CacheLogDelegate

    required public init(context: NSManagedObjectContext, logger: CacheLogDelegate) {
        self.context = context
        self.logger = logger
    }

    public func insert(model: Entity.Model) {
        let entity = Entity.insertEntity(context)
        if let participant = model.participant, let thread = model.conversation {
            CacheConversationManager(context: context, logger: logger).findOrCreateEntity(model.conversation?.id) { threadEntity in
                threadEntity?.update(thread)
                CacheParticipantManager(context: self.context, logger: self.logger).findOrCreateEntity(model.conversation?.id, participant.id) { participantEntity in
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
}
