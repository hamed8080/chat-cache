//
// CacheUserManager.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation
import ChatModels

public final class CacheUserManager: CoreDataProtocol {
    public typealias Entity = CDUser
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

    public func insert(_ models: [Entity.Model], isMe: Bool = false) {
        insertObjects(context) { bgTask in
            models.forEach { model in
                let userEntity = Entity.insertEntity(bgTask)
                userEntity.update(model)
                userEntity.isMe = isMe as NSNumber
            }
        }
    }

    public func fetchCurrentUser(_ compeletion: @escaping (Entity?) -> Void) {
        context.perform {
            let req = Entity.fetchRequest()
            req.predicate = NSPredicate(format: "isMe == %@", NSNumber(booleanLiteral: true))
            let cachedUseInfo = try self.context.fetch(req).first
            compeletion(cachedUseInfo)
        }
    }
}
