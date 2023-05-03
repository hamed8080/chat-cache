//
// CacheCoreDataFileManager.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation
import ChatModels

public final class CacheCoreDataFileManager: CoreDataProtocol {
    let idName = "hashCode"
    var context: NSManagedObjectContext
    let logger: CacheLogDelegate

    required init(context: NSManagedObjectContext, logger: CacheLogDelegate) {
        self.context = context
        self.logger = logger
    }

    func insert(model: File) {
        let entity = CDFile.insertEntity(context)
        entity.update(model)
    }

    public func insert(models: [File]) {
        insertObjects(context) { [weak self] _ in
            models.forEach { model in
                self?.insert(model: model)
            }
        }
    }

    func idPredicate(id: String) -> NSPredicate {
        NSPredicate(format: "\(idName) == %@", id)
    }

    public func first(with id: String, _ completion: @escaping (CDFile?) -> Void) {
        context.perform {
            let req = CDFile.fetchRequest()
            req.predicate = self.idPredicate(id: id)
            let file = try self.context.fetch(req).first
            completion(file)
        }
    }

    public func find(predicate: NSPredicate, _ completion: @escaping ([CDFile]) -> Void) {
        context.perform {
            let req = CDFile.fetchRequest()
            req.predicate = predicate
            let files = try self.context.fetch(req)
            completion(files)
        }
    }

    func update(model _: File, entity _: CDFile) {}

    func update(models _: [File]) {}

    public func update(_ propertiesToUpdate: [String: Any], _ predicate: NSPredicate) {
        // batch update request
        batchUpdate(context) { bgTask in
            let batchRequest = NSBatchUpdateRequest(entityName: CDFile.entityName)
            batchRequest.predicate = predicate
            batchRequest.propertiesToUpdate = propertiesToUpdate
            batchRequest.resultType = .updatedObjectIDsResultType
            _ = try? bgTask.execute(batchRequest)
        }
    }

    func delete(entity _: CDFile) {}
}
