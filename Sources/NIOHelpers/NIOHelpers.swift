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

public extension EventLoopFuture {
    //Convert Future -> Async Code
    
    @available(macOS 12.0, *)
    func awaitFuture() async throws -> Value  {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Value, Error>) -> Void in
            let _ = self.flatMapAlways { (result) -> EventLoopFuture<Result<Value, Error>> in
                switch result {
                case .success(let val):
                    continuation.resume(returning: val)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
                return self.eventLoop.makeSucceededFuture(result)
            }
        }
    }
    
    //Ported from async-kit on Vapor
    private func flatMapAlways<NewValue>(
        file: StaticString = #file, line: UInt = #line,
        _ callback: @escaping (Result<Value, Error>) -> EventLoopFuture<NewValue>
    ) -> EventLoopFuture<NewValue> {
        let promise = self.eventLoop.makePromise(of: NewValue.self, file: file, line: line)
        self.whenComplete { result in callback(result).cascade(to: promise) }
        return promise.futureResult
    }
}

public extension EventLoop {
    //Convert Async Code -> Future
    @available(macOS 12.0, *)
    func asyncFuture<T>(asyncBlock: @escaping () async throws -> T ) -> EventLoopFuture<T> {
        let promise = makePromise(of: T.self)
        promise.completeWithTask {
            try await asyncBlock()
        }

        return promise.futureResult
    }
}
