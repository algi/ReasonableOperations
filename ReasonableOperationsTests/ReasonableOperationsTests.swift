//
//  ReasonableOperationsTests.swift
//  ReasonableOperationsTests
//
//  Created by Marian Bouček on 23.10.16.
//  Copyright © 2016 Marian Bouček. All rights reserved.
//

import XCTest
@testable import ReasonableOperations

class ReasonableOperationsTests: XCTestCase {

    // TODO: create another scenario with real use case (Fetch image from internet, save in CoreData)

    func testSimpleScenario() {

        let executionExpectation = expectation(description: "Expectation for all operations")
        let expectedResult = OperationResult.Success("Successful object")

        let builder = OperationBuilder(observer: TestObserver(expectation: executionExpectation))

        builder
            .add(TestProducerOperation(result: expectedResult))
            .add(TestConsumerOperation(expectedResult: expectedResult))
            .start()

        waitForExpectations(timeout: 5) {
            (error) in
            if let error = error {
                XCTFail("Unexpected error: \(error.localizedDescription)")
            }
        }
    }
}

// #MARK: - Test implementations -

class TestObserver: OperationBuilderObserver {

    let expectation: XCTestExpectation

    init(expectation: XCTestExpectation) {
        self.expectation = expectation
    }

    func operationsFinishedWithError(_ error: NSError?) {

        expectation.fulfill()

        if let error = error {
            XCTFail("Unexpected error in observer: \(error.localizedDescription)")
        }
    }
}

class TestProducerOperation: ProducerOperation {

    typealias DependencyType = String

    let result: OperationResult

    init(result: OperationResult) {
        self.result = result
    }

    func execute() throws {
        switch result {
            case .Failure(let error):
                throw error
            default:
                break
        }
    }

    func operationResult() -> Any {
        switch result {
            case .Success(let value):
                return value
            default:
                XCTFail("ProducerOperation should not be asked for result, if execute() throws an exception.")
                return ""
        }
    }
}

class TestConsumerOperation: ConsumerOperation {

    var actualResult: String?

    let expectedResult: OperationResult

    init(expectedResult: OperationResult) {
        self.expectedResult = expectedResult
    }

    func consume(dependency: Any) {
        self.actualResult = dependency as? String
    }

    func execute() {
        switch expectedResult {
            case .Success(let expectedValue):
                XCTAssertEqual(actualResult, expectedValue, "Actual and expected result doesn't match.")

            case .Failure:
                XCTAssertNil(actualResult, "Expected error, but got result.")
        }
    }
}

enum OperationResult {

    case Success(String)
    case Failure(NSError)

}
