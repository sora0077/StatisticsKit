//
//  StatisticsTests.swift
//  StatisticsTests
//
//  Created by 林 達也 on 2017/02/10.
//  Copyright © 2017年 林 達也. All rights reserved.
//

import XCTest
@testable import StatisticsKit

struct MockHost: ApplicationHost {
    var currentVersion: String
}

final class MockBackend: Backend {
    var latestVersion: String?
    private var hash: [String: Any]
    
    init(_ version: String? = nil, _ defaults: [String: Any] = [:]) {
        latestVersion = version
        hash = defaults
    }
    
    func update(version: String) {
        latestVersion = version
    }
    
    func write<T>(_ value: T?, forKey key: String) {
        hash[key] = value
    }
    
    func read<T>(forKey key: String) -> T? {
        return hash[key] as? T
    }
    
    func remove(forKey key: String) {
        hash.removeValue(forKey: key)
    }
    
    func removeAll() {
        for key in hash.keys where key.hasPrefix("Statistics") {
            hash.removeValue(forKey: key)
        }
    }
}

private extension Statistics.Data {
    struct LaunchCount: StatisticsData {
        public static let key = "launchCount"
        func update(old: Int?) -> Int? {
            return (old ?? 0) + 1
        }
    }
    struct OtherCount: StatisticsData {
        public static let key = "otherCount"
        let data: String
        fileprivate func update(old: String?) -> String? {
            return data
        }
    }
}


class StatisticsTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCompareVersion() {
        typealias Version = Statistics.Version
        XCTAssertTrue(Version(major: 1, minor: 1, patch: 1) < Version(major: 1, minor: 1, patch: 2))
        XCTAssertTrue(Version(major: 1, minor: 1, patch: 1) <= Version(major: 1, minor: 1, patch: 2))
        XCTAssertFalse(Version(major: 1, minor: 1, patch: 1) < Version(major: 1, minor: 1, patch: 1))
        XCTAssertTrue(Version(major: 1, minor: 1, patch: 1) <= Version(major: 1, minor: 1, patch: 1))
        
        XCTAssertTrue(Version(major: 1, minor: 1, patch: 2) > Version(major: 1, minor: 1, patch: 1))
        XCTAssertTrue(Version(major: 1, minor: 1, patch: 2) >= Version(major: 1, minor: 1, patch: 1))
        XCTAssertFalse(Version(major: 1, minor: 1, patch: 1) > Version(major: 1, minor: 1, patch: 1))
        XCTAssertTrue(Version(major: 1, minor: 1, patch: 1) >= Version(major: 1, minor: 1, patch: 1))
        
        XCTAssertEqual(Version(major: 1, minor: 1, patch: 1), Version(major: 1, minor: 1, patch: 1))
    }
    
    func testLaunchCount() {
        let backend = MockBackend()
        XCTAssertEqual(Statistics.Data.LaunchCount.value ?? 0, 0)
        Statistics.launch(with: backend, host: MockHost(currentVersion: "1.0.0"))
        Statistics.update(Statistics.Data.LaunchCount())
        XCTAssertEqual(Statistics.Data.LaunchCount.value, 1)
        
        Statistics.launch(with: backend, host: MockHost(currentVersion: "1.0.0"))
        Statistics.update(Statistics.Data.LaunchCount())
        XCTAssertEqual(Statistics.Data.LaunchCount.value, 2)
        
        Statistics.launch(with: backend, host: MockHost(currentVersion: "1.0.1"))
        Statistics.update(Statistics.Data.LaunchCount())
        XCTAssertEqual(Statistics.Data.LaunchCount.value, 1)
        
        Statistics.launch(with: backend, host: MockHost(currentVersion: "1.0.2"))
        Statistics.update(Statistics.Data.LaunchCount())
        XCTAssertEqual(Statistics.Data.LaunchCount.value, 1)
        
        Statistics.launch(with: backend, host: MockHost(currentVersion: "1.0.2"))
        Statistics.update(Statistics.Data.LaunchCount())
        XCTAssertEqual(Statistics.Data.LaunchCount.value, 2)
    }
    
    func testUpdateClosure() {
        do {
            let backend = MockBackend("1.0.0")
            var flag = false
            Statistics.launch(with: backend, host: MockHost(currentVersion: "1.0.1")) { _ in
                flag = true
            }
            XCTAssertEqual(backend.latestVersion, "1.0.1")
            XCTAssertTrue(flag)
            flag = false
            Statistics.launch(with: backend, host: MockHost(currentVersion: "1.0.1")) { _ in
                flag = true
            }
            XCTAssertEqual(backend.latestVersion, "1.0.1")
            XCTAssertFalse(flag)
        }
        do {
            let backend = MockBackend("1.0.0")
            var flag = false
            Statistics.launch(with: backend, host: MockHost(currentVersion: "1.0.0")) { _ in
                flag = true
            }
            XCTAssertFalse(flag)
        }
        do {
            var backend: MockBackend?
            var flag = false
            do {
                backend = MockBackend("1.0.0")
                try Statistics.launch(with: backend!, host: MockHost(currentVersion: "1.0.1")) { _ in
                    throw NSError(domain: "", code: 0, userInfo: nil)
                }
                XCTFail()
            } catch {
                flag = true
            }
            XCTAssertEqual(backend?.latestVersion, "1.0.0")
            XCTAssert(flag)
        }
    }
    
    func testRemoveData() {
        let backend = MockBackend()
        Statistics.launch(with: backend, host: MockHost(currentVersion: "1.0.0"))
        Statistics.update(Statistics.Data.LaunchCount())
        Statistics.update(Statistics.Data.OtherCount(data: "data"))
        XCTAssertEqual(Statistics.Data.LaunchCount.value, 1)
        XCTAssertEqual(Statistics.Data.OtherCount.value, "data")
        
        Statistics.reset(for: Statistics.Data.LaunchCount.self)
        XCTAssertNil(Statistics.Data.LaunchCount.value)
        XCTAssertNotNil(Statistics.Data.OtherCount.value)
    }
    
    func testRemoveDataAll() {
        let backend = MockBackend()
        Statistics.launch(with: backend, host: MockHost(currentVersion: "1.0.0"))
        backend.write("other", forKey: "otherkey")
        Statistics.update(Statistics.Data.LaunchCount())
        XCTAssertEqual(Statistics.Data.LaunchCount.value, 1)
        XCTAssertNotNil(backend.read(forKey: "otherkey") as String?)
        
        Statistics.reset()
        XCTAssertNil(Statistics.Data.LaunchCount.value)
        XCTAssertNotNil(backend.read(forKey: "otherkey") as String?)
    }
}
