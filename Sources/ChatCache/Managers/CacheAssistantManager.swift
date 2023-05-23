//
// CacheAssistantManager.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation
import ChatModels

public final class CacheAssistantManager: BaseCoreDataManager<CDAssistant> {

    public func block(block: Bool, assistants: [Entity.Model]) {
        let predicate = NSPredicate(format: "\(Entity.idName) IN == @i", assistants.compactMap { $0.participant?.id as? NSNumber })
        let propertiesToUpdate = ["block": block as NSNumber]
        update(propertiesToUpdate, predicate)
    }

    public func getBlocked(_ count: Int?, _ offset: Int?, _ completion: @escaping ([Entity], Int) -> Void) {
        let predicate = NSPredicate(format: "block == %@", NSNumber(booleanLiteral: true))
        fetchWithOffset(entityName: Entity.name, count: count, offset: offset, predicate: predicate, completion)
    }

    public func delete(_ models: [Entity.Model]) {
        let predicate = NSPredicate(format: "\(Entity.idName) IN == @i", models.compactMap { $0.id as? NSNumber })
        batchDelete(entityName: Entity.name, predicate: predicate)
    }

    public func fetch(_ count: Int = 25, _ offset: Int = 0, _ completion: @escaping ([Entity], Int) -> Void) {
        let fetchRequest = Entity.fetchRequest()
        viewContext.perform {
            let threads = try self.viewContext.fetch(fetchRequest)
            fetchRequest.fetchLimit = count
            fetchRequest.fetchOffset = offset
            let count = try self.viewContext.count(for: fetchRequest)
            completion(threads, count)
        }
    }
}
