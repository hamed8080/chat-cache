//
// FetchContactsRequest.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import Foundation

public struct FetchContactsRequest {
    internal var size: Int = 25
    internal var offset: Int = 0
    internal let id: Int?
    internal let cellphoneNumber: String?
    internal let email: String?
    internal let coreUserId: Int?
    internal let order: String?
    internal let query: String?
    internal var summery: Bool?

    public init(id: Int? = nil,
                count: Int = 50,
                cellphoneNumber: String? = nil,
                email: String? = nil,
                coreUserId: Int? = nil,
                offset: Int = 0,
                order: Ordering? = nil,
                query: String? = nil,
                summery: Bool? = nil)
    {
        size = count
        self.offset = offset
        self.id = id
        self.cellphoneNumber = cellphoneNumber
        self.email = email
        self.order = order?.rawValue ?? nil
        self.query = query
        self.summery = summery
        self.coreUserId = coreUserId
    }
}
