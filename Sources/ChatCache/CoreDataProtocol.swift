//
// CoreDataProtocol.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation

public protocol IdProtocol {}
extension Int: IdProtocol {}
extension String: IdProtocol {}

public protocol CacheLogDelegate: AnyObject {
    func log(message: String, persist: Bool, error: Error?)
}

public protocol CoreDataProtocol {
    associatedtype Entity: EntityProtocol
    init(context: NSManagedObjectContext, logger: CacheLogDelegate)
    var context: NSManagedObjectContext { get set }
    var logger: CacheLogDelegate { get }
    func idPredicate(id: Entity.Id) -> NSPredicate
    func save()
    func first(with id: Entity.Id, completion: @escaping (Entity?) -> Void)
    func find(predicate: NSPredicate, completion: @escaping ([Entity]) -> Void)
    func insert(model: Entity.Model)
    func insert(models: [Entity.Model])
    func delete(entity: Entity)
    func update(model: Entity.Model, entity: Entity)
    func update(_ propertiesToUpdate: [String: Any], _ predicate: NSPredicate)
    func mergeChanges(key: String, _ objectIDs: [NSManagedObjectID])
    func insertObjects(_ bgTask: NSManagedObjectContext, _ makeEntities: @escaping ((NSManagedObjectContext) throws -> Void))
    func batchUpdate(_ bgTask: NSManagedObjectContext, _ updateObjects: @escaping (NSManagedObjectContext) -> Void)
    func batchDelete(_ bgTask: NSManagedObjectContext, entityName: String, _ ids: [Int])
    func batchDelete(_ bgTask: NSManagedObjectContext, entityName: String, predicate: NSPredicate)
    func fetchWithOffset(entityName: String, count: Int?, offset: Int?, predicate: NSPredicate?, sortDescriptor: [NSSortDescriptor]?, _ completion: @escaping ([Entity], Int) -> Void)
}

/// Optional Implementations.
public extension CoreDataProtocol {
    func update(model: Entity.Model, entity: Entity) {}
    func update(models: [Entity.Model]) {}
    func delete(entity: Entity) {}
}

public extension CoreDataProtocol {
    func save() {
        if context.hasChanges == true {
            do {
                try context.save()
                context.reset()
                logger.log(message: "saved successfully", persist: false, error: nil)
            } catch {
                let nserror = error as NSError
                logger.log(message: "Error occured in save CoreData: \(nserror)", persist: true, error: nserror)
            }
        } else {
            logger.log(message: "no changes find on context so nothing to save!", persist: false, error: nil)
        }
    }

    func mergeChanges(key: String, _ objectIDs: [NSManagedObjectID]) {
        NSManagedObjectContext.mergeChanges(
            fromRemoteContextSave: [key: objectIDs],
            into: [context]
        )
    }

    func insertObjects(_ bgTask: NSManagedObjectContext, _ makeEntities: @escaping ((NSManagedObjectContext) throws -> Void)) {
        bgTask.perform {
            try makeEntities(bgTask)
            save()
            let insertedObjectIds = bgTask.insertedObjects.map(\.objectID)
            let updatedObjectIds = bgTask.updatedObjects.map(\.objectID)
            mergeChanges(key: NSInsertedObjectsKey, insertedObjectIds)
            // For entities with constraint we the constraint will update not insert, because we use trump policy in bgTask Context.
            mergeChanges(key: NSUpdatedObjectsKey, updatedObjectIds)
        }
    }

    func batchUpdate(_ bgTask: NSManagedObjectContext, _ updateObjects: @escaping (NSManagedObjectContext) -> Void) {
        bgTask.perform {
            updateObjects(bgTask)
            save()
            let updatedObjectIds = bgTask.updatedObjects.map(\.objectID)
            mergeChanges(key: NSUpdatedObjectsKey, updatedObjectIds)
        }
    }

    func batchDelete(_ bgTask: NSManagedObjectContext, entityName: String, _ ids: [Int]) {
        let req = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        req.predicate = NSPredicate(format: "\(Entity.idName) IN %@", ids.map { $0 as NSNumber })
        let request = NSBatchDeleteRequest(fetchRequest: req)
        request.resultType = .resultTypeObjectIDs
        bgTask.perform {
            let deleteResult = try bgTask.execute(request) as? NSBatchDeleteResult
            save()
            mergeChanges(key: NSDeletedObjectsKey, deleteResult?.result as? [NSManagedObjectID] ?? [])
        }
    }

    func batchDelete(_ bgTask: NSManagedObjectContext, entityName: String, predicate: NSPredicate) {
        let req = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        req.predicate = predicate
        let request = NSBatchDeleteRequest(fetchRequest: req)
        request.resultType = .resultTypeObjectIDs
        bgTask.perform {
            let deleteResult = try bgTask.execute(request) as? NSBatchDeleteResult
            save()
            mergeChanges(key: NSDeletedObjectsKey, deleteResult?.result as? [NSManagedObjectID] ?? [])
        }
    }

    func fetchWithOffset(entityName: String, count: Int?, offset: Int?, predicate: NSPredicate? = nil, sortDescriptor: [NSSortDescriptor]? = nil, _ completion: @escaping ([Entity], Int) -> Void) {
        context.perform {
            let req = NSFetchRequest<Entity>(entityName: entityName)
            if let sortDescriptors = sortDescriptor {
                req.sortDescriptors = sortDescriptors
            }
            req.predicate = predicate
            let totalCount = (try? self.context.count(for: req)) ?? 0
            req.fetchLimit = count ?? 50
            req.fetchOffset = offset ?? 0
            let objects = try self.context.fetch(req)
            completion(objects, totalCount)
        }
    }
}


public extension CoreDataProtocol {

    func idPredicate(id: Entity.Id) -> NSPredicate {
        NSPredicate(format: "\(Entity.idName) == \(Entity.queryIdSpecifier)", id as! CVarArg)
    }

    func insert(model: Entity.Model) {
        let entity = Entity.insertEntity(context)
        entity.update(model)
    }

    func insert(models: [Entity.Model]) {
        insertObjects(context) { _ in
            models.forEach { model in
                insert(model: model)
            }
        }
    }

    func first(with id: Entity.Id, completion: @escaping (Entity?) -> Void) {
        context.perform {
            let req = Entity.fetchRequest()
            req.predicate = self.idPredicate(id: id)
            req.fetchLimit = 1
            let entity = try self.context.fetch(req).first
            completion(entity)
        }
    }

    func find(predicate: NSPredicate, completion: @escaping ([Entity]) -> Void) {
        context.perform {
            let req = Entity.fetchRequest()
            req.predicate = predicate
            let userRoles = try self.context.fetch(req)
            completion(userRoles)
        }
    }
}
