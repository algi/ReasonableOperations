//
//  PublicProtocols.swift
//  ReasonableOperations
//
//  Created by Marian Bouček on 24.10.16.
//  Copyright © 2016 Marian Bouček. All rights reserved.
//

import Foundation

/**
 * Basic operation, which doesn't give back any value.
 */
protocol BasicOperation {

    func execute() throws

}

/**
 * Operation, which produces either value or error.
 */
protocol ProducerOperation: BasicOperation {

    func operationResult() -> NSObject

}

/**
 * Operation, which consumes some dependency from previous operation.
 */
protocol ConsumerOperation: BasicOperation {

    func consume(dependency: NSObject)
    
}

// #MARK: - Observers -

/**
 * Observer for watching operations completion. It's intended to use from UIViewController, because it calls functions
 * on main thread. It's also useful for unit testing and other general purposes.
 */
protocol OperationBuilderObserver {

    func operationsFinishedWithError(_ error: NSError?)
    
}
