import XCTest
import CodeView5Tests

var tests = [XCTestCaseEntry]()
tests += CodeSourceEditingTests.allTests()
tests += CodeView5Tests.allTests()
XCTMain(tests)
