//
//  Statistics.swift
//  Statistics
//
//  Created by 林 達也 on 2017/02/10.
//  Copyright © 2017年 林 達也. All rights reserved.
//

import Foundation

public protocol ApplicationHost {
    var currentVersion: String { get }
}

public extension ApplicationHost {
    var currentVersion: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }
}

public protocol Backend {
    var latestVersion: String? { get }
    func update(version: String)

    func write<T>(_ value: T?, forKey key: String)
    func read<T>(forKey key: String) -> T?
    
    func remove(forKey key: String)
    func removeAll()
}

private let versionKey = "_Statistics::version"

public final class Statistics {
    public struct Data {
        private init() {}
    }
    private(set) var backend: Backend
    let current: Version
    var previous: Version? {
        return backend.latestVersion.flatMap(Version.init(semanticVersioningString:))
    }
    fileprivate private(set) static var shared: Statistics!
    
    private init(backend: Backend, version: String) {
        self.backend = backend
        current = Version(semanticVersioningString: version)!
    }
    
    func _key(_ key: String) -> String {
        return "Statistics::\(current)::\(key)"
    }
    
    private func checkUpdate(once: (_ old: Version?) throws -> Void) rethrows {
        func doOnceIfNeeded(_ closure: (Version?) throws -> Void) rethrows {
            guard let old = previous, current <= old else {
                try closure(previous)
                return
            }
        }
        try doOnceIfNeeded(once)
        backend.update(version: current.description)
    }
    
    public static func launch(with backend: Backend, host: ApplicationHost, updated: (_ old: Version?) throws -> Void = { _ in }) rethrows {
        shared = Statistics(backend: backend, version: host.currentVersion)
        try shared.checkUpdate(once: updated)
    }
    
    public static func launch(with backend: Backend, host: ApplicationHost, updated: (_ old: Version?) -> Void = { _ in }) {
        shared = Statistics(backend: backend, version: host.currentVersion)
        shared.checkUpdate(once: updated)
    }
    
    public static func update<D: StatisticsData>(_ data: D) {
        shared.backend.update(data, forKey: shared._key(type(of: data).key))
    }
    
    public static func reset() {
        shared.backend.removeAll()
    }
    
    public static func reset<D: StatisticsData>(for data: D.Type) {
        shared.backend.remove(forKey: shared._key(data.key))
    }
}

private extension Backend {
    func update<D: StatisticsData>(_ data: D, forKey key: String) {
        write(data.update(old: read(forKey: key)), forKey: key)
    }
}

extension StatisticsData {
    public static var value: Value? {
        guard let _key = Statistics.shared?._key(key) else { return nil }
        return Statistics.shared?.backend.read(forKey: _key)
    }
}
