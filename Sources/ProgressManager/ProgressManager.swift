//
//  ProgressManager.swift
//
//
//  Created by Edon Valdman on 10/17/23.
//

import Foundation
import Combine

public final class ProgressManager<ChildTaskKey: Hashable> {
    public let parent: Progress
    public let childTasks: [ChildTaskKey: Progress]
    
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
    
    public convenience init(_ type: ChildTaskKey.Type, childTaskUnitCounts: [ChildTaskKey: Int64], childTaskUnitCountsInParent: [ChildTaskKey: Int64]? = nil) {
        self.init(childTaskUnitCounts: childTaskUnitCounts, childTaskUnitCountsInParent: childTaskUnitCountsInParent)
    }
}

// MARK: - Updating Child Task Progress

extension ProgressManager {
    public func setCompletedUnitCount(_ completedUnitCount: Int64, forChildTask key: ChildTaskKey) {
        childTasks[key]?.completedUnitCount = completedUnitCount
    }
    
    public func addToCompletedUnitCount(_ newlyCompletedUnitCountToAdd: Int64, forChildTask key: ChildTaskKey) {
        childTasks[key]?.completedUnitCount += newlyCompletedUnitCountToAdd
    }
    
    public func updateCompletedUnitCount(forChildTask key: ChildTaskKey, updateClosure: (_ currentValue: Int64) -> Int64) {
        guard let childProgress = childTasks[key] else { return }
        childProgress.completedUnitCount = updateClosure(childProgress.completedUnitCount)
    }
}

// MARK: - Subscribing to Changes in Parent/Child Progress

extension ProgressManager {
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    public var fractionCompletedPublisher: AnyPublisher<Double, Never> {
        parent.publisher(for: \.fractionCompleted)
            .eraseToAnyPublisher()
    }
    
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    public var totalUnitCountPublisher: AnyPublisher<Int64, Never> {
        parent.publisher(for: \.totalUnitCount)
            .eraseToAnyPublisher()
    }
    
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    public var completedUnitCountPublisher: AnyPublisher<Int64, Never> {
        parent.publisher(for: \.completedUnitCount)
            .eraseToAnyPublisher()
    }
    
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    public func fractionCompletedPublisher(forChild childKey: ChildTaskKey) -> AnyPublisher<Double?, Never> {
        if let child = childTasks[childKey] {
            child.publisher(for: \.fractionCompleted)
                .map { $0 as Double? }
                .eraseToAnyPublisher()
        } else {
            Just(nil)
                .eraseToAnyPublisher()
        }
    }
    
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    public func totalUnitCountPublisher(forChild childKey: ChildTaskKey) -> AnyPublisher<Int64?, Never> {
        if let child = childTasks[childKey] {
            child.publisher(for: \.totalUnitCount)
                .map { $0 as Int64? }
                .eraseToAnyPublisher()
        } else {
            Just(nil)
                .eraseToAnyPublisher()
        }
    }
    
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    public func completedUnitCountPublisher(forChild childKey: ChildTaskKey) -> AnyPublisher<Int64?, Never> {
        if let child = childTasks[childKey] {
            child.publisher(for: \.completedUnitCount)
                .map { $0 as Int64? }
                .eraseToAnyPublisher()
        } else {
            Just(nil)
                .eraseToAnyPublisher()
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
