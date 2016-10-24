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

    func testSimpleScenario() {

        let executionExpectation = expectation(description: "Expectation for all operations")

        let builder = OperationBuilder(observer: TestObserver(expectation: executionExpectation))

        builder
            .add(FetchImageOperation())
            .add(SaveImageOperation())
            .start()

        waitForExpectations(timeout: 5) {
            (error) in
            if let error = error {
                XCTFail("Unexpected error: \(error.localizedDescription)")
            }
        }
    }
}

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

// TODO: create another scenario with real use case (Fetch image from internet, save in CoreData)

// #MARK: - Example operations -

class FetchImageOperation: ProducerOperation {

    func execute() {
        print(">> FetchDataOperation finished")
    }

    func operationResult() -> OperationResult {
        return .Success("Image from hell!" as AnyObject)
    }
}

class SaveImageOperation: ConsumerOperation {

    var dependencyFromFetchOperation: String?

    func consume(dependency: AnyObject) {
        self.dependencyFromFetchOperation = dependency as? String
    }

    func execute() {

        guard let dependencyFromFetchOperation = dependencyFromFetchOperation else {
            assertionFailure(">> Unable to run operation without dependency from first operation.")
            return
        }

        print(">> SaveImageOperation finished with: \(dependencyFromFetchOperation)")
    }
}
