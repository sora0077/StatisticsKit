//
//  Statistics.swift
//  Statistics
//
//  Created by 林 達也 on 2017/02/10.
//  Copyright © 2017年 林 達也. All rights reserved.
//

import Foundation

public protocol Backend {
    func write<T>(_ value: T?, forKey key: String)
    func read<T>(forKey key: String) -> T?
    
    func remove(forKey key: String)
    func removeAll()
}

private func bundleLoader(forKey key: String) -> String {
    return Bundle.main.object(forInfoDictionaryKey: key) as? String ?? ""
}

public final class Statistics {
    public struct Data {
        private init() {}
    }
    private(set) var backend: Backend
    private let current: Version
    private let previous: Version?
    
    static var version: String = bundleLoader(forKey: "CFBundleShortVersionString")
    private(set) static var shared: Statistics!
    
    private init(backend: Backend, version: String) {
        let versionKey = "_Statistics::version"
        
        self.backend = backend
        current = Version(semanticVersioningString: version)!
        previous = backend.read(forKey: versionKey).flatMap(Version.init(semanticVersioningString:))
        backend.write(current.description, forKey: versionKey)
    }
    
    func _key(_ key: String) -> String {
        return "Statistics::\(current)::\(key)"
    }
    
    public static func launch(with backend: Backend, updated: (_ old: Version?) -> Void = { _ in }) {
        shared = Statistics(backend: backend, version: version)
        if let old = shared.previous {
            if shared.current > old {
                updated(old)
            }
        } else {
            updated(nil)
        }
    }
    
    static func update<D: StatisticsData>(_ data: D.Type) {
        shared.backend.update(data, forKey: shared._key(data.key))
    }
    
    static func reset() {
        shared.backend.removeAll()
    }
    
    static func reset<D: StatisticsData>(for data: D.Type) {
        shared.backend.remove(forKey: shared._key(data.key))
    }
}

private extension Backend {
    func update<D: StatisticsData>(_ data: D.Type, forKey key: String) {
        write(data.Value.updated(old: read(forKey: key)), forKey: key)
    }
}
