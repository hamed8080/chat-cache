//
// CDContact+CoreDataProperties.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation
import ChatModels

public extension CDContact {
    typealias Entity = CDContact
    typealias Model = Contact
    typealias Id = Int
    static let name = "CDContact"
    static var queryIdSpecifier: String = "%i"
    static let idName = "id"
}

public extension CDContact {
    @NSManaged var blocked: NSNumber?
    @NSManaged var cellphoneNumber: String?
    @NSManaged var email: String?
    @NSManaged var firstName: String?
    @NSManaged var hasUser: NSNumber?
    @NSManaged var id: NSNumber?
    @NSManaged var image: String?
    @NSManaged var lastName: String?
    @NSManaged var notSeenDuration: NSNumber?
    @NSManaged var time: NSNumber?
    @NSManaged var uniqueId: String?
    @NSManaged var userId: NSNumber?
    @NSManaged var user: CDUser?
}

public extension CDContact {
    func update(_ model: Model) {
        blocked = model.blocked as? NSNumber
        cellphoneNumber = model.cellphoneNumber
        email = model.email
        firstName = model.firstName
        hasUser = model.hasUser as NSNumber?
        id = model.id as? NSNumber
        image = model.image
        lastName = model.lastName
        notSeenDuration = model.notSeenDuration as? NSNumber
        time = model.time as? NSNumber
        userId = model.userId as? NSNumber
    }

    var codable: Model {
        Contact(blocked: blocked?.boolValue,
                cellphoneNumber: cellphoneNumber,
                email: email,
                firstName: firstName,
                hasUser: hasUser?.boolValue,
                id: id?.intValue,
                image: image,
                lastName: lastName,
                user: user?.codable,
                notSeenDuration: notSeenDuration?.intValue,
                time: time?.uintValue,
                userId: userId?.intValue)
    }

    func isContactChanged(contact: Contact) -> Bool {
        (email != contact.email) ||
            (firstName != contact.firstName) ||
            (lastName != contact.lastName)
    }
}
