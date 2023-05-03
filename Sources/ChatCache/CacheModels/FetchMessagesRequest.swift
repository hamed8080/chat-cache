//
// FetchMessagesRequest.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import Foundation

public struct FetchMessagesRequest {
    public let messageType: Int?
    public let fromTime: UInt?
    public let messageId: Int?
    public let uniqueIds: [String]?
    public let toTime: UInt?
    public let query: String?
    public let threadId: Int
    public var offset: Int
    public var count: Int
    public let order: String?
    public let hashtag: String?
    public let toTimeNanos: UInt?

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
