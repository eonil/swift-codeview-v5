import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(CodeSourceEditingTests.allTests),
        testCase(CodeView5Tests.allTests),
    ]
}
#endif
