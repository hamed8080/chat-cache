//
// CDCurrentUserRole+CoreDataProperties.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation
import ChatModels

public extension CDCurrentUserRole {
    typealias Entity = CDCurrentUserRole
    typealias Model = CurrentUserRole
    typealias Id = Int
    static let name = "CDCurrentUserRole"
    static var queryIdSpecifier: String = "%i"
    static let idName = "threadId"
}

public extension CDCurrentUserRole {
    @NSManaged var roles: Data?
    @NSManaged var threadId: NSNumber?
}

public extension CDCurrentUserRole {
    func update(_ model: Model) {
        roles = model.roles?.data
        threadId = model.threadId as? NSNumber
    }

    var codable: Model {
        var decodecRoles: [Roles]?
        if let data = self.roles {
           decodecRoles = try? JSONDecoder.instance.decode([Roles].self, from: data)
        }
        return CurrentUserRole(threadId: threadId?.intValue, roles:  decodecRoles)
    }
}
