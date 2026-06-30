import Foundation
import UIKit
import Network

actor CacheManager {
    static let shared = CacheManager()
    
    private let baseDirectory: URL = {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("luxuryCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()
    
    private var memoryCache: [String: Data] = [:]
    private let maxMemoryCacheSize = 250 * 1024 * 1024 // 250MB
    private var currentMemorySize = 0
    
    private func bucketDirectory(for bucket: String) -> URL {
        let dir = baseDirectory.appendingPathComponent(bucket, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    private func fileURL(bucket: String, key: String) -> URL {
        let safeKey = key.replacingOccurrences(of: "/", with: "_")
        return bucketDirectory(for: bucket).appendingPathComponent(safeKey)
    }
    
    private func cacheKey(bucket: String, key: String) -> String {
        "\(bucket)/\(key)"
    }
    
    // MARK: - Read
    
    func getData(bucket: String, key: String) -> Data? {
        let ck = cacheKey(bucket: bucket, key: key)
        if let mem = memoryCache[ck] { return mem }
        
        let url = fileURL(bucket: bucket, key: key)
        guard let data = try? Data(contentsOf: url) else { return nil }
        
        storeInMemory(data: data, for: ck)
        return data
    }
    
    func getImage(bucket: String, key: String) -> UIImage? {
        guard let data = getData(bucket: bucket, key: key) else { return nil }
        return UIImage(data: data)
    }
    
    // MARK: - Write
    
    func store(data: Data, bucket: String, key: String) {
        let url = fileURL(bucket: bucket, key: key)
        try? data.write(to: url)
        
        let ck = cacheKey(bucket: bucket, key: key)
        storeInMemory(data: data, for: ck)
    }
    
    func storeImage(_ image: UIImage, bucket: String, key: String, quality: CGFloat = 0.8) {
        guard let data = image.jpegData(compressionQuality: quality) else { return }
        store(data: data, bucket: bucket, key: key)
    }
    
    // MARK: - Text
    
    func getText(bucket: String, key: String) -> String? {
        guard let data = getData(bucket: bucket, key: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    func storeText(_ text: String, bucket: String, key: String) {
        guard let data = text.data(using: .utf8) else { return }
        store(data: data, bucket: bucket, key: key)
    }
    
    // MARK: - Objects (Codable)
    
    func getObject<T: Decodable>(_ type: T.Type, bucket: String, key: String) -> T? {
        guard let data = getData(bucket: bucket, key: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
    
    func storeObject<T: Encodable>(_ object: T, bucket: String, key: String) {
        guard let data = try? JSONEncoder().encode(object) else { return }
        store(data: data, bucket: bucket, key: key)
    }
    
    // MARK: - Delete
    
    func remove(bucket: String, key: String) {
        let url = fileURL(bucket: bucket, key: key)
        try? FileManager.default.removeItem(at: url)
        
        let ck = cacheKey(bucket: bucket, key: key)
        if let data = memoryCache[ck] {
            currentMemorySize -= data.count
        }
        memoryCache[ck] = nil
    }
    
    func clearBucket(_ bucket: String) {
        let dir = bucketDirectory(for: bucket)
        try? FileManager.default.removeItem(at: dir)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        
        let prefix = "\(bucket)/"
        for key in memoryCache.keys where key.hasPrefix(prefix) {
            if let data = memoryCache[key] {
                currentMemorySize -= data.count
            }
            memoryCache[key] = nil
        }
    }
    
    func clearAll() {
        try? FileManager.default.removeItem(at: baseDirectory)
        try? FileManager.default.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
        memoryCache.removeAll()
        currentMemorySize = 0
    }
    
    // MARK: - Helpers
    
    func exists(bucket: String, key: String) -> Bool {
        let ck = cacheKey(bucket: bucket, key: key)
        if memoryCache[ck] != nil { return true }
        return FileManager.default.fileExists(atPath: fileURL(bucket: bucket, key: key).path)
    }
    
    private func storeInMemory(data: Data, for key: String) {
        if currentMemorySize + data.count > maxMemoryCacheSize {
            evictMemory()
        }
        memoryCache[key] = data
        currentMemorySize += data.count
    }
    
    private func evictMemory() {
        memoryCache.removeAll()
        currentMemorySize = 0
    }
}
