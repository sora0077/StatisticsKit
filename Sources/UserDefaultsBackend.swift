//
//  UserDefaultsBackend.swift
//  StatisticsKit
//
//  Created by 林 達也 on 2017/02/10.
//  Copyright © 2017年 林 達也. All rights reserved.
//

import Foundation

public struct UserDefaultsBackend: Backend {
    private let defaults: UserDefaults
    
    public init(defaults: UserDefaults = UserDefaults.standard) {
        self.defaults = defaults
    }
    
    public func write<T>(_ value: T?, forKey key: String) {
        defaults.set(value, forKey: key)
        defaults.synchronize()
    }
    
    public func read<T>(forKey key: String) -> T? {
        return defaults.object(forKey: key) as? T
    }
    
    public func remove(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
    
    public func removeAll() {
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix("Statistics::") {
            defaults.removeObject(forKey: key)
        }
        defaults.synchronize()
    }
}
