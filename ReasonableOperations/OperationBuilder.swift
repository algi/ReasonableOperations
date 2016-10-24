//
//  FirstViewController.swift
//  ReasonableOperations
//
//  Created by Marian Bouček on 23.10.16.
//  Copyright © 2016 Marian Bouček. All rights reserved.
//

import Foundation

class OperationBuilder: NSObject {

    private let internalQueue = OperationQueue()
    private var plainOperations = [BasicOperation]()

    private var currrentOperation: CustomBlockOperation?
    private var observer: OperationBuilderObserver?

    init(observer: OperationBuilderObserver? = nil) {
        self.observer = observer
    }

    func add(_ operation: BasicOperation) -> Self {
        plainOperations.append(operation)
        return self
    }

    func start() {

        guard plainOperations.count > 0 else {
            assertionFailure("Unable to run empty queue!")
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
            builderDidFinish()
            return
        }

        guard let currentOperation = currrentOperation else {
            assertionFailure("No current operation assigned.")
            return
        }

        guard let operationResult = currentOperation.operationResult else {
            assertionFailure("No operation result from current operation: \(currentOperation)")
            return
        }

        var dependency: Any?

        switch operationResult {
            case .Success(let resultValue):
                dependency = resultValue
            case .Failure(let error):
                builderDidFinish(error: error)
        }

        let newOperation = CustomBlockOperation(plainOperation: plainOperations.removeFirst(), previousResult: dependency)

        newOperation.completionBlock = customBlockOperationDidFinish
        self.currrentOperation = newOperation

        internalQueue.addOperation(newOperation)
    }

    private func builderDidFinish(error: NSError? = nil) {
        if let builderObserver = observer {
            DispatchQueue.main.async {
                builderObserver.operationsFinishedWithError(error)
            }
        }
    }
}

private class CustomBlockOperation: Operation {

    let plainOperation: BasicOperation

    var operationResult: OperationResult?
    var previousResult: Any?

    init(plainOperation: BasicOperation, previousResult: Any? = nil) {
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

        do {
            try plainOperation.execute()

            if let producerOperation = plainOperation as? ProducerOperation {
                operationResult = .Success(producerOperation.operationResult())
            }
            else {
                operationResult = .Success(nil)
            }
        }
        catch (let error as NSError) {
            operationResult = .Failure(error)
        }
    }
}

private enum OperationResult {

    case Success(Any?)
    case Failure(NSError)

}
