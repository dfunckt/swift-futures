//
//  ScanStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum Scan<Output, Base: StreamProtocol> {
        public typealias Accumulate = (Output, Base.Output) -> Output

        case pending(Base, Output, Accumulate)
        case done

        @inlinable
        public init(base: Base, initialResult: Output, nextPartialResult: @escaping Accumulate) {
            self = .pending(base, initialResult, nextPartialResult)
        }
    }
}

extension Stream._Private.Scan: StreamProtocol {
    @inlinable
    public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
        switch self {
        case .pending(var base, var output, let accumulate):
            switch base.pollNext(&context) {
            case .ready(.some(let result)):
                output = accumulate(output, result)
                self = .pending(base, output, accumulate)
                return .ready(output)

            case .ready(.none):
                self = .done
                return .ready(nil)

            case .pending:
                self = .pending(base, output, accumulate)
                return .pending
            }

        case .done:
            fatalError("cannot poll after completion")
        }
    }
}
