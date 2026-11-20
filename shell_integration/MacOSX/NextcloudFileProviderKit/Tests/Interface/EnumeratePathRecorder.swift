// SPDX-FileCopyrightText: 2026 Nextcloud GmbH and Nextcloud contributors
// SPDX-License-Identifier: LGPL-3.0-or-later

import Foundation
import NextcloudFileProviderKit

/// Thread-safe collector for the remote paths PROPFINDs are issued for. The mock's `enumerateCallHandler` may run off the test's thread, so the storage is guarded by a lock.
public final class EnumeratePathRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [(path: String, depth: EnumerateDepth)] = []

    public init() {}

    public func add(_ path: String, depth: EnumerateDepth = .targetAndDirectChildren) {
        lock.lock()
        defer { lock.unlock() }
        storage.append((path, depth))
    }

    /// Every read, whatever its depth.
    public var paths: [String] {
        lock.lock()
        defer { lock.unlock() }
        return storage.map(\.path)
    }

    /// The reads of a directory with its children.
    public var listings: [String] {
        lock.lock()
        defer { lock.unlock() }
        return storage.filter { $0.depth != .target }.map(\.path)
    }

    /// The reads of an item alone.
    public var probes: [String] {
        lock.lock()
        defer { lock.unlock() }
        return storage.filter { $0.depth == .target }.map(\.path)
    }

    public var count: Int {
        paths.count
    }

    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        storage.removeAll()
    }

    /// Attach the recorder to a mock so every read is recorded.
    public func record(on remoteInterface: MockRemoteInterface) {
        remoteInterface.enumerateCallHandler = { [self] remotePath, depth, _, _, _, _, _, _ in
            add(remotePath, depth: depth)
        }
    }
}
