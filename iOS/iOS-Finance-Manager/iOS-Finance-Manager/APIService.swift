//
//  APIService.swift
//  iOS-Finance-Manager
//
//  Created by Quang Nguyen, Aiden Le, Anh Phan on 4/14/25.
//

import Foundation

struct APIService {
    static let baseURL = "https://ios-finance-manager.onrender.com"

    static func login(email: String, password: String) async throws -> AuthResponse {
        guard let url = URL(string: "\(baseURL)/auth/signin") else { throw URLError(.unknown) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["email": email, "password": password]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }
    
    static func signup(email: String, password: String) async throws -> AuthResponse {
        guard let url = URL(string: "\(baseURL)/auth/signup") else { throw URLError(.unknown) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["email": email, "password": password]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }
    
    static func fetchTransactions(token: String) async throws -> [Transaction] {
        guard let url = URL(string: "\(baseURL)/transactions") else { throw URLError(.unknown) }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.data(for: request)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601 // Fallback handled in Transaction
        return try decoder.decode([Transaction].self, from: data)
    }
    
    static func addTransaction(transaction: Transaction, token: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/transactions") else { throw URLError(.unknown) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(transaction)
        let (responseData, _) = try await URLSession.shared.data(for: request)
        let result = try JSONDecoder().decode([String: String].self, from: responseData)
        guard let transactionID = result["transaction_id"] else {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        return transactionID
    }
    
    static func updateTransaction(transaction: Transaction, token: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/transactions/\(transaction.id)") else { throw URLError(.unknown) }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(transaction)
        let (responseData, _) = try await URLSession.shared.data(for: request)
        let result = try JSONDecoder().decode([String: String].self, from: responseData)
        guard let message = result["message"] else {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid update response"])
        }
        return message
    }
    
    static func deleteTransaction(transactionID: String, token: String) async throws {
        guard let url = URL(string: "\(baseURL)/transactions/\(transactionID)") else { throw URLError(.unknown) }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        _ = try await URLSession.shared.data(for: request)
    }
    
    static func fetchTransactionSummary(token: String) async throws -> TransactionSummary {
        guard let url = URL(string: "\(baseURL)/transactions/summary") else { throw URLError(.unknown) }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // Assuming your summary endpoint requires authorization:
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(TransactionSummary.self, from: data)
    }
}
