//
// CacheQueueOfEditMessagesManager.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation
import ChatModels

public final class CacheQueueOfEditMessagesManager: BaseCoreDataManager<CDQueueOfEditMessages> {

    public func delete(_ uniqueIds: [String]) {
        let predicate = NSPredicate(format: "uniqueId IN %@", uniqueIds)
        batchDelete(entityName: Entity.name, predicate: predicate)
    }

    public func unsedForThread(_ threadId: Int?, _ count: Int?, _ offset: Int?, _ completion: @escaping ([Entity], Int) -> Void) {
        let threadIdPredicate = NSPredicate(format: "threadId == \(CDConversation.queryIdSpecifier)", threadId ?? -1)
        fetchWithOffset(entityName: Entity.name, count: count, offset: offset, predicate: threadIdPredicate, completion)
    }
}
