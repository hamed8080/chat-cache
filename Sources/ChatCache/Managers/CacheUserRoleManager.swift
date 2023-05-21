//
// CacheUserRoleManager.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation
import ChatModels

public final class CacheUserRoleManager: CoreDataProtocol {
    public typealias Entity = CDUserRole
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

    public func roles(_ threadId: Int) -> [Roles] {
        let req = Entity.fetchRequest()
        req.predicate = NSPredicate(format: "threadId == \(CDConversation.queryIdSpecifier)", threadId)
        let roles = (try? context.fetch(req))?.first?.codable.roles
        return roles ?? []
    }
}
