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
        hash.removeAll()
    }
}

private struct LaunchCount: StatisticsData {
    public typealias Value = IncrementalValueController
    public static let key = "launchCount"
}

private extension Statistics.Data {
    static var launchCount: LaunchCount.Type { return LaunchCount.self }
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
        XCTAssertEqual(Statistics.Data.launchCount.value ?? 0, 0)
        Statistics.version = "1.0.0"
        Statistics.launch(with: backend)
        Statistics.update(LaunchCount.self)
        XCTAssertEqual(Statistics.Data.launchCount.value, 1)
        
        Statistics.version = "1.0.0"
        Statistics.launch(with: backend)
        Statistics.update(LaunchCount.self)
        XCTAssertEqual(Statistics.Data.launchCount.value, 2)
        
        Statistics.version = "1.0.1"
        Statistics.launch(with: backend)
        Statistics.update(LaunchCount.self)
        XCTAssertEqual(Statistics.Data.launchCount.value, 1)
        
        Statistics.version = "1.0.2"
        Statistics.launch(with: backend)
        Statistics.update(LaunchCount.self)
        XCTAssertEqual(Statistics.Data.launchCount.value, 1)
        
        Statistics.version = "1.0.2"
        Statistics.launch(with: backend)
        Statistics.update(LaunchCount.self)
        XCTAssertEqual(Statistics.Data.launchCount.value, 2)
    }
    
    func testUpdateClosure() {
        do {
            let backend = MockBackend(["_Statistics::version": "1.0.0"])
            var flag = false
            Statistics.version = "1.0.1"
            Statistics.launch(with: backend) { _ in
                flag = true
            }
            XCTAssertTrue(flag)
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
    }
}
