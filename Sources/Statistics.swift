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

private let versionKey = "_Statistics::version"

public final class Statistics {
    public struct Data {
        private init() {}
    }
    private(set) var backend: Backend
    let current: Version
    var previous: Version? {
        return backend.read(forKey: versionKey).flatMap(Version.init(semanticVersioningString:))
    }
    
    static var version: String = bundleLoader(forKey: "CFBundleShortVersionString")
    private(set) static var shared: Statistics!
    
    private init(backend: Backend, version: String) {
        self.backend = backend
        current = Version(semanticVersioningString: version)!
    }
    
    func _key(_ key: String) -> String {
        return "Statistics::\(current)::\(key)"
    }
    
    private func checkUpdate(once: (_ old: Version?) throws -> Void) rethrows {
        if let old = previous {
            if current > old {
                try once(old)
            }
        } else {
            try once(nil)
        }
        backend.write(current.description, forKey: versionKey)
    }
    
    public static func launch(with backend: Backend, updated: (_ old: Version?) throws -> Void = { _ in }) rethrows {
        shared = Statistics(backend: backend, version: version)
        try shared.checkUpdate(once: updated)
    }
    
    public static func launch(with backend: Backend, updated: (_ old: Version?) -> Void = { _ in }) {
        shared = Statistics(backend: backend, version: version)
        shared.checkUpdate(once: updated)
    }
    
    public static func update<D: StatisticsData>(_ data: D.Type) {
        shared.backend.update(data, forKey: shared._key(data.key))
    }
    
    public static func reset() {
        shared.backend.removeAll()
    }
    
    public static func reset<D: StatisticsData>(for data: D.Type) {
        shared.backend.remove(forKey: shared._key(data.key))
    }
}

private extension Backend {
    func update<D: StatisticsData>(_ data: D.Type, forKey key: String) {
        write(data.Value.updated(old: read(forKey: key)), forKey: key)
    }
}
