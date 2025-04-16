//
//  DashboardView.swift
//  iOS-Finance-Manager
//
//  Created by Quang Nguyen, Aiden Le, Anh Phan on 4/14/25.
//

import SwiftUI

enum TransactionType: String, Identifiable {
    case income, expense
    var id: String { self.rawValue }
}

struct DashboardView: View {
    @EnvironmentObject var financeManager: FinanceManager
    @EnvironmentObject var authVM: AuthViewModel
    
    @State private var transactionType: TransactionType? = nil

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Balance")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        if financeManager.isLoadingTransactions {
                            HStack {
                                ProgressView()
                                Text("Loading...")
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Text(formattedBalance)
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(financeManager.balance >= 0 ? .primary : .red)
                        }
                        Button("Refresh") {
                            if let token = authVM.token {
                                Task { await financeManager.fetchTransactions(token: token) }
                            }
                        }
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 5)
                    
                    HStack {
                        Button(action: {
                            transactionType = .income
                        }) {
                            VStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.green)
                                Text("Add Income")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                        }
                        Button(action: {
                            transactionType = .expense
                        }) {
                            VStack {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.red)
                                Text("Add Expense")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                        }
                    }
                    .shadow(radius: 5)
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Recent Transactions")
                                .font(.headline)
                            Spacer()
                            NavigationLink(destination: TransactionsView()) {
                                Text("See All")
                                    .foregroundColor(.blue)
                            }
                        }
                        if financeManager.transactions.isEmpty {
                            Text("No transactions yet")
                                .foregroundColor(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            ForEach(financeManager.transactions.prefix(5)) { transaction in
                                NavigationLink(destination: EditTransactionView(transaction: transaction)) {
                                    TransactionRowView(transaction: transaction)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 5)
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .sheet(item: $transactionType) { type in
                AddTransactionView(isExpense: type == .expense)
                    .environmentObject(authVM)
                    .environmentObject(financeManager)
            }
        }
    }
    
    var formattedBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: NSNumber(value: financeManager.balance)) ?? "$0.00"
    }
}

struct TransactionRowView: View {
    let transaction: Transaction
    
    var body: some View {
        HStack {
            Image(systemName: transaction.category.icon)
                .font(.title3)
                .foregroundColor(transaction.category.color)
                .frame(width: 36, height: 36)
                .background(transaction.category.color.opacity(0.1))
                .cornerRadius(8)
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                HStack(spacing: 4) {
                    Text(transaction.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(dateFormatter.string(from: transaction.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Text(transaction.isExpense ? "-\(transaction.formattedAmount)" : "+\(transaction.formattedAmount)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(transaction.isExpense ? .red : .green)
        }
        .padding(.vertical, 8)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}
