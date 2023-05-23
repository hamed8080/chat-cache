//
// FetchMessagesRequest.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import Foundation

public struct FetchMessagesRequest {
    internal let messageType: Int?
    internal let fromTime: UInt?
    internal let messageId: Int?
    internal let uniqueIds: [String]?
    internal let toTime: UInt?
    internal let query: String?
    internal let threadId: Int
    internal var offset: Int
    internal var count: Int
    internal let order: String?
    internal let hashtag: String?
    internal let toTimeNanos: UInt?

    public init(messageType: Int?,
                fromTime: UInt?,
                messageId: Int?,
                uniqueIds: [String]?,
                toTime: UInt?,
                query: String?,
                threadId: Int,
                offset: Int,
                count: Int,
                order: String?,
                hashtag: String?,
                toTimeNanos: UInt?) {
        self.messageType = messageType
        self.fromTime = fromTime
        self.messageId = messageId
        self.uniqueIds = uniqueIds
        self.toTime = toTime
        self.query = query
        self.threadId = threadId
        self.offset = offset
        self.count = count
        self.order = order
        self.hashtag = hashtag
        self.toTimeNanos = toTimeNanos
    }
}
