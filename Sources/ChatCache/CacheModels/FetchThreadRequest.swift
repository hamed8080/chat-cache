//
// FetchThreadRequest.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import Foundation

public struct FetchThreadRequest {
    internal let count: Int
    internal let offset: Int
    internal var title: String?
    internal var description: String?
    internal let new: Bool?
    internal let archived: Bool?
    internal let threadIds: [Int]?
    internal let creatorCoreUserId: Int?
    internal let partnerCoreUserId: Int?
    internal let partnerCoreContactId: Int?
    internal private(set) var metadataCriteria: String?
    internal private(set) var isGroup: Bool?
    internal private(set) var type: Int?
    internal let uniqueId: String?

    public init(count: Int = 25,
                offset: Int = 0,
                title: String? = nil,
                description: String? = nil,
                new: Bool? = nil,
                isGroup: Bool? = nil,
                type: Int? = nil,
                archived: Bool? = nil,
                threadIds: [Int]? = nil,
                creatorCoreUserId: Int? = nil,
                partnerCoreUserId: Int? = nil,
                partnerCoreContactId: Int? = nil,
                metadataCriteria: String? = nil,
                uniqueId: String? = nil)
    {
        self.count = count
        self.offset = offset
        self.title = title
        self.description = description
        self.metadataCriteria = metadataCriteria
        self.new = new
        self.isGroup = isGroup
        self.type = type
        self.archived = archived
        self.threadIds = threadIds
        self.creatorCoreUserId = creatorCoreUserId
        self.partnerCoreUserId = partnerCoreUserId
        self.partnerCoreContactId = partnerCoreContactId
        self.uniqueId = uniqueId
    }

}
