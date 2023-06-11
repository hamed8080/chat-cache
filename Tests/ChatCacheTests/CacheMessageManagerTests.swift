import XCTest
import ChatModels
import CoreData
import Combine
@testable import ChatCache

@available(iOS 13.0, *)
final class CacheMessageManagerTests: XCTestCase, CacheLogDelegate {

    private var sut: CacheMessageManager!
    private var cache: CacheManager!
    private var logExpectation = XCTestExpectation(description: "Expected to call log delegate")
    private var notification: MockObjectContextNotificaiton!
    private var objectId: NSManagedObjectID?
    private var cancelables = Set<AnyCancellable>()

    override func setUpWithError() throws {
        cache = CacheManager(persistentManager: PersistentManager(logger: self))
        cache.switchToContainer(userId: 1)
        sut = cache.message
        notification = MockObjectContextNotificaiton(context: sut.viewContext)
    }

    public func test_whenPin_pinnedIsSetTrueInStore() {
        // Given
        let msg = mockModel(threadId: 1, id: 2, message: "Hello")
        sut.insert(models: [msg])

        // When
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.pin(true, 1, 2)
        }

        // Then
        let exp = expectation(description: "Expected to update pinned value to true in message entity.")
        notification.onUpdateIds { objectIds in
            self.sut.first(with: 2, context: self.sut.viewContext) { entity in
                if entity?.pinned == true {
                    exp.fulfill()
                }
            }
        }

        wait(for: [exp], timeout: 1)
    }

    public func test_whenUNPin_pinnedIsSetFalseInStore() {
        // Given
        let msg = mockModel(threadId: 1, id: 2, message: "Hello")
        sut.insert(models: [msg])

        // When
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.pin(false, 1, 2)
        }

        // Then
        let exp = expectation(description: "Expected to update pinned value to false in message entity.")
        notification.onUpdateIds { objectIds in
            self.sut.first(with: 2, context: self.sut.viewContext) { entity in
                if entity?.pinned == false {
                    exp.fulfill()
                }
            }
        }

        wait(for: [exp], timeout: 1)
    }

    public func test_whenDeleteAMessage_messageIsDeletedFromStore() {
        // Given
        let msg = mockModel(threadId: 1, id: 2, message: "Hello")
        sut.insert(models: [msg])

        // When
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.delete(2)
        }

        // Then
        let exp = expectation(description: "Expected to delete a message entity from the store.")
        notification.onDeletedIds() { objectIds in
            self.sut.find(1, 2) { entity in
                if entity == nil {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    public func test_whenDeleteAMessageWithMessageIdAndThreadId_messageIsDeletedFromStore() {
        // Given
        let msg = mockModel(threadId: 1, id: 2, message: "Hello")
        sut.insert(models: [msg])

        // When
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.delete(1, 2)
        }

        // Then
        let exp = expectation(description: "Expected to delete a message entity from the store.")
        notification.onDeletedIds() { objectIds in
            self.sut.find(1, 2) { entity in
                if entity == nil {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    public func test_whenClearHistory_deleteAllMessagesForAThread() {
        // Given
        let msg1 = mockModel(threadId: 1, id: 1, message: "Hello1")
        let msg2 = mockModel(threadId: 1, id: 2, message: "Hello2")
        sut.insert(models: [msg1, msg2])

        // When
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.clearHistory(threadId: 1)
        }

        // Then
        let exp = expectation(description: "Expected to delete all messages inside a thread.")
        notification.onDeletedIds() { objectIds in
            self.sut.fetch(.init(threadId: 1)) { entites, total in
                if entites.count == 0, total == 0, objectIds.count == 2 {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    public func test_whenSeenLastMessage_allPreviousMessagesSetSeenTrue() {
        // Given
        let me = 1
        let msg1 = mockModel(threadId: 1, id: 1, message: "Hello1", ownerId: me)
        let msg2 = mockModel(threadId: 1, id: 2, message: "Hello2", ownerId: me)
        let msg3 = mockModel(threadId: 1, id: 3, message: "Hello3", ownerId: me)
        sut.insert(models: [msg1, msg2, msg3])

        // When
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.seen(threadId: 1, messageId: 3, mineUserId: 2)
        }

        // Then
        let exp = expectation(description: "Expected to set all prior messages seen property to true.")
        notification.onUpdateIds { objectIds in
            self.sut.fetch(.init(threadId: 1)) { entites, total in
                let seens = entites.filter{ $0.seen == true }
                if entites.count == 3, objectIds.count == 3, seens.count == 3 {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    public func test_seenLastMessageWhenUserIsMine_shouldNotUpdateSeen() {
        // Given
        let me = 1
        let msg1 = mockModel(threadId: 1, id: 1, message: "Hello1", ownerId: me)
        let msg2 = mockModel(threadId: 1, id: 2, message: "Hello2", ownerId: me)
        let msg3 = mockModel(threadId: 1, id: 3, message: "Hello3", ownerId: me)
        sut.insert(models: [msg1, msg2, msg3])

        // When
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.seen(threadId: 1, messageId: 3, mineUserId: me)
            NotificationCenter.default.post(Notification(name: .NSManagedObjectContextDidMergeChangesObjectIDs, object: self.sut.viewContext))
        }

        // Then
        let exp = expectation(description: "Expected to not update seen properties.")
        var fullFilled = false
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidMergeChangesObjectIDs)
            .sink { notification in
                self.sut.fetch(.init(threadId: 1)) { entites, total in
                    if !entites.map(\.seen).contains(true), !fullFilled {
                        fullFilled = true
                        exp.fulfill()
                    }
                }
            }
            .store(in: &cancelables)
        wait(for: [exp], timeout: 1)
    }

    public func test_deliverAMessageToPartner_shouldUpdateDeliveredToTrue() {
        // Given
        let me = 1
        let msg1 = mockModel(threadId: 1, id: 1, message: "Hello1", ownerId: me)
        let msg2 = mockModel(threadId: 1, id: 2, message: "Hello2", ownerId: me)
        let msg3 = mockModel(threadId: 1, id: 3, message: "Hello3", ownerId: me)
        sut.insert(models: [msg1, msg2, msg3])

        // When
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.partnerDeliver(threadId: 1, messageId: 3)
        }

        // Then
        let exp = expectation(description: "Expected to set delivered to true.")
        notification.onUpdateIds { objectIds in
            self.sut.fetch(.init(threadId: 1)) { entities, total in
                let delivered = entities.filter{ $0.delivered == true }
                if entities.count == 3, objectIds.count == 3, delivered.count == 3 {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    public func test_partnerSeenAMessageAMessageToPartner_shouldUpdateSeenToTrue() {
        // Given
        let me = 1
        let msg1 = mockModel(threadId: 1, id: 1, message: "Hello1", ownerId: me)
        let msg2 = mockModel(threadId: 1, id: 2, message: "Hello2", ownerId: me)
        let msg3 = mockModel(threadId: 1, id: 3, message: "Hello3", ownerId: me)
        let msg4 = mockModel(threadId: 1, id: 4, message: "Hello4", ownerId: 2)
        let msg5 = mockModel(threadId: 1, delivered: false, id: 5, message: "Hello5", ownerId: 2)
        sut.insert(models: [msg1, msg2, msg3, msg4, msg5])

        // When
        notification.onInsert { (entities: [CDConversation]) in
            self.sut.partnerSeen(threadId: 1, messageId: 5, mineUserId: me)
        }

        // Then
        let exp = expectation(description: "Expected to set seen and delivered only for messages that the owner of message is mine to true for partner seen.")
        notification.onUpdateIds { objectIds in
            self.sut.fetch(.init(threadId: 1)) { entities, total in
                if entities.count == 5, entities.filter({ $0.seen == true }).count == 3, entities.filter({ $0.delivered == true }).count == 3 {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    public func test_fetchMessagesBetweenTimes_itReturnOnlyMessagesFromStartToFinish() {
        // Given
        let time = UInt(Date().addingTimeInterval(0).timeIntervalSince1970)
        let msg1 = mockModel(threadId: 1, id: 1, message: "Hello1", time: time)
        let msg2 = mockModel(threadId: 1, id: 2, message: "Hello2", time: time + 100)
        let msg3 = mockModel(threadId: 1, id: 3, message: "Hello3", time: time + 200)
        sut.insert(models: [msg1, msg2, msg3])

        // Then
        let exp = expectation(description: "Expected to fetch only messages from start to Finish")
        notification.onInsert { (_: [CDConversation]) in
            self.sut.fetch(.init(fromTime: time, toTime: time + 100, threadId: 1)) { entities, total in
                if entities.count == 2, !entities.contains(where: {$0.id == 3 }) {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    public func test_fetchMessagesWithMessageType_itReturnWithOnlyOneMessageType() {
        // Given
        let msg1 = mockModel(threadId: 1, id: 1, message: "Hello1", messageType: .text)
        let msg2 = mockModel(threadId: 1, id: 2, message: "Hello2", messageType: .text)
        let msg3 = mockModel(threadId: 1, id: 3, message: "Hello3", messageType: .picture)
        sut.insert(models: [msg1, msg2, msg3])

        // Then
        let exp = expectation(description: "Expected to fetch only messages with one messageType")
        notification.onInsert { (_: [CDConversation]) in
            self.sut.fetch(.init(messageType: MessageType.text.rawValue, threadId: 1)) { entities, total in
                if entities.count == 2, !entities.contains(where: {$0.id == 3 }) {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    public func test_fetchAMessageWithANUniqueId_itReturnOnlyOneMessage() {
        // Given
        let uniqueId = UUID().uuidString
        let msg1 = mockModel(threadId: 1, id: 1, message: "Hello1", uniqueId: uniqueId)
        let msg2 = mockModel(threadId: 1, id: 2, message: "Hello2", uniqueId: "TEST")
        sut.insert(models: [msg1, msg2])

        // Then
        let exp = expectation(description: "Expected to fetch only one message with uniqueId fetch request.")
        notification.onInsert { (_: [CDConversation]) in
            self.sut.fetch(.init(uniqueIds: [uniqueId], threadId: 1)) { entities, total in
                if entities.count == 1, !entities.contains(where: {$0.id == 2 }), entities.first?.uniqueId == uniqueId {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    public func test_fetchMessagesWithArrayUniqueId_itReturnMessages() {
        // Given
        let uniqueId1 = UUID().uuidString
        let uniqueId2 = UUID().uuidString
        let msg1 = mockModel(threadId: 1, id: 1, message: "Hello1", uniqueId: uniqueId1)
        let msg2 = mockModel(threadId: 1, id: 2, message: "Hello2", uniqueId: uniqueId2)
        let msg3 = mockModel(threadId: 1, id: 3, message: "Hello3", uniqueId: "TEST")
        sut.insert(models: [msg1, msg2, msg3])

        // Then
        let exp = expectation(description: "Expected to fetch only messages within uniqueIds fetch request.")
        notification.onInsert { (_: [CDConversation]) in
            self.sut.fetch(.init(uniqueIds: [uniqueId1, uniqueId2], threadId: 1)) { entities, total in
                if entities.count == 2, !entities.contains(where: {$0.id == 3 }) {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    public func test_fetchMessagesWithMessageId_itReturnOnlyOneMessage() {
        // Given
        let msg1 = mockModel(threadId: 1, id: 1, message: "Hello1")
        let msg2 = mockModel(threadId: 1, id: 2, message: "Hello2")
        let msg3 = mockModel(threadId: 1, id: 3, message: "Hello3")
        sut.insert(models: [msg1, msg2, msg3])

        // Then
        let exp = expectation(description: "Expected to fetch only one message with id fetch request.")
        notification.onInsert { (_: [CDConversation]) in
            self.sut.fetch(.init(messageId: 1, threadId: 1)) { entities, total in
                if entities.count == 1, !entities.contains(where: { $0.id == 3 || $0.id  == 2 }) {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    public func test_fetchMessagesWithMessageString_itReturnOnlyOneMessagesContainSameString() {
        // Given
        let msg1 = mockModel(threadId: 1, id: 1, message: "Hello1")
        let msg2 = mockModel(threadId: 1, id: 2, message: "Hello2")
        let msg3 = mockModel(threadId: 1, id: 3, message: "Message")
        sut.insert(models: [msg1, msg2, msg3])

        // Then
        let exp = expectation(description: "Expected to fetch only one messages that contains message string.")
        notification.onInsert { (_: [CDConversation]) in
            self.sut.fetch(.init(query: "Hello", threadId: 1)) { entities, total in
                if entities.count == 2, !entities.contains(where: { $0.id == 3 }) {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    public func test_fetchMessagesWithOrderDescending_itReturnOrderedWithTime() {
        // Given
        let time = UInt(Date().addingTimeInterval(0).timeIntervalSince1970)
        let msg1 = mockModel(threadId: 1, id: 1, message: "Hello1", time: time)
        let msg2 = mockModel(threadId: 1, id: 2, message: "Hello2", time: time + 100)
        let msg3 = mockModel(threadId: 1, id: 3, message: "Message", time: time + 200)
        sut.insert(models: [msg1, msg2, msg3])

        // Then
        let exp = expectation(description: "Expected to get a descending ordered array.")
        notification.onInsert { (_: [CDConversation]) in
            self.sut.fetch(.init(threadId: 1, order: ChatCache.Ordering.desc.rawValue)) { entities, total in
                if entities.count == 3, entities[0].id == 3, entities[1].id == 2, entities[2].id == 1 {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    public func test_fetchMessagesWithOrderAscending_itReturnOrderedWithTime() {
        // Given
        let time = UInt(Date().addingTimeInterval(0).timeIntervalSince1970)
        let msg1 = mockModel(threadId: 1, id: 1, message: "Hello1", time: time)
        let msg2 = mockModel(threadId: 1, id: 2, message: "Hello2", time: time + 100)
        let msg3 = mockModel(threadId: 1, id: 3, message: "Message", time: time + 200)
        sut.insert(models: [msg1, msg2, msg3])

        // Then
        let exp = expectation(description: "Expected to get a ascending ordered array.")
        notification.onInsert { (_: [CDConversation]) in
            self.sut.fetch(.init(threadId: 1, order: ChatCache.Ordering.asc.rawValue)) { entities, total in
                if entities.count == 3, entities[0].id == 1, entities[1].id == 2, entities[2].id == 3 {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    public func test_fetcMentionMessagesInAThread_itReturnOnlyMentionedMessages() {
        // Given
        let msg1 = mockModel(threadId: 1, id: 1, mentioned: true, message: "Hello1")
        let msg2 = mockModel(threadId: 1, id: 2, mentioned: true, message: "Hello2")
        let msg3 = mockModel(threadId: 1, id: 3, mentioned: false, message: "Message1")
        let msg4 = mockModel(threadId: 1, id: 4, mentioned: nil, message: "Message2")
        sut.insert(models: [msg1, msg2, msg3, msg4])

        // Then
        let exp = expectation(description: "Expected to get mentined messages.")
        notification.onInsert { (_: [CDConversation]) in
            self.sut.getMentions(threadId: 1) { entities, _ in
                if entities.count == 2, !entities.contains(where: {$0.id == 3 || $0.id == 4}) {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 1)
    }

    private func mockModel(
        threadId: Int? = nil,
        deletable: Bool? = nil,
        delivered: Bool? = nil,
        editable: Bool? = nil,
        edited: Bool? = nil,
        id: Int? = nil,
        mentioned: Bool? = nil,
        message: String? = nil,
        messageType: MessageType? = nil,
        metadata: String? = nil,
        ownerId: Int? = nil,
        pinned: Bool? = nil,
        previousId: Int? = nil,
        seen: Bool? = nil,
        systemMetadata: String? = nil,
        time: UInt? = nil,
        timeNanos: UInt? = nil,
        uniqueId: String? = nil,
        conversation: Conversation? = Conversation(id: 1),
        forwardInfo: ForwardInfo?  = nil,
        participant: Participant? = nil,
        replyInfo: ReplyInfo? = nil,
        pinTime: UInt? = nil,
        notifyAll: Bool? = nil) -> Message {
        return Message(threadId: threadId,
                       deletable: deletable,
                       delivered: delivered,
                       editable: editable,
                       edited: edited,
                       id: id,
                       mentioned: mentioned,
                       message: message,
                       messageType: messageType,
                       metadata: metadata,
                       ownerId: ownerId,
                       pinned: pinned,
                       previousId: previousId,
                       seen: seen,
                       systemMetadata: systemMetadata,
                       time: time,
                       timeNanos: timeNanos,
                       uniqueId: uniqueId,
                       conversation: conversation,
                       forwardInfo: forwardInfo,
                       participant: participant,
                       replyInfo: replyInfo,
                       pinTime: pinTime,
                       notifyAll: notifyAll)
    }

    func log(message: String, persist: Bool, error: Error?) {

    }
}
