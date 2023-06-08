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
    init(container: PersistentManagerProtocol, logger: CacheLogDelegate)
    var container: PersistentManagerProtocol { get set }
    var viewContext: NSManagedObjectContextProtocol { get }
    var bgContext: NSManagedObjectContextProtocol { get }
    var logger: CacheLogDelegate { get }
    func idPredicate(id: Entity.Id) -> NSPredicate
    func save(context: NSManagedObjectContextProtocol)
    func saveViewContext()
    func first(with id: Entity.Id, context: NSManagedObjectContextProtocol, completion: @escaping (Entity?) -> Void)
    func find(predicate: NSPredicate, completion: @escaping ([Entity]) -> Void)
    func insert(model: Entity.Model, context: NSManagedObjectContextProtocol)
    func insert(models: [Entity.Model])
    func delete(entity: Entity)
    func update(model: Entity.Model, entity: Entity)
    func update(_ propertiesToUpdate: [String: Any], _ predicate: NSPredicate)
    func mergeChanges(key: String, _ objectIDs: [NSManagedObjectID])
    func insertObjects(_ makeEntities: @escaping ((NSManagedObjectContextProtocol) throws -> Void))
    func batchUpdate(_ updateObjects: @escaping (NSManagedObjectContextProtocol) -> Void)
    func batchDelete(_ ids: [Int])
    func batchDelete(predicate: NSPredicate)
    func fetchWithOffset(count: Int?, offset: Int?, predicate: NSPredicate?, sortDescriptor: [NSSortDescriptor]?, _ completion: @escaping ([Entity], Int) -> Void)
    func all(_ completion: @escaping ([Entity]) -> Void)
    func fetchWithObjectIds(ids: [NSManagedObjectID], _ completion: @escaping ([Entity]) -> Void)
    func findOrCreate<T: EntityProtocol>(_ id: Entity.Id, _ completion: @escaping (T) -> Void)
}

/// Optional Implementations.
public extension CoreDataProtocol {
    func update(model: Entity.Model, entity: Entity) {}
    func update(models: [Entity.Model]) {}
    func delete(entity: Entity) {}
}
