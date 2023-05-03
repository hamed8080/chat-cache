//
// CDForwardInfo+CoreDataProperties.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation
import ChatModels

public extension CDForwardInfo {
    @nonobjc class func fetchRequest() -> NSFetchRequest<CDForwardInfo> {
        NSFetchRequest<CDForwardInfo>(entityName: "CDForwardInfo")
    }

    static let entityName = "CDForwardInfo"
    static func entityDescription(_ context: NSManagedObjectContext) -> NSEntityDescription {
        NSEntityDescription.entity(forEntityName: entityName, in: context)!
    }

    static func insertEntity(_ context: NSManagedObjectContext) -> CDForwardInfo {
        CDForwardInfo(entity: entityDescription(context), insertInto: context)
    }

    @NSManaged var messageId: NSNumber?
    @NSManaged var conversation: CDConversation?
    @NSManaged var message: CDMessage?
    @NSManaged var participant: CDParticipant?
}

public extension CDForwardInfo {
    var codable: ForwardInfo {
        ForwardInfo(conversation: conversation?.codable(), participant: participant?.codable)
    }
}
