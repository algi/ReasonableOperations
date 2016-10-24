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

    associatedtype DependencyType: Any

    func operationResult() -> DependencyType

}

/**
 * Operation, which consumes some dependency from previous operation.
 */
protocol ConsumerOperation: BasicOperation {

    associatedtype DependencyType: Any

    func consume(dependency: DependencyType)
    
}

// #MARK: - Observers -

/**
 * Observer for watching operations completion. It's intended to use from UIViewController, because it calls functions
 * on main thread. It's also useful for unit testing and other general purposes.
 */
protocol OperationBuilderObserver {

    func operationsFinishedWithError(_ error: NSError?)
    
}
