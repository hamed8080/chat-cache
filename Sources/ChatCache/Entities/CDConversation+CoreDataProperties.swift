//
// CDConversation+CoreDataProperties.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation
import ChatModels

public extension CDConversation {
    typealias Entity = CDConversation
    typealias Model = Conversation
    typealias Id = Int
    static let name = "CDConversation"
    static var queryIdSpecifier: String = "%i"
    static let idName = "id"
}

public extension CDConversation {
    @NSManaged var admin: NSNumber?
    @NSManaged var canEditInfo: NSNumber?
    @NSManaged var canSpam: NSNumber?
    @NSManaged var closedThread: NSNumber?
    @NSManaged var descriptions: String?
    @NSManaged var group: NSNumber?
    @NSManaged var id: NSNumber?
    @NSManaged var image: String?
    @NSManaged var isArchive: NSNumber?
    @NSManaged var joinDate: NSNumber?
    @NSManaged var lastMessage: String?
    @NSManaged var lastParticipantImage: String?
    @NSManaged var lastParticipantName: String?
    @NSManaged var lastSeenMessageId: NSNumber?
    @NSManaged var lastSeenMessageNanos: NSNumber?
    @NSManaged var lastSeenMessageTime: NSNumber?
    @NSManaged var mentioned: NSNumber?
    @NSManaged var metadata: String?
    @NSManaged var mute: NSNumber?
    @NSManaged var participantCount: NSNumber?
    @NSManaged var partner: NSNumber?
    @NSManaged var partnerLastDeliveredMessageId: NSNumber?
    @NSManaged var partnerLastDeliveredMessageNanos: NSNumber?
    @NSManaged var partnerLastDeliveredMessageTime: NSNumber?
    @NSManaged var partnerLastSeenMessageId: NSNumber?
    @NSManaged var partnerLastSeenMessageNanos: NSNumber?
    @NSManaged var partnerLastSeenMessageTime: NSNumber?
    @NSManaged var pin: NSNumber?
    @NSManaged var time: NSNumber?
    @NSManaged var title: String?
    @NSManaged var type: NSNumber?
    @NSManaged var uniqueName: String?
    @NSManaged var unreadCount: NSNumber?
    @NSManaged var userGroupHash: String?
    @NSManaged var forwardInfos: NSSet?
    @NSManaged var inviter: CDParticipant?
    @NSManaged var lastMessageVO: CDMessage?
    @NSManaged var messages: NSSet?
    @NSManaged var mutualGroups: NSSet?
    @NSManaged var participants: NSSet?
    @NSManaged var pinMessages: NSSet?
    @NSManaged var tagParticipants: NSSet?
}

// MARK: Generated accessors for messages

public extension CDConversation {
    @objc(addMessagesObject:)
    @NSManaged func addToMessages(_ value: CDMessage)

    @objc(removeMessagesObject:)
    @NSManaged func removeFromMessages(_ value: CDMessage)

    @objc(addMessages:)
    @NSManaged func addToMessages(_ values: NSSet)

    @objc(removeMessages:)
    @NSManaged func removeFromMessages(_ values: NSSet)
}

// MARK: Generated accessors for mutualGroups

public extension CDConversation {
    @objc(addMutualGroupsObject:)
    @NSManaged func addToMutualGroups(_ value: CDMutualGroup)

    @objc(removeMutualGroupsObject:)
    @NSManaged func removeFromMutualGroups(_ value: CDMutualGroup)

    @objc(addMutualGroups:)
    @NSManaged func addToMutualGroups(_ values: NSSet)

    @objc(removeMutualGroups:)
    @NSManaged func removeFromMutualGroups(_ values: NSSet)
}

// MARK: Generated accessors for participants

public extension CDConversation {
    @objc(addParticipantsObject:)
    @NSManaged func addToParticipants(_ value: CDParticipant)

    @objc(removeParticipantsObject:)
    @NSManaged func removeFromParticipants(_ value: CDParticipant)

    @objc(addParticipants:)
    @NSManaged func addToParticipants(_ values: NSSet)

    @objc(removeParticipants:)
    @NSManaged func removeFromParticipants(_ values: NSSet)
}

// MARK: Generated accessors for pinMessages

public extension CDConversation {
    @objc(addPinMessagesObject:)
    @NSManaged func addToPinMessages(_ value: CDMessage)

    @objc(removePinMessagesObject:)
    @NSManaged func removeFromPinMessages(_ value: CDMessage)

    @objc(addPinMessages:)
    @NSManaged func addToPinMessages(_ values: NSSet)

    @objc(removePinMessages:)
    @NSManaged func removeFromPinMessages(_ values: NSSet)
}

// MARK: Generated accessors for tagParticipants

public extension CDConversation {
    @objc(addTagParticipantsObject:)
    @NSManaged func addToTagParticipants(_ value: CDTagParticipant)

    @objc(removeTagParticipantsObject:)
    @NSManaged func removeFromTagParticipants(_ value: CDTagParticipant)

    @objc(addTagParticipants:)
    @NSManaged func addToTagParticipants(_ values: NSSet)

    @objc(removeTagParticipants:)
    @NSManaged func removeFromTagParticipants(_ values: NSSet)
}

public extension CDConversation {
    func update(_ model: Model) {
        if model.id == nil { return }
        admin = model.admin as? NSNumber
        canEditInfo = model.canEditInfo as? NSNumber
        canSpam = model.canSpam as NSNumber?
        closedThread = model.closedThread as NSNumber?
        descriptions = model.description
        group = model.group as? NSNumber
        id = model.id as? NSNumber
        image = model.image
        joinDate = model.joinDate as? NSNumber
        lastMessage = model.lastMessage
        lastParticipantImage = model.lastParticipantImage
        lastParticipantName = model.lastParticipantName
        lastSeenMessageId = model.lastSeenMessageId as? NSNumber
        lastSeenMessageNanos = model.lastSeenMessageNanos as? NSNumber
        lastSeenMessageTime = model.lastSeenMessageTime as? NSNumber
        mentioned = model.mentioned as? NSNumber
        metadata = model.metadata
        mute = model.mute as? NSNumber
        participantCount = model.participantCount as? NSNumber
        partner = model.partner as? NSNumber
        partnerLastDeliveredMessageId = model.partnerLastDeliveredMessageId as? NSNumber
        partnerLastDeliveredMessageNanos = model.partnerLastDeliveredMessageNanos as? NSNumber
        partnerLastDeliveredMessageTime = model.partnerLastDeliveredMessageTime as? NSNumber
        partnerLastSeenMessageId = model.partnerLastSeenMessageId as? NSNumber
        partnerLastSeenMessageNanos = model.partnerLastSeenMessageNanos as? NSNumber
        partnerLastSeenMessageTime = model.partnerLastSeenMessageTime as? NSNumber
        pin = model.pin as? NSNumber
        time = model.time as? NSNumber
        title = model.title
        type = model.type?.rawValue as? NSNumber
        unreadCount = model.unreadCount as? NSNumber
        uniqueName = model.uniqueName
        userGroupHash = model.userGroupHash
        isArchive = model.isArchive as NSNumber?
    }

    class func findOrCreate(threadId: Int, context: NSManagedObjectContextProtocol) -> CDConversation {
        let req = CDConversation.fetchRequest()
        req.predicate = NSPredicate(format: "%K == %i", #keyPath(CDConversation.id), threadId)
        let entity = (try? context.fetch(req).first) ?? CDConversation.insertEntity(context)
        return entity
    }

    func codable(fillLastMessageVO: Bool = true, fillParticipants: Bool = false, fillPinMessages: Bool = true) -> Model {
        Conversation(admin: admin?.boolValue,
                     canEditInfo: canEditInfo?.boolValue,
                     canSpam: canSpam?.boolValue,
                     closedThread: closedThread?.boolValue,
                     description: descriptions,
                     group: group?.boolValue,
                     id: id?.intValue,
                     image: image,
                     joinDate: joinDate?.intValue,
                     lastMessage: lastMessage,
                     lastParticipantImage: lastParticipantImage,
                     lastParticipantName: lastParticipantName,
                     lastSeenMessageId: lastSeenMessageId?.intValue,
                     lastSeenMessageNanos: lastSeenMessageNanos?.uintValue,
                     lastSeenMessageTime: lastSeenMessageTime?.uintValue,
                     mentioned: mentioned?.boolValue,
                     metadata: metadata,
                     mute: mute?.boolValue,
                     participantCount: participantCount?.intValue,
                     partner: partner?.intValue,
                     partnerLastDeliveredMessageId: partnerLastDeliveredMessageId?.intValue,
                     partnerLastDeliveredMessageNanos: partnerLastDeliveredMessageNanos?.uintValue,
                     partnerLastDeliveredMessageTime: partnerLastDeliveredMessageTime?.uintValue,
                     partnerLastSeenMessageId: partnerLastSeenMessageId?.intValue,
                     partnerLastSeenMessageNanos: partnerLastSeenMessageNanos?.uintValue,
                     partnerLastSeenMessageTime: partnerLastSeenMessageTime?.uintValue,
                     pin: pin?.boolValue,
                     time: time?.uintValue,
                     title: title,
                     type: ThreadTypes(rawValue: type?.intValue ?? 0),
                     unreadCount: unreadCount?.intValue,
                     uniqueName: uniqueName,
                     userGroupHash: userGroupHash,
                     inviter: inviter?.codable,
                     lastMessageVO: fillLastMessageVO ? lastMessageVO?.codable(fillConversation: false) : nil,
                     participants: fillParticipants ? participants?.allObjects.compactMap { ($0 as? CDParticipant)?.codable } : nil,
                     pinMessages: fillPinMessages ? pinMessages?.allObjects.compactMap { $0 as? CDMessage }.map { $0.codable(fillConversation: false) } : nil,
                     isArchive: isArchive?.boolValue)
    }
}
