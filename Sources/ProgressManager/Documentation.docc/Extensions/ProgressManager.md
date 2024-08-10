# ``ProgressManager/ProgressManager``

## Overview

`ProgressManager` is a class to make dealing with [`Progress`](https://developer.apple.com/documentation/foundation/progress) and its child tasks just a bit more straightforward and easy. Why use it? It allows for granular but accessible control over the details of a multistep operation, while automatically mirroring its state in views like [`ProgressView`](https://developer.apple.com/documentation/swiftui/progressview), [`UIProgressView`](https://developer.apple.com/documentation/uikit/uiprogressview), and [`NSProgressIndicator`](https://developer.apple.com/documentation/appkit/nsprogressindicator).

## How to Use

1. Create a type that you'd like to use for referencing each child task (most easily an enumeration, but could be anything that conforms to `ChildProgressTask`). It must have two properties: `childUnits` and `parentUnits`. See docs for more info on each.

```swift
private enum ProgressSteps: ChildProgressTask {
    case importantStep, smallStep, aMultiUnitStep
    
    var childUnits: Int64 {
        switch self {
        // 1 unit of this task must be completed for it to be considered "complete" by the parent
        case .importantStep: 1
        // 1 unit of this task must be completed for it to be considered "complete" by the parent
        case .smallStep: 1
        // 6 units of this task must be completed for it to be considered "complete" by the parent
        case .aMultiUnitStep: 6
        }
    }
    
    var parentUnits: Int64 {
        switch self {
        // Once all units of this child task have been completed (1 unit),
        // it counts as 5 units in the context of the parent progress
        case .importantStep: 5
        // Once all units of this child task have been completed (1 unit),
        // it counts as 1 unit in the context of the parent progress
        case .smallStep: 1
        // Once all units of this child task have been completed (6 units),
        // it counts as 1 unit in the context of the parent progress
        case .aMultiUnitStep: 1
        }
    }
}
```

2. Then create an instance of `ProgressManager` using your type. When initializing your `ProgressManager`, you only need to provide it with a `Set` of the tasks that it cares about. If your type conforms to `CaseIterable`, you can even exclude the `childTasks` parameter of the initializer.

```swift
let progress = ProgressManager(
    // can be ommitted if type can be inferred
    ProgressSteps.self,
    // a Set of unique child tasks
    childTasks: [.importantStemp, .smallStep, .aMultiUnitStep]
)
```

3. As your code completes the tasks, you call any combination of the child task updating functions (``setCompletedUnitCount(_:forChildTask:)``, ``addToCompletedUnitCount(_:forChildTask:)``, and ``updateCompletedUnitCount(forChildTask:updateClosure:)``).

```swift
// Perform `.importantStep`.
progress.setCompletedUnitCount(1, forChildTask: .importantStep)

// Perform `.smallStemp`.
progress.setCompletedUnitCount(1, forChildTask: .smallStemp)

// Perform `.aMultiUnitStep`.
for i in 0..<6 {
    progress.addToCompletedUnitCount(i, forChildTask: .aMultiUnitStep)
}
```

And that's it! If you need more granular control, you can access the child tasks by either the ``childTasks`` property or just via the ``subscript(_:)`` (`progress[.aMultiUnitStep]`).

## Topics

### Initializers

- ``init(_:childTasks:)``
- ``init(_:)``

### Properties

- ``parent``
- ``childTasks``

### Accessing Child Tasks

- ``subscript(_:)``

### Updating Child Task Progress

- ``resetAllTasks()``
- ``setCompletedUnitCount(_:forChildTask:)``
- ``addToCompletedUnitCount(_:forChildTask:)``
- ``updateCompletedUnitCount(forChildTask:updateClosure:)``

### Visualizing Progress

- ``SwiftUI/ProgressView/init(_:)``
- ``ProgressManagerCompatible/use(progressManager:)``
- ``estimatedTimeRemaining``
- ``setFileOperationKind(_:)``
- ``setFileOperationKind()``
- ``setTotalFileCount(_:)``
- ``setFileOperationThroughput(_:)``
- ``primaryLabelText``
- ``secondaryLabelText``

### Subscribing to Progress Changes via Combine

Rather than exclusively using `ProgressManager` as a means for `ProgressView` and `UIProgressView`, changes to the parent or a child's progress can be easily subscribed to with the following convenience publishers:

- ``fractionCompletedPublisher``
- ``totalUnitCountPublisher``
- ``completedUnitCountPublisher``
- ``fractionCompletedPublisher(forChildTask:)``
- ``totalUnitCountPublisher(forChildTask:)``
- ``completedUnitCountPublisher(forChildTask:)``
