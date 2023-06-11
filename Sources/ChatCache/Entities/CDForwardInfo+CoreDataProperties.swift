//
// CDForwardInfo+CoreDataProperties.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation
import ChatModels

public extension CDForwardInfo {
    typealias Entity = CDForwardInfo
    typealias Model = ForwardInfo
    typealias Id = Int
    static let name = "CDForwardInfo"
    static var queryIdSpecifier: String = "%i"
    static let idName = "id"
}

public extension CDForwardInfo {
    @NSManaged var parentMessageId: NSNumber?
    @NSManaged var forwardedMessageId: NSNumber?
    @NSManaged var forwardedThreadId: NSNumber?
    @NSManaged var conversation: CDConversation?
    @NSManaged var message: CDMessage?
    @NSManaged var participant: CDParticipant?
}

public extension CDForwardInfo {

    func update(_ model: Model) {
    }

    class func findOrCreate(parentMessageId: Int, forwardedMessageId: Int, forwardedThreadId: Int, context: NSManagedObjectContextProtocol) -> CDForwardInfo {
        let req = CDForwardInfo.fetchRequest()
        req.predicate = NSPredicate(format: "%K == %i AND %K == %i AND %K == %i",
                                    #keyPath(CDForwardInfo.parentMessageId), parentMessageId,
                                    #keyPath(CDForwardInfo.forwardedMessageId), forwardedMessageId,
                                    #keyPath(CDForwardInfo.forwardedThreadId), forwardedThreadId

        )
        let entity = (try? context.fetch(req).first) ?? CDForwardInfo.insertEntity(context)
        return entity
    }

    var codable: Model {
        ForwardInfo(conversation: conversation?.codable(), participant: participant?.codable)
    }
}
