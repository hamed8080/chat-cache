//
// CacheForwardInfoManager.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation
import ChatModels

public final class CacheForwardInfoManager: BaseCoreDataManager<CDForwardInfo> {
    public override func insert(model: Entity.Model, context: NSManagedObjectContextProtocol) {
        let entity = Entity.insertEntity(context)
        if let participant = model.participant, let thread = model.conversation, let threadId = thread.id {
            let cmThread = BaseCoreDataManager<CDConversation>(container: container, logger: logger)
            let threadEntity: CDConversation = cmThread.findOrCreate(threadId, context)
            threadEntity.update(thread)
            CacheParticipantManager(container: self.container, logger: self.logger).findOrCreateEntity(model.conversation?.id, participant.id) { participantEntity in
                participantEntity?.update(participant)
                participantEntity?.conversation = threadEntity
                entity.participant = participantEntity
            }
        }
    }
}
