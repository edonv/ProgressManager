//
//  ProgressManager.swift
//
//
//  Created by Edon Valdman on 10/17/23.
//

import Foundation

/// A class to make dealing with [`Progress`](https://developer.apple.com/documentation/foundation/progress) objects and child `Progress` objects just a bit more straightforward and easy to work with.
public final class ProgressManager<ChildTaskKey: Hashable> {
    /// The primary [`Progress`](https://developer.apple.com/documentation/foundation/progress) object.
    public let parent: Progress
    
    /// A `Dictionary` used to store child `Progress` objects.
    public let childTasks: [ChildTaskKey: Progress]
    
    /// An easy way to acccess the child `Progress` objects stored in ``childTasks``.
    /// - Parameter childKey: The key associated with the child `Progress` object to return.
    /// - Returns: The child `Progress` object associated with the provided key, if there is one. Otherwise, `nil`.
    public subscript(_ childKey: ChildTaskKey) -> Progress? {
        childTasks[childKey]
    }
    
    /// Creates a new ``ProgressManager``, automatically creating `Progress` objects to manage child tasks.
    /// - Parameters:
    ///   - childTaskUnitCounts: A `Dictionary` describing how many units need to be completed within each child task.
    ///   - childTaskUnitCountsInParent: A `Dictionary` describing how many units each child task is worth in the parent `Progress`. If the parameter is `nil`, all child tasks will default to the same number of units as its value in `childTaskUnitCounts`. The tasks of any missing keys will similarly default to the count in `childTaskUnitCounts`.
    public init(childTaskUnitCounts: [ChildTaskKey: Int64], childTaskUnitCountsInParent: [ChildTaskKey: Int64]? = nil) {
        let totalParentUnitCount: Int64 = childTaskUnitCounts.reduce(into: 0) { updatingUnitCount, countKVP in
            updatingUnitCount += childTaskUnitCountsInParent?[countKVP.key] ?? countKVP.value
        }
        
        self.parent = Progress(totalUnitCount: totalParentUnitCount)
        
        self.childTasks = childTaskUnitCounts.reduce(into: [:]) { [parent] dict, countKVP in
            dict[countKVP.key] = Progress(totalUnitCount: countKVP.value,
                                          parent: parent,
                                          pendingUnitCount: childTaskUnitCountsInParent?[countKVP.key] ?? countKVP.value)
        }
    }
    
    /// Creates a new ``ProgressManager``, automatically creating `Progress` objects to manage child tasks.
    ///
    /// - Note: There is no practical difference between this initializer and ``init(childTaskUnitCounts:childTaskUnitCountsInParent:)``. The only difference is that because you enter the generic `ChildTaskKey` type in this one, you can use the keys with dot syntax to get enum cases or constants when filling in the other parameters.
    /// - Parameters:
    ///   - type: The type to use as keys for ``childTasks``.
    ///   - childTaskUnitCounts: A `Dictionary` describing how many of each child task there should be.
    ///   - childTaskUnitCountsInParent: A `Dictionary` describing how many units each child task is worth in the parent `Progress`. If the parameter is `nil`, all child tasks will default to the same number of units as its value in `childTaskUnitCounts`. The tasks of any missing keys will similarly default to the count in `childTaskUnitCounts`.
    public convenience init(_ type: ChildTaskKey.Type, childTaskUnitCounts: [ChildTaskKey: Int64], childTaskUnitCountsInParent: [ChildTaskKey: Int64]? = nil) {
        self.init(childTaskUnitCounts: childTaskUnitCounts, childTaskUnitCountsInParent: childTaskUnitCountsInParent)
    }
}

// MARK: - Updating Child Task Progress

extension ProgressManager {
    /// Sets the `totalUnitCount` on the child task with the provided value. If there isn't a child task associated with the provided key, nothing happens.
    ///
    /// This won't change how many units of the ``parent`` `Progress` this child will be associated with.
    /// - Parameters:
    ///   - newChildTotalUnitCount: The new `totalUnitCount` for the child task associated with the provided key.
    ///   - key: The key of the child task whose `totalUnitCount` should be updated.
    public func setChildTaskTotalUnitCount(_ newChildTotalUnitCount: Int64, forChildTask key: ChildTaskKey) {
        childTasks[key]?.totalUnitCount = newChildTotalUnitCount
    }
    
    /// Sets the [`completedUnitCount`](https://developer.apple.com/documentation/foundation/progress/1407934-completedunitcount) property of the child task with the associated key to the provided value.
    /// - Parameters:
    ///   - completedUnitCount: The new count of completed units for the child task associated with the provided key.
    ///   - key: The key of a child task to update.
    public func setCompletedUnitCount(_ completedUnitCount: Int64, forChildTask key: ChildTaskKey) {
        childTasks[key]?.completedUnitCount = completedUnitCount
    }
    
    /// Updates the [`completedUnitCount`](https://developer.apple.com/documentation/foundation/progress/1407934-completedunitcount) property of the child task with the associated key by adding the provided value to the current value.
    /// - Parameters:
    ///   - newlyCompletedUnitCountToAdd: A count of completed units to add to the current value of the child task associated with the provided key.
    ///   - key: The key of a child task to update.
    public func addToCompletedUnitCount(_ newlyCompletedUnitCountToAdd: Int64, forChildTask key: ChildTaskKey) {
        childTasks[key]?.completedUnitCount += newlyCompletedUnitCountToAdd
    }
    
    /// Updates the [`completedUnitCount`](https://developer.apple.com/documentation/foundation/progress/1407934-completedunitcount) property of the child task with the associated key by calling the provided closure.
    /// - Parameters:
    ///   - key: The key of a child task to update.
    ///   - updateClosure: A closure that should return an updated current count of completed units.
    ///   - currentValue: The current count of completed units.
    public func updateCompletedUnitCount(forChildTask key: ChildTaskKey, updateClosure: (_ currentValue: Int64) -> Int64) {
        guard let childProgress = childTasks[key] else { return }
        childProgress.completedUnitCount = updateClosure(childProgress.completedUnitCount)
    }
}

// MARK: - Sendable Conformance

extension ProgressManager: Sendable where ChildTaskKey: Sendable {}

// MARK: - CaseIterable Key Init

extension ProgressManager where ChildTaskKey: CaseIterable {
    /// Creates an empty ``ProgressManager``, automatically creating `Progress` objects to manage child tasks.
    ///
    /// This initializer creates the `ProgressManager` from all cases of `ChildTaskKey`, each child task starting with `totalUnitCount` values of `1`, as well as setting every child task as fully complete. ``setChildTaskTotalUnitCount(_:forChildTask:)`` can be used after the fact to set `totalUnitCount`. This initializer is intended to be used when info on child tasks might not be available yet.
    /// - Parameters:
    ///   - type: The type to use as keys for ``childTasks``.
    ///   - childTaskUnitCountsInParent: A `Dictionary` describing how many units each child task is worth in the parent `Progress`. If the parameter is `nil`, all child tasks will default to `1`. The tasks of any missing keys will similarly default to `1`.
    public convenience init(_ type: ChildTaskKey.Type, childTaskUnitCountsInParent: [ChildTaskKey: Int64]? = nil) {
        // Give all child tasks a total unit count of 1
        let childTaskUnitCounts: [ChildTaskKey: Int64] = type.allCases.reduce(into: [:]) { partialResult, key in
            partialResult[key] = 1
        }
        
        // Set child tasks' associated unit count in the parent, but default to 1
        let childTaskUnitCountsInParentTweaked: [ChildTaskKey: Int64] = type.allCases.reduce(into: [:]) { partialResult, key in
            partialResult[key] = childTaskUnitCountsInParent?[key] ?? 1
        }
        
        self.init(childTaskUnitCounts: childTaskUnitCounts, childTaskUnitCountsInParent: childTaskUnitCountsInParentTweaked)
        
        // Set all child tasks to be complete
        for progress in childTasks.values {
            progress.completedUnitCount = 1
        }
    }
}

extension ProgressManager: CustomStringConvertible {
    public var description: String {
        let parent = "Parent progress: \(parent.completedUnitCount) / \(parent.totalUnitCount)"
        var children = childTasks.map { (key, childProgress) in
            "Child progress (\(key)): \(childProgress.completedUnitCount) / \(childProgress.totalUnitCount)"
        }
        
        children.insert(parent, at: 0)
        return children.joined(separator: "\n")
    }
}

// MARK: - Subscribing to Changes in Parent/Child Progress
#if canImport(Combine)
import Combine

extension ProgressManager {
    /// Publishes changes to [`fractionCompleted`](https://developer.apple.com/documentation/foundation/progress/1408579-fractioncompleted) on ``parent``.
    ///
    /// - Note: This publisher updates continuously as work progresses for all child tasks.
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    public var fractionCompletedPublisher: AnyPublisher<Double, Never> {
        parent.publisher(for: \.fractionCompleted)
            .eraseToAnyPublisher()
    }
    
    /// Publishes changes to [`totalUnitCount`](https://developer.apple.com/documentation/foundation/progress/1410940-totalunitcount) on ``parent``.
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    public var totalUnitCountPublisher: AnyPublisher<Int64, Never> {
        parent.publisher(for: \.totalUnitCount)
            .eraseToAnyPublisher()
    }
    
    /// Publishes changes to [`completedUnitCount`](https://developer.apple.com/documentation/foundation/progress/1407934-completedunitcount) on ``parent``.
    ///
    /// - Note: This publisher only updates when each child task is `100%` complete.
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    public var completedUnitCountPublisher: AnyPublisher<Int64, Never> {
        parent.publisher(for: \.completedUnitCount)
            .eraseToAnyPublisher()
    }
    
    /// Publishes changes to [`fractionCompleted`](https://developer.apple.com/documentation/foundation/progress/1408579-fractioncompleted) on the child task (from ``childTasks``) associated with `childKey` (if there is one).
    ///
    /// If there isn't a child task matching the key, the returned `Publisher` will return `nil` then finish.
    /// - Note: This publisher updates continuously as work progresses for the child task.
    /// - Parameter childKey: The key of a child task from which to get a publisher (if such a child task exists).
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    public func fractionCompletedPublisher(forChild childKey: ChildTaskKey) -> AnyPublisher<Double?, Never> {
        if let child = childTasks[childKey] {
            return child.publisher(for: \.fractionCompleted)
                .map { $0 as Double? }
                .eraseToAnyPublisher()
        } else {
            return Just(nil)
                .eraseToAnyPublisher()
        }
    }
    
    /// Publishes changes to [`totalUnitCount`](https://developer.apple.com/documentation/foundation/progress/1410940-totalunitcount) on the child task (from ``childTasks``) associated with `childKey` (if there is one).
    ///
    /// If there isn't a child task matching the key, the returned `Publisher` will return `nil` then finish.
    /// - Parameter childKey: The key of a child task from which to get a publisher (if such a child task exists).
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    public func totalUnitCountPublisher(forChild childKey: ChildTaskKey) -> AnyPublisher<Int64?, Never> {
        if let child = childTasks[childKey] {
            return child.publisher(for: \.totalUnitCount)
                .map { $0 as Int64? }
                .eraseToAnyPublisher()
        } else {
            return Just(nil)
                .eraseToAnyPublisher()
        }
    }
    
    /// Publishes changes to [`completedUnitCount`](https://developer.apple.com/documentation/foundation/progress/1407934-completedunitcount) on the child task (from ``childTasks``) associated with `childKey` (if there is one).
    ///
    /// If there isn't a child task matching the key, the returned `Publisher` will return `nil` then finish.
    /// - Note: This publisher only updates when the child task is `100%` complete.
    /// - Parameter childKey: The key of a child task from which to get a publisher (if such a child task exists).
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    public func completedUnitCountPublisher(forChild childKey: ChildTaskKey) -> AnyPublisher<Int64?, Never> {
        if let child = childTasks[childKey] {
            return child.publisher(for: \.completedUnitCount)
                .map { $0 as Int64? }
                .eraseToAnyPublisher()
        } else {
            return Just(nil)
                .eraseToAnyPublisher()
        }
    }
}
#endif
