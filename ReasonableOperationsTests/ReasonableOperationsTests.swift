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
        let expectedResult = OperationResult.Success("Successful object" as NSObject)

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

    let result: OperationResult

    init(result: OperationResult) {
        self.result = result
    }

    func execute() {
        // noop
    }

    func operationResult() -> OperationResult {
        return result
    }
}

class TestConsumerOperation: ConsumerOperation {

    var actualResult: NSObject?

    let expectedResult: OperationResult

    init(expectedResult: OperationResult) {
        self.expectedResult = expectedResult
    }

    func consume(dependency: NSObject) {
        self.actualResult = dependency
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
