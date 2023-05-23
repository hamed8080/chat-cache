//
// CacheUserRoleManager.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation
import ChatModels

public final class CacheUserRoleManager: BaseCoreDataManager<CDUserRole> {

    public func roles(_ threadId: Int) -> [Roles] {
        let req = Entity.fetchRequest()
        req.predicate = NSPredicate(format: "threadId == \(CDConversation.queryIdSpecifier)", threadId)
        let roles = (try? viewContext.fetch(req))?.first?.codable.roles
        return roles ?? []
    }
}
