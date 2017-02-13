//
//  Plugins.swift
//  StatisticsKit
//
//  Created by 林 達也 on 2017/02/10.
//  Copyright © 2017年 林 達也. All rights reserved.
//

import Foundation

public protocol StatisticsData {
    associatedtype Value
    static var key: String { get }
    func update(old: Value?) -> Value?
}
