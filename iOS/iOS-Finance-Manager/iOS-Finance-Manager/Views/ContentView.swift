//
//  ContentView.swift
//  iOS-Finance-Manager
//
//  Created by Quang Nguyen, Aiden Le, Anh Phan on 4/14/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var authVM = AuthViewModel()
    @StateObject var financeManager = FinanceManager()
    
    var body: some View {
        Group {
            if authVM.isLoggedIn {
                MainTabView()
                    .environmentObject(authVM)
                    .environmentObject(financeManager)
            } else {
                AuthenticationView()
                    .environmentObject(authVM)
            }
        }
        .onChange(of: authVM.token) { _, new in
            financeManager.transactions = []
            if let token = new {
                Task { await financeManager.fetchTransactions(token: token) }
            }
        }
    }
}
