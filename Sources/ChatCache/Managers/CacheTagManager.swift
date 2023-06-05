//
// CacheTagManager.swift
// Copyright (c) 2022 ChatCache
//
// Created by Hamed Hosseini on 12/14/22

import CoreData
import Foundation
import ChatModels

public final class CacheTagManager: BaseCoreDataManager<CDTag> {
    
    public func getTags(_ completion: @escaping ([Entity]) -> Void) {
        viewContext.perform {
            let req = Entity.fetchRequest()
            let tags = try self.viewContext.fetch(req)
            completion(tags)
        }
    }

    public func delete(_ id: Int?) {
        let predicate = idPredicate(id: id ?? -1)
        batchDelete(predicate: predicate)
    }
}
