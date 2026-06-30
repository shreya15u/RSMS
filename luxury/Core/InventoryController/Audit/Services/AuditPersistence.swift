//
//  AuditPersistence.swift
//  luxury
//
//  Created by Nalinish Ranjan on 27/05/26.
//

import Foundation

final class AuditPersistence {
    static let shared = AuditPersistence()
    
    private let keyPrefix = "rsms_audit_session_"
    private let listKey = "rsms_audit_sessions_list"
    
    private init() {}
    
    func loadSession(id: UUID) -> AuditSession? {
        guard let data = UserDefaults.standard.data(forKey: keyPrefix + id.uuidString) else {
            return nil
        }
        return try? JSONDecoder().decode(AuditSession.self, from: data)
    }
    
    func saveSession(_ session: AuditSession) {
        do {
            let data = try JSONEncoder().encode(session)
            UserDefaults.standard.set(data, forKey: keyPrefix + session.id.uuidString)
            
            var list = loadAllSessionIds()
            if !list.contains(session.id) {
                list.append(session.id)
                saveAllSessionIds(list)
            }
        } catch {
            print("Error encoding audit session: \(error)")
        }
    }
    
    func clearSession(id: UUID) {
        UserDefaults.standard.removeObject(forKey: keyPrefix + id.uuidString)
        var list = loadAllSessionIds()
        list.removeAll { $0 == id }
        saveAllSessionIds(list)
    }
    
    func loadAllSessions() -> [AuditSession] {
        let ids = loadAllSessionIds()
        return ids.compactMap { loadSession(id: $0) }
    }
    
    private func loadAllSessionIds() -> [UUID] {
        guard let data = UserDefaults.standard.data(forKey: listKey) else {
            return []
        }
        return (try? JSONDecoder().decode([UUID].self, from: data)) ?? []
    }
    
    private func saveAllSessionIds(_ list: [UUID]) {
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: listKey)
        }
    }
    
    func clearAllSessions() {
        let ids = loadAllSessionIds()
        for id in ids {
            UserDefaults.standard.removeObject(forKey: keyPrefix + id.uuidString)
        }
        UserDefaults.standard.removeObject(forKey: listKey)
    }
}
