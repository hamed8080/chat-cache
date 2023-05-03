//
// CacheAssistantManager.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation
import ChatModels

public final class CacheAssistantManager: CoreDataProtocol {
    let idName = "id"
    var context: NSManagedObjectContext
    let logger: CacheLogDelegate

    required init(context: NSManagedObjectContext, logger: CacheLogDelegate) {
        self.context = context
        self.logger = logger
    }

    func insert(model: Assistant) {
        let entity = CDAssistant.insertEntity(context)
        entity.update(model)
    }

    public func insert(models: [Assistant]) {
        insertObjects(context) { [weak self] _ in
            models.forEach { model in
                self?.insert(model: model)
            }
        }
    }

    func idPredicate(id: Int) -> NSPredicate {
        NSPredicate(format: "\(idName) == %i", id)
    }

    func first(with id: Int, _ completion: @escaping (CDAssistant?) -> Void) {
        context.perform {
            let req = CDAssistant.fetchRequest()
            req.predicate = self.idPredicate(id: id)
            let assistant = try self.context.fetch(req).first
            completion(assistant)
        }
    }

    func find(predicate: NSPredicate, _ completion: @escaping ([CDAssistant]) -> Void) {
        context.perform {
            let req = CDAssistant.fetchRequest()
            req.predicate = predicate
            let contacts = try self.context.fetch(req)
            completion(contacts)
        }
    }

    func update(model _: Assistant, entity _: CDAssistant) {}

    func update(models: [Assistant]) {
        let _ = NSPredicate(format: "id IN == @i", models.compactMap { $0.id as? NSNumber })
    }

    public func update(_ propertiesToUpdate: [String: Any], _ predicate: NSPredicate) {
        // batch update request
        batchUpdate(context) { bgTask in
            let batchRequest = NSBatchUpdateRequest(entityName: CDAssistant.entityName)
            batchRequest.predicate = predicate
            batchRequest.propertiesToUpdate = propertiesToUpdate
            batchRequest.resultType = .updatedObjectIDsResultType
            _ = try? bgTask.execute(batchRequest)
        }
    }

    func delete(entity _: CDAssistant) {}

    public func block(block: Bool, assistants: [Assistant]) {
        let predicate = NSPredicate(format: "id IN == @i", assistants.compactMap { $0.participant?.id as? NSNumber })
        let propertiesToUpdate = ["block": block as NSNumber]
        update(propertiesToUpdate, predicate)
    }

    public func getBlocked(_ count: Int?, _ offset: Int?, _ completion: @escaping ([CDAssistant], Int) -> Void) {
        let predicate = NSPredicate(format: "block == %@", NSNumber(booleanLiteral: true))
        fetchWithOffset(entityName: CDAssistant.entityName, count: count, offset: offset, predicate: predicate, completion)
    }

    public func delete(_ models: [Assistant]) {
        let predicate = NSPredicate(format: "id IN == @i", models.compactMap { $0.id as? NSNumber })
        batchDelete(context, entityName: CDAssistant.entityName, predicate: predicate)
    }

    public func fetch(_ count: Int = 25, _ offset: Int = 0, _ completion: @escaping ([CDAssistant], Int) -> Void) {
        let fetchRequest = CDAssistant.fetchRequest()
        context.perform {
            let threads = try self.context.fetch(fetchRequest)
            fetchRequest.fetchLimit = count
            fetchRequest.fetchOffset = offset
            let count = try self.context.count(for: fetchRequest)
            completion(threads, count)
        }
    }
}
