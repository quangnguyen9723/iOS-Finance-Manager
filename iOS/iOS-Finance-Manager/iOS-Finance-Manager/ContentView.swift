//
//
//  Created by Quang Nguyen on 3/4/25.
//

import SwiftUI

// MARK: - Models

enum Category: String, CaseIterable, Codable {
    case food = "Food"
    case transportation = "Transportation"
    case housing = "Housing"
    case utilities = "Utilities"
    case entertainment = "Entertainment"
    case health = "Health"
    case shopping = "Shopping"
    case income = "Income"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .transportation: return "car.fill"
        case .housing: return "house.fill"
        case .utilities: return "bolt.fill"
        case .entertainment: return "tv.fill"
        case .health: return "heart.fill"
        case .shopping: return "bag.fill"
        case .income: return "dollarsign.circle.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .food: return .orange
        case .transportation: return .blue
        case .housing: return .brown
        case .utilities: return .yellow
        case .entertainment: return .purple
        case .health: return .red
        case .shopping: return .pink
        case .income: return .green
        case .other: return .gray
        }
    }
}

struct Transaction: Identifiable, Codable {
    var id = UUID()
    var title: String
    var amount: Double
    var date: Date
    var category: Category
    var isExpense: Bool
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

// MARK: - View Model

class FinanceManager: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var balance: Double = 0.0
    
    private let transactionsKey = "savedTransactions"
    private let balanceKey = "savedBalance"
    
    init() {
        loadData()
    }
    
    func addTransaction(_ transaction: Transaction) {
        transactions.append(transaction)
        if transaction.isExpense {
            balance -= transaction.amount
        } else {
            balance += transaction.amount
        }
        saveData()
    }
    
    func removeTransaction(at indexSet: IndexSet) {
        for index in indexSet {
            let transaction = transactions[index]
            if transaction.isExpense {
                balance += transaction.amount
            } else {
                balance -= transaction.amount
            }
        }
        transactions.remove(atOffsets: indexSet)
        saveData()
    }
    
    func updateBalance(newBalance: Double) {
        balance = newBalance
        saveData()
    }
    
    func saveData() {
        if let encoded = try? JSONEncoder().encode(transactions) {
            UserDefaults.standard.set(encoded, forKey: transactionsKey)
        }
        UserDefaults.standard.set(balance, forKey: balanceKey)
    }
    
    func loadData() {
        if let transactionsData = UserDefaults.standard.data(forKey: transactionsKey),
           let decodedTransactions = try? JSONDecoder().decode([Transaction].self, from: transactionsData) {
            transactions = decodedTransactions
        }
        balance = UserDefaults.standard.double(forKey: balanceKey)
    }
    
    func recentTransactions(limit: Int = 5) -> [Transaction] {
        return Array(transactions.sorted(by: { $0.date > $1.date }).prefix(limit))
    }
}

// MARK: - Views

struct ContentView: View {
    @StateObject private var financeManager = FinanceManager()
    
    var body: some View {
        TabView {
            DashboardView()
                .environmentObject(financeManager)
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
            TransactionsView()
                .environmentObject(financeManager)
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet")
                }
            SettingsView()
                .environmentObject(financeManager)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

struct DashboardView: View {
    @EnvironmentObject var financeManager: FinanceManager
    @State private var showingUpdateBalanceSheet = false
    @State private var showingAddTransactionSheet = false
    @State private var isExpenseForNewTransaction = true  // New state variable
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Balance Card
                    VStack(alignment: .leading) {
                        Text("Current Balance")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text(formattedBalance)
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(financeManager.balance >= 0 ? .primary : .red)
                        Button("Update Balance") {
                            showingUpdateBalanceSheet = true
                        }
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    // Quick Action Buttons
                    HStack {
                        Button(action: {
                            isExpenseForNewTransaction = false
                            showingAddTransactionSheet = true
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
                            isExpenseForNewTransaction = true
                            showingAddTransactionSheet = true
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
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    // Recent Transactions
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Recent Transactions")
                                .font(.headline)
                            Spacer()
                            NavigationLink(destination: TransactionsView()) {
                                Text("See All")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                        if financeManager.transactions.isEmpty {
                            Text("No transactions yet")
                                .foregroundColor(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            ForEach(financeManager.recentTransactions()) { transaction in
                                TransactionRowView(transaction: transaction)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .sheet(isPresented: $showingUpdateBalanceSheet) {
                UpdateBalanceView()
            }
            .sheet(isPresented: $showingAddTransactionSheet) {
                AddTransactionView(isExpense: isExpenseForNewTransaction)
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
            VStack(alignment: .leading) {
                Text(transaction.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                HStack {
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
        formatter.timeStyle = .none
        return formatter
    }
}

struct UpdateBalanceView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var financeManager: FinanceManager
    @State private var balanceText = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Update Account Balance")) {
                    TextField("Balance", text: $balanceText)
                        .keyboardType(.decimalPad)
                        .onAppear {
                            balanceText = String(format: "%.2f", financeManager.balance)
                        }
                    Text("This will set your account balance to the amount above.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Update Balance")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let newBalance = Double(balanceText) {
                            financeManager.updateBalance(newBalance: newBalance)
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(balanceText.isEmpty)
                }
            }
        }
    }
}

struct TransactionsView: View {
    @EnvironmentObject var financeManager: FinanceManager
    @State private var showingAddTransactionSheet = false
    @State private var selectedFilter: TransactionFilter = .all
    @State private var searchText = ""
    
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
        if searchText.isEmpty {
            return filtered
        } else {
            return filtered.filter {
                $0.title.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
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
                
                // Category Filter
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
                            TransactionRowView(transaction: transaction)
                        }
                        .onDelete(perform: financeManager.removeTransaction)
                    }
                }
            }
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTransactionSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTransactionSheet) {
                // Default to Expense in TransactionsView
                AddTransactionView(isExpense: true)
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    var icon: String? = nil
    var color: Color? = nil
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon, let color = color {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.caption)
                }
                Text(title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color(.systemGray6))
            .foregroundColor(isSelected ? .accentColor : .primary)
            .cornerRadius(20)
        }
    }
}

struct AddTransactionView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var financeManager: FinanceManager
    
    @State private var title = ""
    @State private var amount = ""
    @State private var date = Date()
    @State private var selectedCategory: Category
    @State private var isExpense: Bool
    
    init(isExpense: Bool = true) {
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
                    
                    // Reversed order: Income first, then Expense
                    Picker("Type", selection: $isExpense) {
                        Text("Income").tag(false)
                        Text("Expense").tag(true)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: isExpense) { newValue in
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
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTransaction()
                    }
                    .disabled(title.isEmpty || amount.isEmpty)
                }
            }
        }
    }
    
    private func saveTransaction() {
        guard let amountValue = Double(amount) else { return }
        let category = isExpense ? selectedCategory : Category.income
        let transaction = Transaction(
            title: title,
            amount: amountValue,
            date: date,
            category: category,
            isExpense: isExpense
        )
        financeManager.addTransaction(transaction)
        presentationMode.wrappedValue.dismiss()
    }
}

struct SettingsView: View {
    @EnvironmentObject var financeManager: FinanceManager
    @State private var showingResetConfirmation = false
    @State private var showingCategoryAnalysis = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Button("Category Analysis") {
                        showingCategoryAnalysis = true
                    }
                }
                Section(header: Text("Data")) {
                    Button("Reset All Data") {
                        showingResetConfirmation = true
                    }
                    .foregroundColor(.red)
                }
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .alert(isPresented: $showingResetConfirmation) {
                Alert(
                    title: Text("Reset All Data"),
                    message: Text("Are you sure you want to reset all data? This cannot be undone."),
                    primaryButton: .destructive(Text("Reset")) {
                        financeManager.transactions = []
                        financeManager.balance = 0
                        financeManager.saveData()
                    },
                    secondaryButton: .cancel()
                )
            }
            .sheet(isPresented: $showingCategoryAnalysis) {
                CategoryAnalysisView()
            }
        }
    }
}

struct CategoryAnalysisView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var financeManager: FinanceManager
    
    var categoryTotals: [(category: Category, amount: Double)] {
        var totals: [Category: Double] = [:]
        for category in Category.allCases {
            totals[category] = 0
        }
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
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
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
                    .progressViewStyle(LinearProgressViewStyle(tint: category.color))
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

@main
struct SimpleBudgetApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

#Preview {
    ContentView()
}
