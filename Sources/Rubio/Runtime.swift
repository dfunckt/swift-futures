//
//  Driver.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import Futures
import FuturesIO
import FuturesPlatform
import FuturesSync

@usableFromInline let _currentDriver = ThreadLocal<Driver?>()

extension Context {
    internal var io: Driver? {
        _currentDriver.value
    }
}

public final class Runtime {

}
