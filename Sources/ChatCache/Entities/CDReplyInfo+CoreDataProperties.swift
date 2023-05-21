//
// CDReplyInfo+CoreDataProperties.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation
import ChatModels

public extension CDReplyInfo {
    typealias Entity = CDReplyInfo
    typealias Model = ReplyInfo
    typealias Id = Int
    static let name = "CDReplyInfo"
    static var queryIdSpecifier: String = "%i"
    static let idName = "id"
}

public extension CDReplyInfo {
    @NSManaged var markDeleted: NSNumber?
    @NSManaged var messageId: NSNumber?
    @NSManaged var messageText: String?
    @NSManaged var messageType: NSNumber?
    @NSManaged var metadata: String?
    @NSManaged var repliedToMessageId: NSNumber?
    @NSManaged var systemMetadata: String?
    @NSManaged var time: NSNumber?
    @NSManaged var parentMessage: CDMessage?
    @NSManaged var participant: CDParticipant?
}

public extension CDReplyInfo {
    func update(_ model: Model) {
        markDeleted = model.deleted as? NSNumber
        messageText = model.message
        messageType = model.messageType?.rawValue as? NSNumber
        metadata = model.metadata
        repliedToMessageId = model.repliedToMessageId as? NSNumber
        systemMetadata = model.systemMetadata
        time = model.time as? NSNumber
    }

    var codable: Model {
        ReplyInfo(deleted: markDeleted?.boolValue,
                  repliedToMessageId: repliedToMessageId?.intValue,
                  message: messageText,
                  messageType: MessageType(rawValue: messageType?.intValue ?? 0),
                  metadata: metadata,
                  systemMetadata: systemMetadata,
                  time: time?.uintValue,
                  participant: participant?.codable)
    }
}
