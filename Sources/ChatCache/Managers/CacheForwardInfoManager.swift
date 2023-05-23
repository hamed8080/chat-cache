//
// CacheForwardInfoManager.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation
import ChatModels

public final class CacheForwardInfoManager: BaseCoreDataManager<CDForwardInfo> {
    public override func insert(model: Entity.Model, context: NSManagedObjectContext) {
        let entity = Entity.insertEntity(context)
        if let participant = model.participant, let thread = model.conversation {
            CacheConversationManager(container: container, logger: logger).findOrCreateEntity(model.conversation?.id, context) { threadEntity in
                threadEntity?.update(thread)
                CacheParticipantManager(container: self.container, logger: self.logger).findOrCreateEntity(model.conversation?.id, participant.id) { participantEntity in
                    participantEntity?.update(participant)
                    participantEntity?.conversation = threadEntity
                    entity.participant = participantEntity
                }
            }
        }
    }
}
