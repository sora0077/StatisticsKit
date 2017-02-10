//
//  Plugins.swift
//  StatisticsKit
//
//  Created by 林 達也 on 2017/02/10.
//  Copyright © 2017年 林 達也. All rights reserved.
//

import Foundation

public protocol ValueController {
    associatedtype ValueType
    static func updated(old: ValueType?) -> ValueType?
}

public struct IncrementalValueController: ValueController {
    public typealias ValueType = Int
    
    public static func updated(old: Int?) -> Int? {
        return (old ?? 0) + 1
    }
}

public protocol StatisticsData {
    associatedtype Value: ValueController
    static var key: String { get }
}

extension StatisticsData {
    public static var value: Value.ValueType? {
        guard let _key = Statistics.shared?._key(key) else { return nil }
        return Statistics.shared?.backend.read(forKey: _key)
    }
}
