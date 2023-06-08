import XCTest
import ChatModels
import CoreData
import Combine
@testable import ChatCache

@available(iOS 13.0, *)
final class CacheConversationManagerTests: XCTestCase, CacheLogDelegate {

    var sut: CacheConversationManager!
    var cache: CacheManager!
    var logExpectation = XCTestExpectation(description: "Expected to call log delegate")
    var notification: MockObjectContextNotificaiton!
    var objectId: NSManagedObjectID?

    override func setUpWithError() throws {
        cache = CacheManager(persistentManager: PersistentManager(logger: self))
        cache.switchToContainer(userId: 1)
        sut = cache.conversation
        notification = MockObjectContextNotificaiton(context: sut.viewContext)
    }

    func test_whenInsert_conversationIsInStore() {
        // Given
        let models = [mockModel(id: 1), mockModel(id: 2)]

        // When
        sut.insert(models: models)

        // Then
        let exp = expectation(description: "Expected to insert two items in store.")
        notification.onInsert { (entities: [CDConversation]) in
            if entities.count == 2 {
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 1)
    }

    func test_whenDelete_conversationIsDeletedInStore() {
        // Given
        let models = [mockModel(id: 1), mockModel(id: 2)]
        sut.insert(models: models)

        // When
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.batchDelete(models.compactMap(\.id))
        }

        // Then
        let exp = expectation(description: "Expected to delete two items from store.")
        notification.onDeletedIds { objectIds in
            if objectIds.count == 2 {
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 1)
    }

    func test_whenUpdateTitle_titleIsStored() {
        // Given
        let models = [mockModel(id: 1), mockModel(id: 2)]
        sut.insert(models: models)

        // When
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.update(["title": "Updated Title"], self.sut.idPredicate(id: models.first!.id!))
        }

        // Then
        let exp = expectation(description: "Expected to update thread title.")
        notification.onUpdateIds { objectIds in
            if objectIds.count == 1 {
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 1)
    }

    func test_whenIncreaseUnreadCount_isIncreased() {
        // Given
        let models = [mockModel(id: 1, unreadCount: 10)]
        sut.insert(models: models)

        // When
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.setUnreadCount(action: .increase, threadId: models.first!.id!)
        }

        // Then
        let exp = expectation(description: "Expected to increase unreadCount to 11.")
        notification.onUpdateIds { objectIds in
            self.sut.first(with: models.first!.id!, context: self.sut.viewContext) { response in
                if response?.unreadCount == 11 {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    func test_whenDecreaseUnreadCount_isDecreased() {
        // Given
        let models = [mockModel(id: 1, unreadCount: 10)]
        sut.insert(models: models)

        // When
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.setUnreadCount(action: .decrease, threadId: models.first!.id!)
        }

        // Then
        let exp = expectation(description: "Expected to increase unreadCount to 9.")
        notification.onUpdateIds { objectIds in
            self.sut.first(with: models.first!.id!, context: self.sut.viewContext) { response in
                if response?.unreadCount == 9 {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    func test_whenDecreaseUnreadCountIsZero_isNotNegativeNumber() {
        // Given
        let models = [mockModel(id: 1, unreadCount: 0)]
        sut.insert(models: models)

        // When
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.setUnreadCount(action: .decrease, threadId: models.first!.id!)
        }

        // Then
        let exp = expectation(description: "Expected to increase unreadCount to 0.")
        notification.onUpdateIds { objectIds in
            self.sut.first(with: models.first!.id!, context: self.sut.viewContext) { response in
                if response?.unreadCount == 0 {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    func test_whenSetUnreadCount_isEqualToValueSetted() {
        // Given
        let models = [mockModel(id: 1, unreadCount: 5)]
        sut.insert(models: models)

        // When
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.setUnreadCount(action: .set(8), threadId: models.first!.id!)
        }

        // Then
        let exp = expectation(description: "Expected to set the value of unreadCount to 8.")
        notification.onUpdateIds { objectIds in
            self.sut.first(with: models.first!.id!, context: self.sut.viewContext) { response in
                if response?.unreadCount == 8 {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    func test_whenSetNegativeUnreadCount_isEqualToZero() {
        // Given
        let models = [mockModel(id: 1, unreadCount: 5)]
        sut.insert(models: models)

        // When
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.setUnreadCount(action: .set(-10), threadId: models.first!.id!)
        }

        // Then
        let exp = expectation(description: "Expected to set unreadCount to 0.")
        notification.onUpdateIds { objectIds in
            self.sut.first(with: models.first!.id!, context: self.sut.viewContext) { response in
                if response?.unreadCount == 0 {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    func test_whenGetThreadsUnreadCountDictionary_isFilledWithRightValues() {
        // Given
        let notpartOfFetch = mockModel(id: 4, unreadCount: 50)
        let models = [mockModel(id: 1, unreadCount: 5), mockModel(id: 2, unreadCount: 8), mockModel(id: 3, unreadCount: 10), notpartOfFetch]
        sut.insert(models: models)

        // When
        let exp = expectation(description: "Expected fetch 3 threads out of four threads that we have inserted.")
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.threadsUnreadcount(models.compactMap(\.id).dropLast()) { dictionary in
                let first = dictionary["\(1)"]
                let second = dictionary["\(2)"]
                let third = dictionary["\(3)"]
                if dictionary.count == models.count - 1, first == 5, second == 8, third == 10 {
                    exp.fulfill()
                }
            }
        }

        // Then
        wait(for: [exp], timeout: 1)
    }

    func test_whenGetThreadsUnreadCount_isFilledWithRightValues() {
        // Given
        let models = [mockModel(id: 1, unreadCount: 5), mockModel(id: 2, unreadCount: 8), mockModel(id: 3, unreadCount: nil)]
        sut.insert(models: models)

        // When
        let exp = expectation(description: "Expected to set two threads unread count, because the last thread has no unread count value.")
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.threadsUnreadcount(models.compactMap(\.id)) { dictionary in
                let first = dictionary["\(1)"]
                let second = dictionary["\(2)"]
                if dictionary.count == models.count - 1, first == 5, second == 8 {
                    exp.fulfill()
                }
            }
        }

        // Then
        wait(for: [exp], timeout: 1)
    }

    func test_whenGetThreadsThereIsNoThreads_returnAnEmptyDic() {
        // When
        let exp = expectation(description: "Expected to get an empty array when there is no thread.")
        self.sut.threadsUnreadcount([1]) { dictionary in
            if dictionary.count == 0 {
                exp.fulfill()
            }
        }

        // Then
        wait(for: [exp], timeout: 1)
    }

    func test_whenUpdateThreadsUnreadCount_shoulUpdateThreadsUnreadCount() {
        // Given
        let models = [mockModel(id: 1, unreadCount: 5), mockModel(id: 2, unreadCount: 8), mockModel(id: 3, unreadCount: nil)]
        sut.insert(models: models)

        // When
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.updateThreadsUnreadCount(["1": 10, "2": 20, "3": 0])
        }

        // Then
        let exp = expectation(description: "Expected to right values for updating unread count.")
        var isFullfiled = false
        notification.onUpdateIds { objectIds in
            self.sut.threadsUnreadcount([1, 2, 3]) { threadsCountDic in
                let first = threadsCountDic["1"]
                let second = threadsCountDic["2"]
                let third = threadsCountDic["3"]
                if first == 10, second == 20, third == 0, !isFullfiled {
                    isFullfiled = true
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    func test_whenArchive_isArchivedSetTrueInStore() {
        // Given
        let models = [mockModel(id: 1), mockModel(id: 2)]
        sut.insert(models: models)

        // When
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.archive(true, 1)
        }

        // Then
        let exp = expectation(description: "Expected archive value to be true.")
        notification.onUpdateIds { objectIds in
            self.sut.first(with: 1, context: self.sut.viewContext) { entity in
                if entity?.isArchive == true {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    func test_whenUNArchive_isArchivedSetFalseInStore() {
        // Given
        let models = [mockModel(id: 1)]
        sut.insert(models: models)

        // When
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.archive(false, 1)
        }

        // Then
        let exp = expectation(description: "Expected archive value to be false.")
        notification.onUpdateIds { objectIds in
            self.sut.first(with: 1, context: self.sut.viewContext) { entity in
                if entity?.isArchive == false {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    func test_whenIsClosed_isClosedSetTrueInStore() {
        // Given
        let models = [mockModel(id: 1), mockModel(id: 2)]
        sut.insert(models: models)

        // When
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.close(true, 1)
        }

        // Then
        let exp = expectation(description: "Expected thread has been closed.")
        notification.onUpdateIds { objectIds in
            self.sut.first(with: 1, context: self.sut.viewContext) { entity in
                if entity?.closedThread == true {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    func test_whenIsOpnned_isClosedSetFalseInStore() {
        // Given
        let models = [mockModel(id: 1), mockModel(id: 2)]
        sut.insert(models: models)

        // When
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.close(false, 1)
        }

        // Then
        let exp = expectation(description: "Expected thread has been opennd.")
        notification.onUpdateIds { objectIds in
            self.sut.first(with: 1, context: self.sut.viewContext) { entity in
                if entity?.closedThread == false {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    func test_whenPin_isPinSetTrueInStore() {
        // Given
        let models = [mockModel(id: 1), mockModel(id: 2)]
        sut.insert(models: models)

        // When
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.pin(true, 1)
        }

        // Then
        let exp = expectation(description: "Expected the pin has been setted to true.")
        notification.onUpdateIds { objectIds in
            self.sut.first(with: 1, context: self.sut.viewContext) { entity in
                if entity?.pin == true {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    func test_whenUnPin_isPinSetFalseInStore() {
        // Given
        let models = [mockModel(id: 1), mockModel(id: 2)]
        sut.insert(models: models)

        // When
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.pin(false, 1)
        }

        // Then
        let exp = expectation(description: "Expected the pin has been setted to false.")
        notification.onUpdateIds { objectIds in
            self.sut.first(with: 1, context: self.sut.viewContext) { entity in
                if entity?.pin == false {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    func test_whenPin_isPinSetTrueInFetch() {
        // Given
        let models = [mockModel(id: 1), mockModel(id: 2)]
        sut.insert(models: models)

        // When
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.pin(true, 1)
        }

        // Then
        let exp = expectation(description: "Expected the pin has been setted to true inside get threads fetch.")
        notification.onUpdateIds { _ in
            self.sut.fetch(.init()) { entities, _ in
                if let entity = entities.first(where: {$0.id == 1}), entity.pin == true {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    func test_whenMute_isMuteSetTrueInStore() {
        // Given
        let models = [mockModel(id: 1), mockModel(id: 2)]
        sut.insert(models: models)

        // When
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.mute(true, 1)
        }

        // Then
        let exp = expectation(description: "Expected the thread has been muted.")
        notification.onUpdateIds { objectIds in
            self.sut.first(with: 1, context: self.sut.viewContext) { entity in
                if entity?.mute == true {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    func test_whenUNMute_isMuteSetFalseInStore() {
        // Given
        let models = [mockModel(id: 1, mute: nil), mockModel(id: 2)]
        sut.insert(models: models)

        // When
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.mute(false, 1)
        }

        // Then
        let exp = expectation(description: "Expected the thread has been not muted.")
        notification.onUpdateIds { objectIds in
            self.sut.first(with: 1, context: self.sut.viewContext) { entity in
                if entity?.mute == false {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    func test_whenGetAllThreadIds_returnAllIds() {
        // Given
        let models = [mockModel(id: 1), mockModel(id: 2)]
        sut.insert(models: models)

        // When
        let exp = expectation(description: "Expected thread ids return.")
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.fetchIds { threadIds in
                if threadIds.count == 2 {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    func test_whenChangeThreadType_typeHasChangedInStore() {
        // Given
        let models = [mockModel(id: 1, type: .normal)]
        sut.insert(models: models)

        // When

        notification.onInsert { (entities: [CDConversation]) in
            self.sut.changeThreadType(1,.channel)
        }
        let exp = expectation(description: "Expected to change thread type in store to channel.")
        notification.onUpdateIds { _ in
            self.sut.first(with: 1, context: self.sut.viewContext) { entity in
                if let typeValue = entity?.type, ThreadTypes(rawValue: typeValue.intValue) == .channel {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    func test_whenSumAllUnreadCount_itReturnSumOfThreadsUnreadCount() {
        // Given
        let models = [mockModel(id: 1, unreadCount: 10),
                      mockModel(id: 2, unreadCount: 1),
                      mockModel(id: 3, unreadCount: nil),
                      mockModel(id: 4, unreadCount: 20)]
        sut.insert(models: models)

        // When
        let exp = expectation(description: "Expected to get summation of all unreads to be 31.")
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.allUnreadCount { unreadCount in
                if unreadCount == 31 {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    func test_whenSumAllUnreadCountWehnHaveAnException_itReturnZeroUnreadCount() {
        let mock = DefaultMockCacheManager()
        let sut = mock.cache!.conversation!

        // When
        mock.context!.fetchResult = []
        let exp = expectation(description: "Expected to get zero as a result of there is no rows inside the store")
        sut.allUnreadCount { unreadCount in
            if unreadCount == 0 {
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 1)
    }

    func test_whenThereIsNoThreadSumAllUnreadCount_itReturnZero() {
        // When
        let exp = expectation(description: "Expected to get summation of all unreads to be 0.")
        sut.allUnreadCount { unreadCount in
            if unreadCount == 0 {
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 1)
    }

    func test_whenDeleteAThread_itDeletedFromStore() {
        // Given
        let models = [mockModel(id: 1, unreadCount: 10), mockModel(id: 2, unreadCount: 1)]
        sut.insert(models: models)

        // When
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.delete(1)
        }

        // Then
        let exp = expectation(description: "Expected the thread to be deleted from store.")
        notification.onDeletedIds { _ in
            self.sut.first(with: 1, context: self.sut.viewContext) { entity in
                if entity == nil {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    func test_whenFetchWithTitle_itShouldReturnAtLeastOneThread() {
        // Given
        let models = [mockModel(id: 1, title: "Test"),
                      mockModel(id: 2, title: nil),
                      mockModel(id: 2, title: "New"),
                      mockModel(id: 2, title: "Test2")]
        sut.insert(models: models)

        // When
        let exp = expectation(description: "Expected get two threads with the title of Test.")
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.fetch(.init(title: "Test")) { entities, _ in
                if entities.count == 2, !entities.contains(where: {$0.title == nil }) {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    func test_whenFetchWithDescription_itShouldReturnAtLeastOneThread() {
        // Given
        let models = [mockModel(description: "Test", id: 1),
                      mockModel(description: nil, id: 2),
                      mockModel(description: "New", id: 3),
                      mockModel(description: "Test2", id: 4)]
        sut.insert(models: models)

        // When
        let exp = expectation(description: "Expected get two get threads with the description of Test.")
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.fetch(.init(description: "Test")) { entities, _ in
                if entities.count == 2 {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    func test_whenIsGroup_itHasSavedInStore() {
        // Given
        let models = [mockModel(group: true, id: 1)]
        sut.insert(models: models)

        // When
        let exp = expectation(description: "Expected to save and fetch a group thread.")
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.fetch(.init(isGroup: true)) { entities, _ in
                if entities.count == 1 {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    func test_whenGetThreadsWithIds_itReturnThreadsWithRightIds() {
        // Given
        let models = [mockModel(id: 1),
                      mockModel(id: 2),
                      mockModel(id: 3),
                      mockModel(id: 4)
        ]
        sut.insert(models: models)

        // When
        let exp = expectation(description: "Expected to fetch three threads.")
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.fetch(.init(threadIds: [1,2,3])) { entities, _ in
                if entities.map(\.id).map({$0 as! Int}).sorted() == [1,2,3] {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    func test_whenGetThreadsWithType_itReturnThreadsWithRightTypes() {
        // Given
        let models = [mockModel(id: 1, type: .normal),
                      mockModel(id: 2, type: .channel),
                      mockModel(id: 3, type: .ownerGroup),
                      mockModel(id: 4, type: .normal)
        ]
        sut.insert(models: models)

        // When
        let exp = expectation(description: "Expected to fetch two threads with the type of normal.")
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.fetch(.init(type: ThreadTypes.normal.rawValue)) { entities, _ in
                let array = entities.compactMap({$0.type as? Int})
                let typeSet = Set(array)
                if entities.count == 2, typeSet.count == 1, typeSet.first == ThreadTypes.normal.rawValue {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    func test_whenGetThreadsWithArchivedTrue_itReturnAllArchivedThreads() {
        // Given
        let models = [mockModel(id: 1, isArchive: true),
                      mockModel(id: 2, isArchive: nil),
                      mockModel(id: 3, isArchive: false),
                      mockModel(id: 4, isArchive: true)
        ]
        sut.insert(models: models)

        // When
        let exp = expectation(description: "Expected to fetch three threads with two archived set true and one nil.")
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.fetch(.init(archived: true)) { entities, _ in
                let array = entities.map({$0.isArchive as? Bool})
                if entities.count == 3,  array.contains(true) || array.contains(nil) {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    func test_whenGetThreadsWithArchivedFalse_itReturnAllUnArchivedThreads() {
        // Given
        let models = [mockModel(id: 1, isArchive: false),
                      mockModel(id: 2, isArchive: nil),
                      mockModel(id: 3, isArchive: true),
                      mockModel(id: 4, isArchive: false)
        ]
        sut.insert(models: models)

        // When
        let exp = expectation(description: "Expected to fetch three threads with the archived set false.")
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.fetch(.init(archived: false)) { entities, _ in
                let array = entities.map({$0.isArchive as? Bool})
                if entities.count == 3, array.contains(false) || array.contains(nil) {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    func test_whenGetThreadsPinTrumpTime_itReturnPinAtFirstItemOfTheList() {
        // Given
        let models = [mockModel(id: 1, pin: true, time: UInt(Date().advanced(by: 1000).timeIntervalSince1970)),
                      mockModel(id: 2, pin: nil, time: UInt(Date().timeIntervalSince1970)),
                      mockModel(id: 3, pin: false, time: UInt(Date().advanced(by: -1000).timeIntervalSince1970)),
                      mockModel(id: 4, pin: true, time: UInt(Date().advanced(by: -5000).timeIntervalSince1970))
        ]
        sut.insert(models: models)

        // When
        let exp = expectation(description: "Expected to fetch 4 threads with pin threads on top and the first thread is with id 1.")
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.fetch(.init()) { entities, _ in
                if entities.count == 4, entities[0].id == 1, entities[0].pin == true, entities[1].pin == true {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    func test_whenGetThreadIfThereIsNoPin_threadsSortedByTime() {
        // Given
        let models = [mockModel(id: 1, time: UInt(Date().advanced(by: 10000).timeIntervalSince1970)),
                      mockModel(id: 2, time: UInt(Date().timeIntervalSince1970)),
                      mockModel(id: 3, time: UInt(Date().advanced(by: -1000).timeIntervalSince1970)),
                      mockModel(id: 4, time: UInt(Date().advanced(by: -5000).timeIntervalSince1970))
        ]
        sut.insert(models: models)

        // When
        let exp = expectation(description: "Expected to fetch four threads with first thread at list must be with id 1.")
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.fetch(.init()) { entities, _ in
                if entities.count == 4, entities[0].id == 1 {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    func test_whenUpdateLastMessageThreadIdIsNil_theowAnError() {
        // Given
        let models = [mockModel(id: 1, lastMessage: "TEST")]
        sut.insert(models: models)

        // When
        let exp = expectation(description: "Expected to throw an exception when the lastMessageText is nil")
        notification.onInsert { (entities: [CDConversation]) in
            do {
                try self.sut.replaceLastMessage(.init(id: 1), self.sut.viewContext)
            } catch {
                exp.fulfill()
            }
        }

        // Then
        wait(for: [exp], timeout: 1)
    }

    func test_whenUpdateLastMessageVOIsNil_theowAnError() {
        // Given
        let models = [mockModel(id: 1, lastMessage: "TEST")]
        sut.insert(models: models)

        // When
        let exp = expectation(description: "Expected to throw an exception when the lastMessageVO is nil.")
        notification.onInsert { (entities: [CDConversation]) in
            do {
                try self.sut.replaceLastMessage(.init(id: 1, lastMessage: "UPDATED"), self.sut.viewContext)
            } catch {
                exp.fulfill()
            }
        }

        // Then
        wait(for: [exp], timeout: 1)
    }

    func test_whenUpdateLastMessageWhenThreadIsNotExist_insertNewThreadAndSetLastMessageTextAndLastMessageVO() throws {
        // Given
        let insertMSG = Message(threadId: 1, message: "Hi, There")

        // When
        let exp = expectation(description: "Expected to update the last message text and messageVO to be UPDATED.")
        try self.sut.replaceLastMessage(.init(id: 1, lastMessage: insertMSG.message, lastMessageVO: insertMSG), self.sut.viewContext)

        // Then
        notification.onInsert { (entities: [CDConversation]) in
            if let threadEntity = entities.first, threadEntity.lastMessage == "Hi, There", threadEntity.lastMessageVO?.message == "Hi, There" {
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 1)
    }

    func test_whenInsertNewMessage_setLastMessageTextAndLastMessageVO() {
        // Given
        let insertMSG = Message(threadId: 1, message: "Hello")
        let models = [mockModel(id: 1, lastMessage: insertMSG.message, lastMessageVO: insertMSG)]
        sut.insert(models: models)

        // When
        let exp = expectation(description: "Expected to update the last message text to Inserted and set properly.")
        var made = false
        notification.onInsert { (entities: [CDConversation]) in
            if made == false {
                made = true
                let updateLastMSG = Message(threadId: 1, message: "Hi, There")
                try? self.sut.replaceLastMessage(.init(id: 1, lastMessage: updateLastMSG.message, lastMessageVO: updateLastMSG))
            }
        }

        // Then
        var fullfilled = false
        notification.onUpdate { (entities: [CDConversation]) in
            if let threadEntity = entities.first,
               threadEntity.lastMessage == "Hi, There",
               threadEntity.lastMessageVO?.message == "Hi, There",
               fullfilled == false {
                fullfilled = true
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 1)
    }


    func test_whenEditLastMessage_setLastMessageTextAndLastMessageVO() {
        // Given
        let insertMSG = Message(threadId: 1, id: 2, message: "Hello")
        let models = [mockModel(id: 1, lastMessage: insertMSG.message, lastMessageVO: insertMSG)]
        sut.insert(models: models)

        // When
        let exp = expectation(description: "Expected to update the last message text to UPDATED.")
        notification.onInsert { (entities: [CDConversation]) in
            let updateLastMSG = Message(threadId: 1, id: 2, message: "Hi, There")
            try? self.sut.replaceLastMessage(.init(id: 1, lastMessage: updateLastMSG.message, lastMessageVO: updateLastMSG), self.sut.viewContext)
        }

        // Then
        var fullfilled = false
        notification.onUpdate { (entities: [CDConversation]) in
            if let threadEntity = entities.first,
               threadEntity.lastMessage == "Hi, There",
               threadEntity.lastMessageVO?.message == "Hi, There",
               threadEntity.lastMessageVO?.id == 2,
               fullfilled == false {
                fullfilled = true
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 1)
    }

    func test_whenInsertAThreadWithLastMessageVO_itHasLastParticipantInStore() {
        // Given
        let thread = mockModel(id: 1)
        let participant = Participant(firstName: "John", id: 1, conversation: thread)
        let lastMessageVO = Message(threadId: 1, id: 2, message: "Hello", participant: participant)
        thread.lastMessageVO = lastMessageVO
        let models = [thread]
        sut.insert(models: models)

        // When
        let exp = expectation(description: "Expected to have a participant object on LastMessageVO.")
        notification.onInsert { (entities: [CDConversation]) in
            if let participant = entities.first?.lastMessageVO?.participant, participant.firstName == "John" {
                exp.fulfill()
            }
        }

        // Then
        wait(for: [exp], timeout: 1)
    }


    func test_whenIdInModelIsNil_nothingInsertInStore() {
        // Given
        let model = mockModel(id: nil)

        // When
        sut.insert(model: model, context: sut.viewContext)

        // Then
        let exp = expectation(description: "Expected to nothing insert in store.")
        sut.all{ entities in
            if entities.count == 0 {
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 1)
    }

    func test_whenSeenAMessage_itUpdateLastSeenMessageTime() {
        // Given
        let lastMessageVO = Message(threadId: 1, id: 2, message: "Hello")

        sut.insert(models: [mockModel(id: 1,
                                      lastSeenMessageId: 1,
                                      lastSeenMessageNanos: 1,
                                      lastSeenMessageTime: 1,
                                      lastMessageVO: lastMessageVO)
        ])

        // When
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.seen(threadId: 1, messageId: 2)
        }

        // Then
        let exp = expectation(description: "Expected to update lastSeenMessageId, lastSeenMessageTime, lastSeenMessageNanos.")
        notification.onUpdateIds { objectIds in
            self.sut.first(with: 1, context: self.sut.viewContext) { entity in
                if let entity = entity, entity.lastSeenMessageId == 2, entity.lastSeenMessageTime?.intValue ?? 0 > 1, entity.lastSeenMessageTime?.intValue ?? 0 > 1 {
                    exp.fulfill()
                }
            }
        }

        wait(for: [exp], timeout: 1)
    }

    func test_whenAMessageDeliveredToPartner_itUpdateProperties() {
        // Given
        let lastMessageVO = Message(threadId: 1, id: 2, message: "Hello")

        sut.insert(models: [mockModel(id: 1,
                                      partnerLastDeliveredMessageId: 1,
                                      partnerLastDeliveredMessageTime: 1,
                                      partnerLastSeenMessageNanos: 1,
                                      lastMessageVO: lastMessageVO)
        ])

        // When
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.partnerDeliver(threadId: 1, messageId: 2, messageTime: UInt(Date().timeIntervalSince1970))
        }

        // Then
        let exp = expectation(description: "Expected to update partnerLastDeliveredMessageTime, partnerLastDeliveredMessageNanos, partnerLastDeliveredMessageId.")
        notification.onUpdateIds { objectIds in
            self.sut.first(with: 1, context: self.sut.viewContext) { entity in
                if let entity = entity, entity.partnerLastDeliveredMessageId == 2, entity.partnerLastDeliveredMessageTime?.intValue ?? 0 > 1, entity.partnerLastDeliveredMessageNanos?.intValue ?? 0 > 1 {
                    exp.fulfill()
                }
            }
        }

        wait(for: [exp], timeout: 1)
    }

    func test_whenAMessageSeenByPartner_itUpdateProperties() {
        // Given
        let lastMessageVO = Message(threadId: 1, id: 2, message: "Hello")
        sut.insert(models: [mockModel(id: 1, lastMessageVO: lastMessageVO)])

        // When
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.partnerSeen(threadId: 1, messageId: 2, messageTime: UInt(Date().timeIntervalSince1970))
        }

        // Then
        let exp = expectation(description: "Expected to update all delivered fileds and seen fileds.")
        notification.onUpdateIds { objectIds in
            self.sut.first(with: 1, context: self.sut.viewContext) { entity in
                if let entity = entity,
                   entity.partnerLastSeenMessageId == 2,
                   entity.partnerLastSeenMessageTime?.intValue ?? 0 > 1,
                   entity.partnerLastSeenMessageNanos?.intValue ?? 0 > 1,
                   entity.partnerLastDeliveredMessageId == 2,
                   entity.partnerLastDeliveredMessageTime?.intValue ?? 0 > 1,
                   entity.partnerLastDeliveredMessageNanos?.intValue ?? 0 > 1
                {
                    exp.fulfill()
                }
            }
        }

        wait(for: [exp], timeout: 1)
    }

    func test_whenPinAMessage_itSetPinToTrue() {
        // Given
        let message = Message(threadId: 1, id: 2, message: "Hello")

        // When
        sut.insert(models: [mockModel(id: 1, pinMessages: [message])])

        // Then
        let exp = expectation(description: "Expected to set pin to true.")
        notification.onInsert { (entities: [CDConversation]) in
            if let entity = (entities.first?.pinMessages?.allObjects as? [CDMessage])?.first, entity.pinned == true {
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 1)
    }

    private func mockModel(admin: Bool? = false,
                           canEditInfo: Bool? = false,
                           canSpam: Bool? = false,
                           closedThread: Bool? = false,
                           description: String? = "Thread Conversation",
                           group: Bool? = false,
                           id: Int? = 1,
                           image: String? = nil,
                           joinDate: Int? = nil,
                           lastMessage: String? = nil,
                           lastParticipantImage: String? = nil,
                           lastParticipantName: String? = nil,
                           lastSeenMessageId: Int? = nil,
                           lastSeenMessageNanos: UInt? = nil,
                           lastSeenMessageTime: UInt? = nil,
                           mentioned: Bool? = nil ,
                           metadata: String? = nil,
                           mute: Bool? = nil,
                           participantCount: Int? = 0,
                           partner: Int? = nil,
                           partnerLastDeliveredMessageId: Int? = nil,
                           partnerLastDeliveredMessageNanos: UInt? = nil,
                           partnerLastDeliveredMessageTime: UInt? = nil,
                           partnerLastSeenMessageId: Int? = nil,
                           partnerLastSeenMessageNanos: UInt? = nil,
                           partnerLastSeenMessageTime: UInt? = nil,
                           pin: Bool? = nil,
                           time: UInt = UInt(Date().millisecondsSince1970),
                           title: String? = "Thread Title",
                           type: ThreadTypes? = .normal,
                           unreadCount: Int? = nil,
                           uniqueName: String? = nil,
                           userGroupHash: String? = nil,
                           inviter: Participant? = nil,
                           lastMessageVO: Message? = nil,
                           participants: [Participant]? = nil,
                           pinMessages: [Message]? = nil,
                           isArchive: Bool? = nil) -> Conversation {
        return Conversation(admin: admin,
                            canEditInfo: canEditInfo,
                            canSpam: canSpam,
                            closedThread: closedThread,
                            description: description,
                            group: group,
                            id: id,
                            image: image,
                            joinDate: joinDate,
                            lastMessage: lastMessage,
                            lastParticipantImage: lastParticipantImage,
                            lastParticipantName: lastParticipantName,
                            lastSeenMessageId: lastSeenMessageId,
                            lastSeenMessageNanos: lastSeenMessageNanos,
                            lastSeenMessageTime: lastSeenMessageTime,
                            mentioned: mentioned,
                            metadata: metadata,
                            mute: mute,
                            participantCount: participantCount,
                            partner: partner,
                            partnerLastDeliveredMessageId: partnerLastDeliveredMessageId,
                            partnerLastDeliveredMessageNanos: partnerLastDeliveredMessageNanos,
                            partnerLastDeliveredMessageTime: partnerLastDeliveredMessageTime,
                            partnerLastSeenMessageId: partnerLastSeenMessageId,
                            partnerLastSeenMessageNanos: partnerLastSeenMessageNanos,
                            partnerLastSeenMessageTime: partnerLastSeenMessageTime,
                            pin: pin,
                            time: time,
                            title: title,
                            type: type,
                            unreadCount: unreadCount,
                            uniqueName: uniqueName,
                            userGroupHash: userGroupHash,
                            inviter: inviter,
                            lastMessageVO: lastMessageVO,
                            participants: participants,
                            pinMessages: pinMessages,
                            isArchive: isArchive)
    }

    func log(message: String, persist: Bool, error: Error?) {

    }
}
