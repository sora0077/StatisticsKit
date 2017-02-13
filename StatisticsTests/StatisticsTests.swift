//
//  StatisticsTests.swift
//  StatisticsTests
//
//  Created by 林 達也 on 2017/02/10.
//  Copyright © 2017年 林 達也. All rights reserved.
//

import XCTest
@testable import StatisticsKit

final class MockBackend: Backend {
    private var hash: [String: Any]
    
    init(_ defaults: [String: Any] = [:]) {
        hash = defaults
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
        Statistics.version = "1.0.0"
        Statistics.launch(with: backend)
        Statistics.update(Statistics.Data.LaunchCount())
        XCTAssertEqual(Statistics.Data.LaunchCount.value, 1)
        
        Statistics.version = "1.0.0"
        Statistics.launch(with: backend)
        Statistics.update(Statistics.Data.LaunchCount())
        XCTAssertEqual(Statistics.Data.LaunchCount.value, 2)
        
        Statistics.version = "1.0.1"
        Statistics.launch(with: backend)
        Statistics.update(Statistics.Data.LaunchCount())
        XCTAssertEqual(Statistics.Data.LaunchCount.value, 1)
        
        Statistics.version = "1.0.2"
        Statistics.launch(with: backend)
        Statistics.update(Statistics.Data.LaunchCount())
        XCTAssertEqual(Statistics.Data.LaunchCount.value, 1)
        
        Statistics.version = "1.0.2"
        Statistics.launch(with: backend)
        Statistics.update(Statistics.Data.LaunchCount())
        XCTAssertEqual(Statistics.Data.LaunchCount.value, 2)
    }
    
    func testUpdateClosure() {
        do {
            let backend = MockBackend(["_Statistics::version": "1.0.0"])
            var flag = false
            Statistics.version = "1.0.1"
            Statistics.launch(with: backend) { _ in
                flag = true
            }
            XCTAssertEqual(Statistics.shared.previous, Statistics.Version(major: 1, minor: 0, patch: 1))
            XCTAssertTrue(flag)
            flag = false
            Statistics.launch(with: backend) { _ in
                flag = true
            }
            XCTAssertEqual(Statistics.shared.previous, Statistics.Version(major: 1, minor: 0, patch: 1))
            XCTAssertFalse(flag)
        }
        do {
            let backend = MockBackend(["_Statistics::version": "1.0.0"])
            var flag = false
            Statistics.version = "1.0.0"
            Statistics.launch(with: backend) { _ in
                flag = true
            }
            XCTAssertFalse(flag)
        }
        do {
            var flag = false
            do {
                let backend = MockBackend(["_Statistics::version": "1.0.0"])
                Statistics.version = "1.0.1"
                try Statistics.launch(with: backend) { _ in
                    throw NSError(domain: "", code: 0, userInfo: nil)
                }
                XCTFail()
            } catch {
                flag = true
            }
            XCTAssertEqual(Statistics.shared.previous, Statistics.Version(major: 1, minor: 0, patch: 0))
            XCTAssert(flag)
        }
    }
    
    func testRemoveData() {
        let backend = MockBackend()
        Statistics.version = "1.0.0"
        Statistics.launch(with: backend)
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
        Statistics.version = "1.0.0"
        Statistics.launch(with: backend)
        backend.write("other", forKey: "otherkey")
        Statistics.update(Statistics.Data.LaunchCount())
        XCTAssertEqual(Statistics.Data.LaunchCount.value, 1)
        XCTAssertNotNil(backend.read(forKey: "otherkey") as String?)
        
        Statistics.reset()
        XCTAssertNil(Statistics.Data.LaunchCount.value)
        XCTAssertNotNil(backend.read(forKey: "otherkey") as String?)
    }
}
