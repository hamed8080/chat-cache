//
// CacheAssistantManager.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation
import ChatModels

public final class CacheAssistantManager: CoreDataProtocol {
    public typealias Entity = CDAssistant
    public var context: NSManagedObjectContext
    public let logger: CacheLogDelegate

    required public init(context: NSManagedObjectContext, logger: CacheLogDelegate) {
        self.context = context
        self.logger = logger
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
        batchDelete(context, entityName: Entity.name, predicate: predicate)
    }

    public func fetch(_ count: Int = 25, _ offset: Int = 0, _ completion: @escaping ([Entity], Int) -> Void) {
        let fetchRequest = Entity.fetchRequest()
        context.perform {
            let threads = try self.context.fetch(fetchRequest)
            fetchRequest.fetchLimit = count
            fetchRequest.fetchOffset = offset
            let count = try self.context.count(for: fetchRequest)
            completion(threads, count)
        }
    }
}
