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
    @NSManaged var messageId: NSNumber?
    @NSManaged var conversation: CDConversation?
    @NSManaged var message: CDMessage?
    @NSManaged var participant: CDParticipant?
}

public extension CDForwardInfo {

    func update(_ model: Model) {
    }

    var codable: Model {
        ForwardInfo(conversation: conversation?.codable(), participant: participant?.codable)
    }
}
