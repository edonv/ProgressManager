//
//  ProgressView+Extensions.swift
//
//
//  Created by Edon Valdman on 8/7/24.
//

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension ProgressView {
    /// Creates a progress view for visualizing the given `ProgressManager` instance.
    ///
    /// The progress view synthesizes a default label using the `localizedDescription` of the given progress instance.
    public init<TaskKeys: Hashable>(
        _ progressManager: ProgressManager<TaskKeys>
    ) where Label == EmptyView, CurrentValueLabel == EmptyView {
        self.init(progressManager.parent)
    }
}
#endif
