//
//  EditTransactionView.swift
//  iOS-Finance-Manager
//
//  Created by Quang Nguyen on 4/14/25.
//

import SwiftUI

struct EditTransactionView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var financeManager: FinanceManager
    
    @State var transaction: Transaction
    @State private var title: String
    @State private var amount: String
    @State private var date: Date
    @State private var selectedCategory: Category
    @State private var isExpense: Bool
    
    init(transaction: Transaction) {
        self._transaction = State(initialValue: transaction)
        self._title = State(initialValue: transaction.title)
        self._amount = State(initialValue: String(format: "%.2f", transaction.amount))
        self._date = State(initialValue: transaction.date)
        self._selectedCategory = State(initialValue: transaction.category)
        self._isExpense = State(initialValue: transaction.isExpense)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Transaction Details")) {
                    TextField("Title", text: $title)
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    Picker("Type", selection: $isExpense) {
                        Text("Income").tag(false)
                        Text("Expense").tag(true)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: isExpense) { _, newValue in
                        if !newValue {
                            selectedCategory = .income
                        } else if selectedCategory == .income {
                            selectedCategory = .other
                        }
                    }
                    if isExpense {
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(Category.allCases.filter { $0 != .income }, id: \.self) { category in
                                HStack {
                                    Image(systemName: category.icon)
                                        .foregroundColor(category.color)
                                    Text(category.rawValue)
                                }
                                .tag(category)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Transaction")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task { await saveEdits() }
                    }
                    .disabled(title.isEmpty || amount.isEmpty)
                }
            }
        }
    }
    
    private func saveEdits() async {
        guard let amountValue = Double(amount),
              let token = authVM.token else { return }
        let updatedTransaction = Transaction(
            id: transaction.id,
            title: title,
            amount: amountValue,
            date: date,
            category: isExpense ? selectedCategory : .income,
            isExpense: isExpense
        )
        await financeManager.updateTransaction(updatedTransaction, token: token)
        presentationMode.wrappedValue.dismiss()
    }
}
