# ProgressManager

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fedonv%2FProgressManager%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/edonv/ProgressManager)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fedonv%2FProgressManager%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/edonv/ProgressManager)

`ProgressManager` is a class to make dealing with [`Progress`](https://developer.apple.com/documentation/foundation/progress) and its child tasks just a bit more straightforward and easy. Why use it? It allows for a complex but accessible way to use `Progress` for things like [`ProgressView`](https://developer.apple.com/documentation/swiftui/progressview) and [`UIProgressView`](https://developer.apple.com/documentation/uikit/uiprogressview).

## How to Use ProgressManager

1. Just create any type that you'd like to use for referencing each child task (most easily an enumeration, but could be anything that conforms to `Hashable`).

```swift
enum ProgressSteps: Hashable {
    case importantStep, smallStep, aMultiUnitStep
}
```

2. Then create an instance of `ProgressManager` using your key type. When initializing your `ProgressManager`, you tell it how many units each child task needs to be complete (could be `1`, or it could be that a child task is doing something `3` times, so it would be `3` units). You also enter how you want each child task weighted, as maybe uploading uploading a file to a server should have a heavier weight than creating a local instance variable (so it has more significance).

```swift
let progress = ProgressManager(
    ProgressSteps.self,
    childTaskUnitCounts: [
        // 1 unit of this task must be completed for it to be considered "complete" by the parent
        .importantStep: 1,
        // 1 unit of this task must be completed for it to be considered "complete" by the parent
        .smallStep: 1,
        // 6 units of this task must be completed for it to be considered "complete" by the parent
        .aMultiUnitStep: 6,
    ],
    childTaskUnitCountsInParent: [
        // Once all units of this child task have been completed (1 unit),
        // it counts as 5 units in the context of the parent progress
        .importantStep: 5,
        // Once all units of this child task have been completed (1 unit),
        // it counts as 1 unit in the context of the parent progress
        .smallStep: 1,
        // Once all units of this child task have been completed (6 units),
        // it counts as 1 unit in the context of the parent progress
        .aMultiUnitStep: 1,
    ]
)
```

3. As your code completes the tasks, you call any combination of the child task updating functions (`setCompletedUnitCount(_:forChildTask:)`, `addToCompletedUnitCount(_:forChildTask:)`, and `updateCompletedUnitCount(forChildTask:updateClosure:)`).

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

And that's it! If you need more granular control, you can access the child tasks by either the `childTasks` property or just via the subscript (`progress[.aMultiUnitStep]`).
