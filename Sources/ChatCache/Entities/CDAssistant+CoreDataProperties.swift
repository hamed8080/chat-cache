//
// CDAssistant+CoreDataProperties.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation
import ChatModels
import Additive

public extension CDAssistant {
    typealias Entity = CDAssistant
    typealias Model = Assistant
    typealias Id = Int
    static let name = "CDAssistant"
    static var queryIdSpecifier: String = "%i"
    static let idName = "id"
}

public extension CDAssistant {
    @NSManaged var assistant: Invitee?
    @NSManaged var block: NSNumber?
    @NSManaged var contactType: String?
    @NSManaged var inviteeId: Int64
    @NSManaged var roles: Data?
    @NSManaged var participant: CDParticipant?
}

public extension CDAssistant {
    func update(_ model: Model) {
        contactType = model.contactType
        self.assistant = model.assistant
        roles = model.roles?.data
        block = model.block as? NSNumber
        setParticipant(model: model)
    }
    
    func setParticipant(model: Model) {
        guard let context = managedObjectContext else { return }
        let predicate = NSPredicate(format: "%K == %i", #keyPath(CDParticipant.id), model.participant?.id as? NSNumber ?? 0)
        let req = CDParticipant.fetchRequest()
        req.predicate = predicate
        if let participantEntity = try? context.fetch(req).first {
            self.participant = participantEntity
        } else if let participantModel = model.participant {
            let participantEntity = CDParticipant.insertEntity(context)
            participantEntity.update(participantModel)
            self.participant = participantEntity
        }
    }

    var codable: Model {
        Assistant(contactType: contactType,
                  assistant: assistant,
                  participant: participant?.codable,
                  roles: try? JSONDecoder.instance.decode([Roles].self, from: roles ?? Data()),
                  block: block?.boolValue)
    }
}
