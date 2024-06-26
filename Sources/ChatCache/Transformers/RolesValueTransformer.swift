//
// RolesValueTransformer.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import Foundation
import ChatModels
import Additive

@objc(RolesValueTransformer)
final class RolesValueTransformer: ValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        NSArray.self
    }

    override class func allowsReverseTransformation() -> Bool {
        true
    }

    override func transformedValue(_ value: Any?) -> Any? {
        guard let roles = value as? [Roles] else { return nil }
        do {
            let data = try JSONEncoder.instance.encode(roles)
            return data
        } catch {
            assertionFailure("Failed to transform `[Roles]` to `Data`")
            return nil
        }
    }

    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? NSData else { return nil }
        do {
            let roles = try JSONDecoder.instance.decode([Roles].self, from: data as Data)
            return roles
        } catch {
            assertionFailure("Failed to transform `data` to `[Roles]`")
            return nil
        }
    }
}

extension RolesValueTransformer {
    /// The name of the transformer. This is the name used to register the transformer using `ValueTransformer.setValueTrandformer(_"forName:)`.
    static let name = NSValueTransformerName(rawValue: String(describing: RolesValueTransformer.self))

    /// Registers the value transformer with `ValueTransformer`.
    public static func register() {
        let transformer = RolesValueTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: name)
    }
}
