//
// CDImage+CoreDataProperties.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation
import ChatModels

public extension CDImage {
    typealias Entity = CDImage
    typealias Model = Image
    typealias Id = String
    static let name = "CDImage"
    static var queryIdSpecifier: String = "%@"
    static let idName = "hashCode"
}

public extension CDImage {
    @NSManaged var actualHeight: NSNumber?
    @NSManaged var actualWidth: NSNumber?
    @NSManaged var hashCode: String?
    @NSManaged var height: NSNumber?
    @NSManaged var name: String?
    @NSManaged var size: NSNumber?
    @NSManaged var width: NSNumber?
}

public extension CDImage {
    func update(_ model: Model) {
        actualWidth = model.actualWidth as? NSNumber
        actualHeight = model.actualHeight as? NSNumber
        height = model.height as? NSNumber
        width = model.width as? NSNumber
        size = model.size as? NSNumber
        name = model.name
        hashCode = model.hashCode
    }

    var codable: Model {
        Image(actualWidth: actualWidth?.intValue,
              actualHeight: actualHeight?.intValue,
              height: height?.intValue,
              width: width?.intValue,
              size: size?.intValue,
              name: name,
              hashCode: hashCode)
    }
}
