//
//  FirstViewController.swift
//  ReasonableOperations
//
//  Created by Marian Bouček on 23.10.16.
//  Copyright © 2016 Marian Bouček. All rights reserved.
//

import UIKit

class OperationBuilder: NSObject {

    public var done = false

    private let internalQueue = OperationQueue()
    private var plainOperations = [PlainOperation]()

    private var currrentOperation: CustomBlockOperation?
    private var observer: OperationBuilderObserver?

    init(observer: OperationBuilderObserver? = nil) {
        self.observer = observer
    }

    func add(_ operation: PlainOperation) -> Self {
        plainOperations.append(operation)
        return self
    }

    func start() {

        guard plainOperations.count > 0 else {
            print(">> Unable to run empty queue...")
            return
        }

        let firstOperation = plainOperations.removeFirst()

        let blockOperation = CustomBlockOperation(plainOperation: firstOperation)
        blockOperation.completionBlock = customBlockOperationDidFinish

        currrentOperation = blockOperation

        internalQueue.addOperation(blockOperation)
    }

    private func customBlockOperationDidFinish() {

        if plainOperations.count == 0 {
            builderFinished()
            return
        }

        guard let currrentOperation = currrentOperation else {
            assertionFailure("No current operation assigned.")
            return
        }

        var dependency: String?

        if let producer = currrentOperation.plainOperation as? ProducerOperation {

            switch producer.operationResult() {

                case .Success(let resultValue):
                    dependency = resultValue

                case .Failure(let error):
                    builderFinished(error: error)
                    return
            }
        }

        let newOperation = CustomBlockOperation(plainOperation: plainOperations.removeFirst(), previousResult: dependency)

        newOperation.completionBlock = customBlockOperationDidFinish
        self.currrentOperation = newOperation

        internalQueue.addOperation(newOperation)
    }

    private func builderFinished(error: NSError? = nil) {
        done = true

        // TODO: main thread (?)
        observer?.operationsFinishedWithError(error)
    }

    private class CustomBlockOperation: Operation {

        let plainOperation: PlainOperation

        var operationResult: OperationResult?
        var previousResult: String?

        init(plainOperation: PlainOperation, previousResult: String? = nil) {
            self.plainOperation = plainOperation
            self.previousResult = previousResult
        }

        private override func main() {

            if let consumerOperation = plainOperation as? ConsumerOperation {

                guard let previousResult = previousResult else {
                    assertionFailure(">> Unable to satisfy dependencies for operation: \(plainOperation)")
                    return
                }

                consumerOperation.consume(dependency: previousResult)
            }

            plainOperation.execute()

            if let producerOperation = plainOperation as? ProducerOperation {
                operationResult = producerOperation.operationResult()
            }
            else {
                operationResult = .Success("")
            }
        }
    }
}

// #MARK: - Observers -

protocol OperationBuilderObserver {

    func operationsFinishedWithError(_ error: NSError?)

}

// #MARK: - Public API -

protocol PlainOperation {

    func execute()

}

enum OperationResult {

    case Success(String) // TODO: generics (?)
    case Failure(NSError)

}

protocol ProducerOperation: PlainOperation {

    func operationResult() -> OperationResult

}

protocol ConsumerOperation: PlainOperation {

    func consume(dependency: String) // TODO: generics (?)

}
