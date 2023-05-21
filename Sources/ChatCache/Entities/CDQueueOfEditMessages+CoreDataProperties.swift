//
// CDQueueOfEditMessages+CoreDataProperties.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation
import ChatModels

public extension CDQueueOfEditMessages {
    typealias Entity = CDQueueOfEditMessages
    typealias Model = QueueOfEditMessages
    typealias Id = Int
    static let name = "CDQueueOfEditMessages"
    static var queryIdSpecifier: String = "%i"
    static let idName = "id"
}

public extension CDQueueOfEditMessages {
    @NSManaged var messageId: NSNumber?
    @NSManaged var messageType: NSNumber?
    @NSManaged var metadata: String?
    @NSManaged var repliedTo: NSNumber?
    @NSManaged var textMessage: String?
    @NSManaged var threadId: NSNumber?
    @NSManaged var typeCode: String?
    @NSManaged var uniqueId: String?
}

public extension CDQueueOfEditMessages {
    func update(_ model: Model) {
        messageId = model.messageId as? NSNumber
        messageType = model.messageType?.rawValue as? NSNumber
        metadata = model.metadata
        repliedTo = model.repliedTo as? NSNumber
        textMessage = model.textMessage
        threadId = model.threadId as? NSNumber
        typeCode = model.typeCode
        uniqueId = model.uniqueId
    }

    var codable: Model {
        QueueOfEditMessages(messageId: messageId?.intValue,
                            messageType: MessageType(rawValue: messageType?.intValue ?? 0),
                            metadata: metadata,
                            repliedTo: repliedTo?.intValue,
                            textMessage: textMessage,
                            threadId: threadId?.intValue,
                            typeCode: typeCode,
                            uniqueId: uniqueId)
    }
}
