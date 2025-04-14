//
//  CategoryAnalysisView.swift
//  iOS-Finance-Manager
//
//  Created by Quang Nguyen on 4/14/25.
//

import SwiftUI

struct CategoryAnalysisView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var financeManager: FinanceManager
    
    var categoryTotals: [(category: Category, amount: Double)] {
        var totals: [Category: Double] = [:]
        for category in Category.allCases { totals[category] = 0 }
        for transaction in financeManager.transactions where transaction.isExpense {
            totals[transaction.category, default: 0] += transaction.amount
        }
        return totals.filter { $0.value > 0 }
            .map { (category: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }
    
    var totalExpenses: Double {
        categoryTotals.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Spending by Category")
                        .font(.headline)
                        .padding(.horizontal)
                    if categoryTotals.isEmpty {
                        Text("No expense data available")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 40)
                    } else {
                        ForEach(categoryTotals, id: \.category) { item in
                            CategoryProgressView(
                                category: item.category,
                                amount: item.amount,
                                percentage: totalExpenses > 0 ? item.amount / totalExpenses : 0
                            )
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Category Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { presentationMode.wrappedValue.dismiss() }
                }
            }
        }
    }
}

struct CategoryProgressView: View {
    let category: Category
    let amount: Double
    let percentage: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundColor(category.color)
                Text(category.rawValue)
                    .font(.subheadline)
                Spacer()
                Text(formattedAmount)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            HStack(spacing: 16) {
                ProgressView(value: percentage)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(height: 8)
                Text(String(format: "%.1f%%", percentage * 100))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 50, alignment: .trailing)
            }
        }
        .padding(.vertical, 4)
    }
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}
