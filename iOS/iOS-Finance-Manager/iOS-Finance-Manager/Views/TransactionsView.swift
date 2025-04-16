//
//  TransactionsView.swift
//  iOS-Finance-Manager
//
//  Created by Quang Nguyen, Aiden Le, Anh Phan on 4/14/25.
//

import SwiftUI

struct TransactionsView: View {
    @EnvironmentObject var financeManager: FinanceManager
    @EnvironmentObject var authVM: AuthViewModel
//    @State private var showingAddTransactionSheet = false
    @State private var selectedFilter: TransactionFilter = .all
    @State private var searchText = ""
    
    @State private var transactionType: TransactionType? = nil
    
    enum TransactionFilter: Equatable {
        case all, expenses, income, category(Category)
        
        var name: String {
            switch self {
            case .all: return "All"
            case .expenses: return "Expenses"
            case .income: return "Income"
            case .category(let category): return category.rawValue
            }
        }
        
        static func == (lhs: TransactionFilter, rhs: TransactionFilter) -> Bool {
            switch (lhs, rhs) {
            case (.all, .all), (.expenses, .expenses), (.income, .income):
                return true
            case (.category(let lhsCategory), .category(let rhsCategory)):
                return lhsCategory == rhsCategory
            default:
                return false
            }
        }
    }
    
    var filteredTransactions: [Transaction] {
        let sorted = financeManager.transactions.sorted(by: { $0.date > $1.date })
        let filtered: [Transaction]
        switch selectedFilter {
        case .all:
            filtered = sorted
        case .expenses:
            filtered = sorted.filter { $0.isExpense }
        case .income:
            filtered = sorted.filter { !$0.isExpense }
        case .category(let category):
            filtered = sorted.filter { $0.category == category }
        }
        return searchText.isEmpty ? filtered : filtered.filter { $0.title.lowercased().contains(searchText.lowercased()) }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search transactions", text: $searchText)
                        .disableAutocorrection(true)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        FilterChip(title: "All", isSelected: selectedFilter == .all, action: { selectedFilter = .all })
                        FilterChip(title: "Expenses", isSelected: selectedFilter == .expenses, action: { selectedFilter = .expenses })
                        FilterChip(title: "Income", isSelected: selectedFilter == .income, action: { selectedFilter = .income })
                        ForEach(Category.allCases, id: \.self) { category in
                            FilterChip(title: category.rawValue,
                                       icon: category.icon,
                                       color: category.color,
                                       isSelected: selectedFilter == .category(category),
                                       action: { selectedFilter = .category(category) })
                        }
                    }
                    .padding(.horizontal)
                }
                
                if filteredTransactions.isEmpty {
                    VStack {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                            .padding()
                        Text(financeManager.transactions.isEmpty ? "No Transactions" : "No Matches Found")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text(financeManager.transactions.isEmpty ? "Add a transaction to get started" : "Try adjusting your search or filters")
                            .foregroundColor(.secondary)
                            .padding(.top, 1)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(filteredTransactions) { transaction in
                            NavigationLink(destination: EditTransactionView(transaction: transaction)) {
                                TransactionRowView(transaction: transaction)
                            }
                        }
                        .onDelete(perform: deleteTransaction)
                    }
                }
            }
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { transactionType = .expense }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $transactionType) { type in
                AddTransactionView(isExpense: type == .expense)
                    .environmentObject(authVM)
                    .environmentObject(financeManager)
            }
        }
    }
    
    private func deleteTransaction(at offsets: IndexSet) {
        guard let token = authVM.token else { return }
        let transactionsToDelete = offsets.map { filteredTransactions[$0] }
        for transaction in transactionsToDelete {
            Task {
                await financeManager.deleteTransaction(transaction, token: token)
            }
        }
    }
}
