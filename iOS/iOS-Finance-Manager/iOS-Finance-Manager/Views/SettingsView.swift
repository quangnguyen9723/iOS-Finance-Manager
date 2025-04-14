//
//  SettingsView.swift
//  iOS-Finance-Manager
//
//  Created by Quang Nguyen on 4/14/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var financeManager: FinanceManager
    @State private var showingCategoryAnalysis = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Button("Category Analysis") {
                        showingCategoryAnalysis = true
                    }
                }
                Section(header: Text("Account")) {
                    Button("Sign Out") {
                        Task { await authVM.signout() }
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingCategoryAnalysis) {
                CategoryAnalysisView()
                    .environmentObject(financeManager)
            }
        }
    }
}
