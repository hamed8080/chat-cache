//
// CDUserRole+CoreDataProperties.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation
import ChatModels
import Additive

public extension CDUserRole {
    typealias Entity = CDUserRole
    typealias Model = UserRole
    typealias Id = Int
    static let name = "CDUserRole"
    static var queryIdSpecifier: String = "%i"
    static let idName = "id"
}

public extension CDUserRole {
    @NSManaged var image: String?
    @NSManaged var name: String?
    @NSManaged var roles: Data?
    @NSManaged var userId: NSNumber?
    @NSManaged var user: CDUser?
}

public extension CDUserRole {
    func update(_ model: Model) {
        name = model.name
        roles = model.roles?.data
        userId = model.userId as? NSNumber
        image = model.image
    }

    var codable: Model {
        UserRole(userId: userId?.intValue,
                 name: name,
                 roles: try? JSONDecoder.instance.decode([Roles].self, from: roles ?? Data()),
                 image: image)
    }
}
