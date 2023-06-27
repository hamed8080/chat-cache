//
// CDUser+CoreDataProperties.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation
import ChatModels

public extension CDUser {
    typealias Entity = CDUser
    typealias Model = User
    typealias Id = Int
    static let name = "CDUser"
    static var queryIdSpecifier: String = "%i"
    static let idName = "id"
}

public extension CDUser {
    @NSManaged var bio: String?
    @NSManaged var cellphoneNumber: String?
    @NSManaged var coreUserId: NSNumber?
    @NSManaged var email: String?
    @NSManaged var firstName: String?
    @NSManaged var id: NSNumber?
    @NSManaged var image: String?
    @NSManaged var isMe: NSNumber?
    @NSManaged var lastName: String?
    @NSManaged var lastSeen: NSNumber?
    @NSManaged var metadata: String?
    @NSManaged var name: String?
    @NSManaged var nickname: String?
    @NSManaged var receiveEnable: NSNumber?
    @NSManaged var sendEnable: NSNumber?
    @NSManaged var ssoId: String?
    @NSManaged var username: String?
    @NSManaged var contacts: NSSet?
}

// MARK: Generated accessors for contacts

public extension CDUser {
    @objc(addContactsObject:)
    @NSManaged func addToContacts(_ value: CDContact)

    @objc(removeContactsObject:)
    @NSManaged func removeFromContacts(_ value: CDContact)

    @objc(addContacts:)
    @NSManaged func addToContacts(_ values: NSSet)

    @objc(removeContacts:)
    @NSManaged func removeFromContacts(_ values: NSSet)
}

public extension CDUser {
    func update(_ model: Model) {
        cellphoneNumber = model.cellphoneNumber
        coreUserId = model.coreUserId as? NSNumber
        email = model.email
        id = model.id as? NSNumber
        image = model.image
        lastSeen = model.lastSeen as? NSNumber
        name = model.name
        nickname = model.nickname
        receiveEnable = model.receiveEnable as? NSNumber
        sendEnable = model.sendEnable as? NSNumber
        username = model.username
        bio = model.chatProfileVO?.bio
        metadata = model.chatProfileVO?.metadata
        ssoId = model.ssoId
        lastName = model.lastName
        firstName = model.firstName
    }

    var codable: Model {
        User(cellphoneNumber: cellphoneNumber,
             coreUserId: coreUserId?.intValue,
             email: email,
             id: id?.intValue,
             image: image,
             lastSeen: lastSeen?.intValue,
             name: name,
             nickname: nickname,
             receiveEnable: receiveEnable?.boolValue,
             sendEnable: sendEnable?.boolValue,
             username: username,
             ssoId: ssoId,
             firstName: firstName,
             lastName: lastName, profile: Profile(bio: bio, metadata: metadata))
    }
}
