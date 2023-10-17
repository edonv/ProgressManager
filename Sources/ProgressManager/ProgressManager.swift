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
