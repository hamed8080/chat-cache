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
    init(container: PersistentManager, logger: CacheLogDelegate)
    var container: PersistentManager { get set }
    var viewContext: NSManagedObjectContext { get }
    var bgContext: NSManagedObjectContext { get }
    var logger: CacheLogDelegate { get }
    func idPredicate(id: Entity.Id) -> NSPredicate
    func save(context: NSManagedObjectContext)
    func first(with id: Entity.Id, completion: @escaping (Entity?) -> Void)
    func first(with id: Entity.Id, context: NSManagedObjectContext, completion: @escaping (Entity?) -> Void)
    func find(predicate: NSPredicate, completion: @escaping ([Entity]) -> Void)
    func insert(model: Entity.Model, context: NSManagedObjectContext)
    func insert(models: [Entity.Model])
    func delete(entity: Entity)
    func update(model: Entity.Model, entity: Entity)
    func update(_ propertiesToUpdate: [String: Any], _ predicate: NSPredicate)
    func mergeChanges(key: String, _ objectIDs: [NSManagedObjectID])
    func insertObjects(_ makeEntities: @escaping ((NSManagedObjectContext) throws -> Void))
    func batchUpdate(_ updateObjects: @escaping (NSManagedObjectContext) -> Void)
    func batchDelete(entityName: String, _ ids: [Int])
    func batchDelete(entityName: String, predicate: NSPredicate)
    func fetchWithOffset(entityName: String, count: Int?, offset: Int?, predicate: NSPredicate?, sortDescriptor: [NSSortDescriptor]?, _ completion: @escaping ([Entity], Int) -> Void)
}

/// Optional Implementations.
public extension CoreDataProtocol {
    func update(model: Entity.Model, entity: Entity) {}
    func update(models: [Entity.Model]) {}
    func delete(entity: Entity) {}
}
