import XCTest
@testable import ProgressManager

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
final class ProgressManagerTests: XCTestCase {
    private enum Suboperations: Int, Hashable, CaseIterable {
        case step1 = 1, step2 = 2, step3 = 3
    }
    
    private let dummyManager = ProgressManager(Suboperations.self, childTaskUnitCounts: [
        .step1: 3,
        .step2: 2,
        .step3: 1
    ], childTaskUnitCountsInParent: [
        .step1: 2,
        .step3: 3
    ])
    
    func testInit() throws {
        print(dummyManager)
        XCTAssertEqual(dummyManager.childTasks[.step1]?.totalUnitCount, 3)
        XCTAssertEqual(dummyManager.childTasks[.step2]?.totalUnitCount, 2)
        XCTAssertEqual(dummyManager.childTasks[.step3]?.totalUnitCount, 1)
        XCTAssertEqual(dummyManager.parent.totalUnitCount, 11)
    }
    
    func testProgressReporting() async throws {
        let fractionCompletedPub = dummyManager.fractionCompletedPublisher
            .sink { progress in
                print("Overall progress (fraction): \(progress)")
            }
        let completedUnitCountPub = dummyManager.completedUnitCountPublisher
            .sink { progress in
                print("Overall progress (counted):  \(progress)")
            }
        
        await withThrowingTaskGroup(of: Void.self) { taskGroup in
            for step in Suboperations.allCases {
                taskGroup.addTask {
                    let count = self.dummyManager[step]?.totalUnitCount ?? 1
                    for _ in 0..<count {
                        _ = try await Task.sleep(nanoseconds: UInt64(1000000000 * step.rawValue))
                        self.dummyManager.addToCompletedUnitCount(1, forChildTask: step)
                    }
                }
            }
        }
    }
}
