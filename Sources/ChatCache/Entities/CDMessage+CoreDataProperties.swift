//
// CDMessage+CoreDataProperties.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation
import ChatModels

public extension CDMessage {
    typealias Entity = CDMessage
    typealias Model = Message
    typealias Id = Int
    static let name = "CDMessage"
    static var queryIdSpecifier: String = "%i"
    static let idName = "id"
}

public extension CDMessage {
    @NSManaged var deletable: NSNumber?
    @NSManaged var delivered: NSNumber?
    @NSManaged var editable: NSNumber?
    @NSManaged var edited: NSNumber?
    /// Messages with the same ID cannot exist in two different threads since they are unique to the server.
    @NSManaged var id: NSNumber?
    @NSManaged var mentioned: NSNumber?
    @NSManaged var message: String?
    @NSManaged var messageType: NSNumber?
    @NSManaged var metadata: String?
    @NSManaged var notifyAll: NSNumber?
    @NSManaged var ownerId: NSNumber?
    @NSManaged var pinned: NSNumber?
    @NSManaged var pinTime: NSNumber?
    @NSManaged var previousId: NSNumber?
    @NSManaged var seen: NSNumber?
    @NSManaged var systemMetadata: String?
    @NSManaged var threadId: NSNumber?
    @NSManaged var time: NSNumber?
    @NSManaged var uniqueId: String?
    @NSManaged var conversation: CDConversation?
    @NSManaged var forwardInfo: ForwardInfo?
    @NSManaged var conversationLastMessageVO: CDConversation?
    @NSManaged var participant: CDParticipant?
    @NSManaged var pinMessages: CDConversation?
    @NSManaged var replyInfo: ReplyInfo?
}

public extension CDMessage {
    func update(_ model: Model) {
        deletable = model.deletable as? NSNumber
        delivered = model.delivered as? NSNumber
        editable = model.editable as? NSNumber
        edited = model.edited as? NSNumber
        id = model.id as? NSNumber
        mentioned = model.mentioned as? NSNumber
        message = model.message
        messageType = model.messageType?.rawValue as? NSNumber
        metadata = model.metadata
        ownerId = model.ownerId as? NSNumber
        pinned = model.pinned as? NSNumber
        previousId = model.previousId as? NSNumber
        seen = model.seen as? NSNumber
        systemMetadata = model.systemMetadata
        threadId = model.threadId as? NSNumber ?? model.conversation?.id as? NSNumber
        time = model.time as? NSNumber
        uniqueId = model.uniqueId
        pinTime = model.pinTime as? NSNumber
        notifyAll = model.pinNotifyAll as? NSNumber
        replyInfo = model.replyInfo
        forwardInfo = model.forwardInfo

        if let participant = model.participant, let threadId = threadId, let context = managedObjectContext {
            setParticipant(participant, threadId.intValue, context)
        }
    }

    func setParticipant(_ participant: Participant, _ threadId: Int, _ context: NSManagedObjectContext) {
        if let participantId = participant.id {
            self.participant = CDParticipant.findOrCreate(threadId: threadId, participantId: participantId, context: context)
            self.participant?.conversation = CDConversation.findOrCreate(threadId: threadId, context: context)
            self.participant?.update(participant)
        }
    }

    func codable(fillConversation: Bool = true, fillParticipant: Bool = true) -> Model {
       return Message(threadId: threadId?.intValue,
                deletable: deletable?.boolValue,
                delivered: deletable?.boolValue,
                editable: editable?.boolValue,
                edited: edited?.boolValue,
                id: id?.intValue,
                mentioned: mentioned?.boolValue,
                message: message,
                messageType: MessageType(rawValue: messageType?.intValue ?? 0),
                metadata: metadata,
                ownerId: ownerId?.intValue,
                pinned: pinned?.boolValue,
                previousId: previousId?.intValue,
                seen: seen?.boolValue,
                systemMetadata: systemMetadata,
                time: time?.uintValue,
                timeNanos: time?.uintValue,
                uniqueId: uniqueId,
                conversation: fillConversation ? conversation?.codable() : nil,
                forwardInfo: forwardInfo,
                participant: fillParticipant ? participant?.codable : nil,
                replyInfo: replyInfo,
                pinTime: pinTime?.uintValue,
                notifyAll: notifyAll?.boolValue)
    }
}
