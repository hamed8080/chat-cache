//
// CDQueueOfFileMessages+CoreDataProperties.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation
import ChatModels

public extension CDQueueOfFileMessages {
    typealias Entity = CDQueueOfFileMessages
    typealias Model = QueueOfFileMessages
    typealias Id = Int
    static let name = "CDQueueOfFileMessages"
    static var queryIdSpecifier: String = "%i"
    static let idName = "id"
}

public extension CDQueueOfFileMessages {
    @NSManaged var fileExtension: String?
    @NSManaged var fileName: String?
    @NSManaged var fileToSend: Data?
    @NSManaged var hC: NSNumber?
    @NSManaged var imageToSend: Data?
    @NSManaged var isPublic: NSNumber?
    @NSManaged var messageType: NSNumber?
    @NSManaged var metadata: String?
    @NSManaged var mimeType: String?
    @NSManaged var originalName: String?
    @NSManaged var repliedTo: NSNumber?
    @NSManaged var textMessage: String?
    @NSManaged var threadId: NSNumber?
    @NSManaged var typeCode: String?
    @NSManaged var uniqueId: String?
    @NSManaged var userGroupHash: String?
    @NSManaged var wC: NSNumber?
    @NSManaged var xC: NSNumber?
    @NSManaged var yC: NSNumber?
}

public extension CDQueueOfFileMessages {
    func update(_ model: Model) {
        fileExtension = model.fileExtension
        fileName = model.fileName
        fileToSend = model.fileToSend
        imageToSend = model.imageToSend
        isPublic = model.isPublic as? NSNumber
        messageType = model.messageType?.rawValue as? NSNumber
        metadata = model.metadata
        mimeType = model.mimeType
        originalName = model.originalName
        repliedTo = model.repliedTo as? NSNumber
        textMessage = model.textMessage
        threadId = model.threadId as? NSNumber
        typeCode = model.typeCode
        uniqueId = model.uniqueId
        userGroupHash = model.userGroupHash
        hC = model.hC as? NSNumber
        wC = model.wC as? NSNumber
        xC = model.xC as? NSNumber
        yC = model.yC as? NSNumber
    }

    var codable: Model {
        QueueOfFileMessages(fileExtension: fileExtension,
                            fileName: fileName,
                            isPublic: isPublic?.boolValue,
                            messageType: MessageType(rawValue: messageType?.intValue ?? 0),
                            metadata: metadata,
                            mimeType: mimeType,
                            originalName: originalName,
                            repliedTo: repliedTo?.intValue,
                            textMessage: textMessage,
                            threadId: threadId?.intValue,
                            typeCode: typeCode,
                            uniqueId: uniqueId,
                            userGroupHash: userGroupHash,
                            hC: hC?.intValue,
                            wC: wC?.intValue,
                            xC: xC?.intValue,
                            yC: yC?.intValue,
                            fileToSend: fileToSend,
                            imageToSend: imageToSend)
    }
}
