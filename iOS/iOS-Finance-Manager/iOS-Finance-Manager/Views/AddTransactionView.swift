//
//  AddTransactionView.swift
//  iOS-Finance-Manager
//
//  Created by Quang Nguyen, Aiden Le, Anh Phan on 4/14/25.
//

import SwiftUI

struct AddTransactionView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var financeManager: FinanceManager
    
    @State private var title = ""
    @State private var amount = ""
    @State private var date = Date()
    @State private var selectedCategory: Category
    @State private var isExpense: Bool
    
    init(isExpense: Bool) {
        self._isExpense = State(initialValue: isExpense)
        self._selectedCategory = State(initialValue: isExpense ? .other : .income)
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
            .navigationTitle("Add Transaction")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task { await saveTransaction() }
                    }
                    .disabled(title.isEmpty || amount.isEmpty)
                }
            }
        }
    }
    
    private func saveTransaction() async {
        guard let amountValue = Double(amount),
              let token = authVM.token else { return }
        let transaction = Transaction(
            title: title,
            amount: amountValue,
            date: date,
            category: isExpense ? selectedCategory : .income,
            isExpense: isExpense
        )
        await financeManager.addTransaction(transaction, token: token)
        presentationMode.wrappedValue.dismiss()
    }
}
