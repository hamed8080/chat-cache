//
// CDTagParticipant+CoreDataProperties.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import ChatModels
import Foundation

public extension CDTagParticipant {
    typealias Entity = CDTagParticipant
    typealias Model = TagParticipant
    typealias Id = Int
    static let name = "CDTagParticipant"
    static var queryIdSpecifier: String = "%i"
    static let idName = "id"
}

public extension CDTagParticipant {
    @NSManaged var active: NSNumber?
    @NSManaged var id: NSNumber?
    @NSManaged var tagId: NSNumber?
    @NSManaged var threadId: NSNumber?
    @NSManaged var conversation: CDConversation?
    @NSManaged var tag: CDTag?
}

public extension CDTagParticipant {
    func update(_ model: Model) {
        id = model.id as? NSNumber
        active = model.active as? NSNumber
        tagId = model.tagId as? NSNumber
        id = model.id as? NSNumber
    }

    var codable: Model {
        TagParticipant(id: id?.intValue,
                       active: active?.boolValue,
                       tagId: tagId?.intValue,
                       threadId: threadId?.intValue,
                       conversation: conversation?.codable())
    }
}
