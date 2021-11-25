//
//  BackgroundThreadService.swift
//  
//
//  Created by Bill Gestrich on 10/27/21.
//

import Foundation
import NIO

public class BackgroundThreadService {
    let concurrentQueue: DispatchQueue
    
    public init(serviceLabel: String) {
        self.concurrentQueue = DispatchQueue(label: serviceLabel, attributes: .concurrent)
    }
    
    public func backgroundFuture<T>(eventLoop: EventLoop, block: @escaping () -> T) -> EventLoopFuture<T> {
        return eventLoop.makeSucceededFuture(Void()).flatMap {
            let promise = eventLoop.makePromise(of: T.self)
            DispatchQueue.global().async {
                let res = block()
                promise.succeed(res)
            }
            
            return promise.futureResult
        }
    }

    public func backgroundFutureThrowing<T>(eventLoop: EventLoop, block: @escaping () throws -> T) -> EventLoopFuture<T> {
        return eventLoop.makeSucceededFuture(Void()).flatMap {
            let promise = eventLoop.makePromise(of: T.self)
            self.concurrentQueue.async {
                do {
                    let toRet = try block()
                    promise.succeed(toRet)
                } catch let err {
                    promise.fail(err)
                }
            }
            
            return promise.futureResult
        }
    }


    public func backgroundInlineFuture<T>(passThroughResult: T, eventLoop: EventLoop, block: @escaping () -> Void) -> EventLoopFuture<T> {
        return eventLoop.makeSucceededFuture(Void()).flatMap {
            let promise = eventLoop.makePromise(of: T.self)
            self.concurrentQueue.async  {
                block()
                promise.succeed(passThroughResult)
            }
            
            return promise.futureResult
        }
    }
}
