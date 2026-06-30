//
//  AuthService.swift
//  luxury
//
//  Created by Aditya Chauhan on 18/05/26.
//

import Foundation
import Supabase

final class AuthService {
    private let client = SupabaseManager.shared.client
    
    func getCurrentSession() async -> Session? {
        return try? await client.auth.session
    }
    
    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
    }
    
    func signUp(email: String, password: String, data: [String: AnyJSON]? = nil) async throws -> User {
        let response = try await client.auth.signUp(email: email, password: password, data: data)
        return response.user
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    func adminCreateUser(email: String, password: String, role: UserRole) async throws -> UUID {
        let payload: [String: AnyJSON] = [
            "email": .string(email),
            "password": .string(password),
            "role": .string(role.rawValue)
        ]
        
        struct CreateUserResponse: Decodable {
            struct UserData: Decodable {
                let id: UUID
            }
            let user: UserData
        }
        
        let response: CreateUserResponse = try await client.functions.invoke(
            "create-invited-user",
            options: FunctionInvokeOptions(body: payload)
        )
        
        return response.user.id
    }
    
    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
    }
    
    func updateUserMetadata(data: [String: AnyJSON]) async throws {
        _ = try await client.auth.update(user: UserAttributes(data: data))
    }

    
    func observeAuthState(onChange: @escaping (AuthChangeEvent, Session?) -> Void) {
        Task {
            for await (event, session) in client.auth.authStateChanges {
                onChange(event, session)
            }
        }
    }
}
