//
// CacheManager.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation
import ChatModels

public final class CacheManager {
    internal let persistentManager: PersistentManager
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

    public func deleteQueues(uniqueIds: [String]) {
        editQueue?.delete(uniqueIds)
        fileQueue?.delete(uniqueIds)
        textQueue?.delete(uniqueIds)
        forwardQueue?.delete(uniqueIds)
    }

    public func switchToContainer(userId: Int, completion: (() ->Void)? = nil) {
        persistentManager.switchToContainer(userId: userId) { [weak self] in
            self?.setupManangers()
            completion?()
        }
    }

    public func delete() {
         persistentManager.delete()
    }
}
