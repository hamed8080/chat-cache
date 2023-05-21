//
// CacheContactManager.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation
import ChatModels

public final class CacheContactManager: CoreDataProtocol {
    public typealias Entity = CDContact
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

    public func delete(_ id: Int) {
        batchDelete(context, entityName: Entity.name, predicate: idPredicate(id: id))
    }

    public func block(_ block: Bool, _ threadId: Int?) {
        let predicate = idPredicate(id: threadId ?? -1)
        let propertiesToUpdate: [String: Any] = ["blocked": block]
        update(propertiesToUpdate, predicate)
    }

    public func getContacts(_ req: FetchContactsRequest, _ completion: @escaping ([Entity], Int) -> Void) {
        let fetchRequest = Entity.fetchRequest()
        let ascending = req.order != Ordering.desc.rawValue
        if let id = req.id {
            fetchRequest.predicate = NSPredicate(format: "\(Entity.idName) == \(Entity.queryIdSpecifier)", id)
        } else if let uniqueId = req.uniqueId {
            fetchRequest.predicate = NSPredicate(format: "uniqueId == %@", uniqueId)
        } else {
            var andPredicateArr = [NSPredicate]()

            if let cellphoneNumber = req.cellphoneNumber, cellphoneNumber != "" {
                andPredicateArr.append(NSPredicate(format: "cellphoneNumber CONTAINS[cd] %@", cellphoneNumber))
            }
            if let email = req.email, email != "" {
                andPredicateArr.append(NSPredicate(format: "email CONTAINS[cd] %@", email))
            }

            var orPredicatArray = [NSPredicate]()

            if andPredicateArr.count > 0 {
                orPredicatArray.append(NSCompoundPredicate(type: .and, subpredicates: andPredicateArr))
            }

            if let query = req.query, query != "" {
                let theSearchPredicate = NSPredicate(format: "cellphoneNumber CONTAINS[cd] %@ OR email CONTAINS[cd] %@ OR firstName CONTAINS[cd] %@ OR lastName CONTAINS[cd] %@", query, query, query, query)
                orPredicatArray.append(theSearchPredicate)
            }

            if orPredicatArray.count > 0 {
                fetchRequest.predicate = NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.or, subpredicates: orPredicatArray)
            }
        }

        let firstNameSort = NSSortDescriptor(key: "firstName", ascending: ascending)
        let lastNameSort = NSSortDescriptor(key: "lastName", ascending: ascending)
        fetchRequest.sortDescriptors = [lastNameSort, firstNameSort]
        context.perform {
            let count = try? self.context.count(for: Entity.fetchRequest())
            fetchRequest.fetchLimit = req.size
            fetchRequest.fetchOffset = req.offset
            let contacts = try self.context.fetch(fetchRequest)
            completion(contacts, count ?? 0)
        }
    }

    public func allContacts(_ completion: @escaping ([Entity]) -> Void) {
        context.perform {
            let req = Entity.fetchRequest()
            let contacts = try self.context.fetch(req)
            completion(contacts)
        }
    }
}
