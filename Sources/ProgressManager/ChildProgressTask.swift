//
//  ChildProgressTask.swift
//
//
//  Created by Edon Valdman on 8/7/24.
//

import Foundation

public protocol ChildProgressTask: Hashable, Sendable {
    /// The number of units (or steps) this task needs to be complete.
    var childUnits: Int64 { get }
    
    /// The number of units the child task counts for in the context of the parent operation.
    ///
    /// # Example
    /// If ``childUnits`` is `6`, and `unitCountInParent` is `1`, then it will count as `1` unit in the parent `Progress` once this task has had `6` units complete.
    ///
    /// In this scenario, the parent's [`fractionCompleted`](https://developer.apple.com/documentation/foundation/progress/1408579-fractioncompleted) will be affected as each child task unit is completed, but its [`completedUnitCount`](https://developer.apple.com/documentation/foundation/progress/1407934-completedunitcount) will stay the same until ``childUnits`` number of units have been completed in the child task.
    var parentUnits: Int64 { get }
}
