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

    public init(messageType: Int? = nil,
                fromTime: UInt? = nil,
                messageId: Int? = nil,
                uniqueIds: [String]? = nil,
                toTime: UInt? = nil,
                query: String? = nil,
                threadId: Int,
                offset: Int = 0,
                count: Int = 25,
                order: String? = nil,
                hashtag: String? = nil,
                toTimeNanos: UInt? = nil) {
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
