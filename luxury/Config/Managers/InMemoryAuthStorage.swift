//
//  InMemoryAuthStorage.swift
//  luxury
//

import Foundation
import Supabase

final class InMemoryAuthStorage: AuthLocalStorage, @unchecked Sendable {
    private var storage: [String: Data] = [:]
    private let queue = DispatchQueue(label: "com.luxury.InMemoryAuthStorage")
    
    func store(key: String, value: Data) throws {
        queue.sync {
            storage[key] = value
        }
    }
    
    func retrieve(key: String) throws -> Data? {
        queue.sync {
            return storage[key]
        }
    }
    
    func remove(key: String) throws {
        queue.sync {
            _ = storage.removeValue(forKey: key)
        }
    }
}
