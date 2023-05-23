//
// CacheManager.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation

public final class CacheManager {
    private let persistentManager: PersistentManager
    public private(set) var assistant: CacheAssistantManager?
    public private(set) var contact: CacheContactManager?
    public private(set) var conversation: CacheConversationManager?
    public private(set) var file: CacheCoreDataFileManager?
    public private(set) var forwardInfo: CacheForwardInfoManager?
    public private(set) var image: CacheImageManager?
    public private(set) var message: CacheMessageManager?
    public private(set) var mutualGroup: CacheMutualGroupManager?
    public private(set) var participant: CacheParticipantManager?
    public private(set) var editQueue: CacheQueueOfEditMessagesManager?
    public private(set) var textQueue: CacheQueueOfTextMessagesManager?
    public private(set) var forwardQueue: CacheQueueOfForwardMessagesManager?
    public private(set) var fileQueue: CacheQueueOfFileMessagesManager?
    public private(set) var replyInfo: CacheReplyInfoManager?
    public private(set) var tag: CacheTagManager?
    public private(set) var tagParticipant: CacheTagParticipantManager?
    public private(set) var user: CacheUserManager?
    public private(set) var userRole: CacheUserRoleManager?
    lazy var entities: [NSEntityDescription] = {
        [
            CDTag.entity(),
            CDParticipant.entity(),
            CDConversation.entity(),
            CDTagParticipant.entity(),
            CDMessage.entity(),
            CDReplyInfo.entity(),
            CDUserRole.entity(),
            CDUser.entity(),
            CDQueueOfEditMessages.entity(),
            CDQueueOfFileMessages.entity(),
            CDQueueOfTextMessages.entity(),
            CDQueueOfForwardMessages.entity(),
            CDFile.entity(),
            CDImage.entity(),
            CDAssistant.entity(),
            CDForwardInfo.entity(),
            CDMutualGroup.entity(),
            CDContact.entity(),
        ]
    }()

    public init(logger: CacheLogDelegate) {
        persistentManager = PersistentManager(logger: logger)
    }

    public func setupManangers(){
        if let logger = persistentManager.logger {
            assistant = CacheAssistantManager(container: persistentManager, logger: logger)
            contact = CacheContactManager(container: persistentManager, logger: logger)
            conversation = CacheConversationManager(container: persistentManager, logger: logger)
            file = CacheCoreDataFileManager(container: persistentManager, logger: logger)
            forwardInfo = CacheForwardInfoManager(container: persistentManager, logger: logger)
            image = CacheImageManager(container: persistentManager, logger: logger)
            message = CacheMessageManager(container: persistentManager, logger: logger)
            mutualGroup = CacheMutualGroupManager(container: persistentManager, logger: logger)
            participant = CacheParticipantManager(container: persistentManager, logger: logger)
            editQueue = CacheQueueOfEditMessagesManager(container: persistentManager, logger: logger)
            textQueue = CacheQueueOfTextMessagesManager(container: persistentManager, logger: logger)
            forwardQueue = CacheQueueOfForwardMessagesManager(container: persistentManager, logger: logger)
            fileQueue = CacheQueueOfFileMessagesManager(container: persistentManager, logger: logger)
            replyInfo = CacheReplyInfoManager(container: persistentManager, logger: logger)
            tag = CacheTagManager(container: persistentManager, logger: logger)
            tagParticipant = CacheTagParticipantManager(container: persistentManager, logger: logger)
            user = CacheUserManager(container: persistentManager, logger: logger)
            userRole = CacheUserRoleManager(container: persistentManager, logger: logger)
        }
    }

    public func truncate(bgTask: NSManagedObjectContext, context: NSManagedObjectContext) {
        bgTask.perform { [weak self] in
            var objectIds: [NSManagedObjectID] = []
            try self?.entities.forEach { entity in
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entity.name ?? "")
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                deleteRequest.resultType = .resultTypeObjectIDs
                if let result = try bgTask.execute(deleteRequest) as? NSBatchDeleteResult, let ids = result.result as? [NSManagedObjectID] {
                    objectIds.append(contentsOf: ids)
                }
                try? bgTask.save()
                self?.mergeChanges(context: context, key: NSDeletedObjectsKey, objectIds)
            }
        }
    }

    public func mergeChanges(context: NSManagedObjectContext, key: String, _ objectIDs: [NSManagedObjectID]) {
        NSManagedObjectContext.mergeChanges(
            fromRemoteContextSave: [key: objectIDs],
            into: [context]
        )
    }

    public func deleteQueues(uniqueIds: [String]) {
        editQueue?.delete(uniqueIds)
        fileQueue?.delete(uniqueIds)
        textQueue?.delete(uniqueIds)
        forwardQueue?.delete(uniqueIds)
    }

    public func switchToContainer(userId: Int) {
        persistentManager.switchToContainer(userId: userId) { [weak self] in
            self?.setupManangers()
        }
    }

    public func delete() {
         persistentManager.delete()
    }
}
