//
// Codable+.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import Foundation
internal extension JSONDecoder {
    static let instance = JSONDecoder()
}

internal extension JSONEncoder {
    static let instance = JSONEncoder()
}

internal extension Encodable {
    var data: Data? {
        try? JSONEncoder.instance.encode(self)
    }
}
