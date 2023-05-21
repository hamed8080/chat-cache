//
// CDQueueOfForwardMessages+CoreDataProperties.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation
import ChatModels

public extension CDQueueOfForwardMessages {
    typealias Entity = CDQueueOfForwardMessages
    typealias Model = QueueOfForwardMessages
    typealias Id = Int
    static let name = "CDQueueOfForwardMessages"
    static var queryIdSpecifier: String = "%i"
    static let idName = "id"
}

public extension CDQueueOfForwardMessages {
    @NSManaged var fromThreadId: NSNumber?
    @NSManaged var messageIds: String?
    @NSManaged var threadId: NSNumber?
    @NSManaged var typeCode: String?
    @NSManaged var uniqueIds: String?
}

public extension CDQueueOfForwardMessages {
    func update(_ model: Model) {
        fromThreadId = model.fromThreadId as? NSNumber
        messageIds = model.messageIds?.map { "\($0)" }.joined(separator: ",")
        threadId = model.threadId as? NSNumber
        typeCode = model.typeCode
        uniqueIds = model.uniqueIds?.joined(separator: ",")
    }

    var codable: Model {
        QueueOfForwardMessages(fromThreadId: fromThreadId?.intValue,
                               messageIds: messageIds?.split(separator: ",").compactMap { Int($0) },
                               threadId: threadId?.intValue,
                               typeCode: typeCode,
                               uniqueIds: uniqueIds?.split(separator: ",").map { String($0) })
    }
}
