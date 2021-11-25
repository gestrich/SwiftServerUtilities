import NIO
import Foundation


public func backgroundFuture<T>(eventLoop: EventLoop, block: @escaping () -> T) -> EventLoopFuture<T> {
    let promise = eventLoop.makePromise(of: T.self)
    DispatchQueue.global().async {
        let res = block()
        promise.succeed(res)
    }
    
    return promise.futureResult
}
