//
//  ProgressManager.swift
//
//
//  Created by Edon Valdman on 10/17/23.
//

import Foundation

/// A class to make dealing with [`Progress`](https://developer.apple.com/documentation/foundation/progress) objects and child `Progress` objects just a bit more straightforward and easy to work with.
public final class ProgressManager<ChildTask: ChildProgressTask>: Sendable {
    /// The primary [`Progress`](https://developer.apple.com/documentation/foundation/progress) object.
    public let parent: Progress
    
    /// A `Dictionary` used to store child `Progress` objects.
    public let childTasks: [ChildTask: Progress]
    
    private let childTasksInfo: Set<ChildTask>
    
    /// Creates a new ``ProgressManager``, automatically creating `Progress` objects to manage child tasks.
    /// - Parameters:
    ///   - type: The generic type for the child tasks. If the type can be inferred from the context, this parameter can be omitted.
    ///   - childTasks: A unique unordered `Set` of child tasks that make up the primary `Progress` operation.
    public init(
        _ type: ChildTask.Type = ChildTask.self,
        childTasks: Set<ChildTask>
    ) {
        self.childTasksInfo = childTasks
        
        let totalParentUnitCount: Int64 = childTasks
            .reduce(into: 0) { $0 += $1.parentUnits }
        
        self.parent = Progress(totalUnitCount: totalParentUnitCount)
        
        self.childTasks = childTasks.reduce(into: [:]) { [parent] dict, task in
            dict[task] = Progress(
                totalUnitCount: task.childUnits,
                parent: parent,
                pendingUnitCount: task.parentUnits
            )
        }
    }
    
    /// An easy way to acccess the child `Progress` objects stored in ``childTasks``.
    /// - Parameter child: The key associated with the child `Progress` object to return.
    /// - Returns: The child `Progress` object associated with the provided key, if there is one. Otherwise, `nil`.
    public subscript(_ child: ChildTask) -> Progress? {
        childTasks[child]
    }
}

// MARK: - Updating Child Task Progress

extension ProgressManager {
    /// Resets the progress of all child tasks to `0`.
    @MainActor
    public func resetAllTasks() {
        self.childTasks.values
            .forEach { $0.completedUnitCount = 0 }
    }
    
    /// Sets the [`completedUnitCount`](https://developer.apple.com/documentation/foundation/progress/1407934-completedunitcount) property of the child task with the associated key to the provided value.
    /// - Parameters:
    ///   - completedUnitCount: The new count of completed units for the child task associated with the provided key.
    ///   - key: The key of a child task to update.
    @MainActor
    public func setCompletedUnitCount(
        _ completedUnitCount: Int64,
        forChildTask childTask: ChildTask
    ) {
        childTasks[childTask]?.completedUnitCount = completedUnitCount
    }
    
    /// Updates the [`completedUnitCount`](https://developer.apple.com/documentation/foundation/progress/1407934-completedunitcount) property of the child task with the associated key by adding the provided value to the current value.
    /// - Parameters:
    ///   - newlyCompletedUnitCountToAdd: A count of completed units to add to the current value of the child task associated with the provided key.
    ///   - key: The key of a child task to update.
    @MainActor
    public func addToCompletedUnitCount(
        _ newlyCompletedUnitCountToAdd: Int64,
        forChildTask childTask: ChildTask
    ) {
        childTasks[childTask]?.completedUnitCount += newlyCompletedUnitCountToAdd
    }
    
    /// Updates the [`completedUnitCount`](https://developer.apple.com/documentation/foundation/progress/1407934-completedunitcount) property of the child task with the associated key by calling the provided closure.
    /// - Parameters:
    ///   - key: The key of a child task to update.
    ///   - updateClosure: A closure that should return an updated current count of completed units.
    ///   - currentValue: The current count of completed units.
    @MainActor
    public func updateCompletedUnitCount(
        forChildTask childTask: ChildTask,
        updateClosure: (_ currentValue: Int64) -> Int64
    ) {
        guard let childProgress = childTasks[childTask] else { return }
        childProgress.completedUnitCount = updateClosure(childProgress.completedUnitCount)
    }
}

// MARK: - Misc Extra Properties

extension ProgressManager {
    /// An optional value that represents the time remaining, in seconds.
    ///
    /// When this is set and the `ProgressManager` is used in a `ProgressView`, the label will be automatically updated with this information.
    ///
    /// This is displayed in the format of "x hours, y minutes, z seconds remaining" (excluding any components not needed).
    ///
    /// > Note: Though it will not display any units smaller than a second (it rounds to the nearest second), using `Double` is more convenient for doing multiplication/division without having to cast anything.
    public var estimatedTimeRemaining: Double? {
        get {
            self.parent.userInfo[.estimatedTimeRemainingKey] as? Double
        } set {
            self.parent.setUserInfoObject(newValue, forKey: .estimatedTimeRemainingKey)
        }
    }
    
    /// Tells the underlying `Progress` that it's referring to a specific kind of file-related operation.
    ///
    /// When this is used with a non-`nil` value and the `ProgressManager` is used in a `ProgressView`, the label will be automatically updated with relevant information.
    ///
    /// Passing `nil` tells the underlying `Progress` that its related operation is not related to files processing.
    public func setFileOperationKind(_ kind: Progress.FileOperationKind?) {
        if let kind {
            self.parent.kind = .file
            self.parent.setUserInfoObject(kind, forKey: .fileOperationKindKey)
        } else {
            self.parent.kind = nil
            self.parent.setUserInfoObject(nil, forKey: .fileOperationKindKey)
        }
    }
    
    /// Tells the underlying `Progress` that it's referring to a general file-related operation.
    ///
    /// When this is used with a non-`nil` value and the `ProgressManager` is used in a `ProgressView`, the label will be automatically updated with relevant information.
    public func setFileOperationKind() {
        self.parent.kind = .file
    }
    
    /// Tells the underlying `Progress` the total number of files for a file progress object.
    ///
    /// When this is used with a non-`nil` value and the `ProgressManager` is used in a `ProgressView`, the label will be automatically updated with relevant information.
    ///
    /// > Important: This only affects the label if ``setFileOperationKind(_:)`` (or ``setFileOperationKind()``) is used to indicate a file-related operation.
    ///
    /// Passing `nil` tells the underlying `Progress` that its related operation is not related to files processing.
    public func setTotalFileCount(_ count: Int?) {
        self.parent.fileTotalCount = count
    }
    
    /// Tells the underlying `Progress` the speed of data processing, in bytes per second.
    ///
    /// When this is used with a non-`nil` value and the `ProgressManager` is used in a `ProgressView`, the label will be automatically updated with relevant information.
    ///
    /// > Important: This only affects the label if ``setFileOperationKind(_:)`` is used to set a *specific* kind of file operation, not just ``setFileOperationKind()``.
    ///
    /// Passing `nil` tells the underlying `Progress` that its related operation is not related to files processing.
    public func setFileOperationThroughput(_ throughput: Int?) {
        self.parent.setUserInfoObject(throughput, forKey: .throughputKey)
    }
    
    /// Overrides the primary descriptive text of a `Progress` view attached to this `ProgressManager`.
    public var primaryLabelText: String? {
        get {
            self.parent.localizedDescription
        } set {
            self.parent.localizedDescription = newValue
        }
    }
    
    /// Overrides the secondary descriptive text of a `Progress` view attached to this `ProgressManager`.
    public var secondaryLabelText: String? {
        get {
            self.parent.localizedAdditionalDescription
        } set {
            self.parent.localizedAdditionalDescription = newValue
        }
    }
}

// MARK: - CaseIterable Key Init

extension ProgressManager where ChildTask: CaseIterable {
    /// Creates a new ``ProgressManager`` from a `CaseIterable` `ChildTask` type, automatically creating `Progress` objects to manage child tasks.
    /// - Parameters:
    ///   - type: The generic type for the child tasks. If the type can be inferred from the context, this parameter can be omitted.
    public convenience init(_ type: ChildTask.Type = ChildTask.self) {
        let allCases = Set(ChildTask.allCases)
        self.init(childTasks: allCases)
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
    public func fractionCompletedPublisher(forChildTask childTask: ChildTask) -> AnyPublisher<Double?, Never> {
        if let child = childTasks[childTask] {
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
    public func totalUnitCountPublisher(forChildTask childTask: ChildTask) -> AnyPublisher<Int64?, Never> {
        if let child = childTasks[childTask] {
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
    public func completedUnitCountPublisher(forChildTask childTask: ChildTask) -> AnyPublisher<Int64?, Never> {
        if let child = childTasks[childTask] {
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
