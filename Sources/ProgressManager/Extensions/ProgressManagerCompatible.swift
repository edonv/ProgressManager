//
//  ProgressManagerCompatible.swift
//  
//
//  Created by Edon Valdman on 8/7/24.
//

import Foundation

// MARK: - ProgressManagerCompatible

public protocol ProgressManagerCompatible {
    /// Attaches a ``ProgressManager`` to this instance.
    func use<TaskKeys: Hashable>(
        progressManager: ProgressManager<TaskKeys>
    )
}

// MARK: - NSProgressIndicator

#if canImport(AppKit)
import AppKit

@available(macOS 14.0, *)
extension NSProgressIndicator: ProgressManagerCompatible {
    public func use<TaskKeys: Hashable>(
        progressManager: ProgressManager<TaskKeys>
    ) {
        self.observedProgress = progressManager.parent
    }
}
#endif

// MARK: - UIProgressView

#if canImport(UIKit)
import UIKit

extension UIProgressView {
    public func use<TaskKeys: Hashable>(
        progressManager: ProgressManager<TaskKeys>
    ) {
        self.observedProgress = progressManager.parent
    }
}
#endif
