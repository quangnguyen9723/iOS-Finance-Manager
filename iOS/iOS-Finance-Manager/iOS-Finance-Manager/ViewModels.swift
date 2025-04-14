//
//  ViewModels.swift
//  iOS-Finance-Manager
//
//  Created by Quang Nguyen on 4/14/25.
//

import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var token: String? = nil
    @Published var user: User? = nil
    @Published var errorMessage: String? = nil
    
    func login(email: String, password: String) async {
        do {
            let response = try await APIService.login(email: email, password: password)
            self.token = response.token
            self.user = User(uid: response.uid, email: response.email)
            self.isLoggedIn = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func signup(email: String, password: String) async {
        do {
            let response = try await APIService.signup(email: email, password: password)
            self.token = response.token
            self.user = User(uid: response.uid, email: response.email)
            self.isLoggedIn = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func signout() async {
        guard let token = token else { return }
        do {
            try await APIService.signout(token: token)
            self.token = nil
            self.user = nil
            self.isLoggedIn = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

@MainActor
class FinanceManager: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var isLoadingTransactions: Bool = false
    
    var balance: Double {
        transactions.reduce(0) { $0 + ($1.isExpense ? -$1.amount : $1.amount) }
    }
    
    func fetchTransactions(token: String) async {
        isLoadingTransactions = true
        do {
            let fetched = try await APIService.fetchTransactions(token: token)
            self.transactions = fetched.sorted(by: { $0.date > $1.date })
        } catch {
            print("Error fetching transactions: \(error)")
        }
        isLoadingTransactions = false
    }
    
    func addTransaction(_ transaction: Transaction, token: String) async {
        do {
            let newID = try await APIService.addTransaction(transaction: transaction, token: token)
            var newTransaction = transaction
            newTransaction.id = newID
            self.transactions.insert(newTransaction, at: 0)
        } catch {
            print("Error adding transaction: \(error)")
        }
    }
    
    func updateTransaction(_ transaction: Transaction, token: String) async {
        do {
            _ = try await APIService.updateTransaction(transaction: transaction, token: token)
            if let index = self.transactions.firstIndex(where: { $0.id == transaction.id }) {
                self.transactions[index] = transaction
            }
        } catch {
            print("Error updating transaction: \(error)")
        }
    }
    
    func deleteTransaction(_ transaction: Transaction, token: String) async {
        do {
            try await APIService.deleteTransaction(transactionID: transaction.id, token: token)
            self.transactions.removeAll { $0.id == transaction.id }
        } catch {
            print("Error deleting transaction: \(error)")
        }
    }
}
