//
//  Version.swift
//  Statistics
//
//  Created by 林 達也 on 2017/02/10.
//  Copyright © 2017年 林 達也. All rights reserved.
//

import Foundation

extension Statistics {
    public struct Version {
        public let major, minor, patch: Int
        
        init(major: Int, minor: Int, patch: Int) {
            (self.major, self.minor, self.patch) = (major, minor, patch)
        }
    }
}

extension Statistics.Version {
    init?(semanticVersioningString string: String) {
        var comps = string.components(separatedBy: ".")
        guard comps.count == 3 else { return nil }
        if comps[0].hasPrefix("v") {
            comps[0] = comps[0].replacingOccurrences(of: "v", with: "")
        }
        guard let major = Int(comps[0]), let minor = Int(comps[1]), let patch = Int(comps[2]) else { return nil }
        
        self.init(major: major, minor: minor, patch: patch)
    }
}

extension Statistics.Version: Comparable {
    public static func == (lhs: Statistics.Version, rhs: Statistics.Version) -> Bool {
        return lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch == rhs.patch
    }
    
    public static func < (lhs:Statistics.Version, rhs: Statistics.Version) -> Bool {
        return lhs.major < rhs.major || lhs.minor < rhs.minor || lhs.patch < rhs.patch
    }
}

extension Statistics.Version: CustomStringConvertible {
    public var description: String {
        return "\(major).\(minor).\(patch)"
    }
}
