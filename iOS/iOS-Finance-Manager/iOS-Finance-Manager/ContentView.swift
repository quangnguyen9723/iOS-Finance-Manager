import SwiftUI

// MARK: - API Service

struct APIService {
    static let baseURL = "https://ios-finance-manager.onrender.com" // Replace with your backend URL

    static func login(email: String, password: String) async throws -> AuthResponse {
        guard let url = URL(string: "\(baseURL)/auth/signin") else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["email": email, "password": password]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: request)
        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
        return authResponse
    }
    
    static func signup(email: String, password: String) async throws -> AuthResponse {
        guard let url = URL(string: "\(baseURL)/auth/signup") else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["email": email, "password": password]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: request)
        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
        return authResponse
    }
    
    static func signout(token: String) async throws {
        guard let url = URL(string: "\(baseURL)/auth/signout") else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        _ = try await URLSession.shared.data(for: request)
    }
    
    static func fetchTransactions(token: String) async throws -> [Transaction] {
        guard let url = URL(string: "\(baseURL)/transactions") else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.data(for: request)
        let decoder = JSONDecoder()
        // Using ISO8601 date decoding (with fallback handled in Transaction)
        decoder.dateDecodingStrategy = .iso8601
        let transactions = try decoder.decode([Transaction].self, from: data)
        return transactions
    }
    
    static func addTransaction(transaction: Transaction, token: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/transactions") else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(transaction)
        request.httpBody = data
        let (responseData, _) = try await URLSession.shared.data(for: request)
        let result = try JSONDecoder().decode([String: String].self, from: responseData)
        guard let transactionID = result["transaction_id"] else {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        return transactionID
    }
    
    // New: Update a transaction
    static func updateTransaction(transaction: Transaction, token: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/transactions/\(transaction.id)") else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(transaction)
        request.httpBody = data
        let (responseData, _) = try await URLSession.shared.data(for: request)
        let result = try JSONDecoder().decode([String: String].self, from: responseData)
        guard let message = result["message"] else {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid update response"])
        }
        return message
    }
    
    // New: Delete a transaction
    static func deleteTransaction(transactionID: String, token: String) async throws {
        guard let url = URL(string: "\(baseURL)/transactions/\(transactionID)") else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        _ = try await URLSession.shared.data(for: request)
    }
}

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
    var id: String
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
    
    enum CodingKeys: String, CodingKey {
        case id, title, amount, date, category
        case isExpense = "is_expense"
    }
    
    // Explicit initializer for creating new transactions.
    init(id: String = UUID().uuidString, title: String, amount: Double, date: Date, category: Category, isExpense: Bool) {
        self.id = id
        self.title = title
        self.amount = amount
        self.date = date
        self.category = category
        self.isExpense = isExpense
    }
    
    // Custom decoding: handles numbers as Double or String and flexibly parses dates.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        if let doubleAmount = try? container.decode(Double.self, forKey: .amount) {
            amount = doubleAmount
        } else {
            let stringAmount = try container.decode(String.self, forKey: .amount)
            guard let convertedAmount = Double(stringAmount) else {
                throw DecodingError.dataCorruptedError(forKey: .amount, in: container, debugDescription: "Amount cannot be converted to Double")
            }
            amount = convertedAmount
        }
        let rawDateString = try container.decode(String.self, forKey: .date)
        guard let parsedDate = Transaction.parseDate(from: rawDateString) else {
            throw DecodingError.dataCorruptedError(forKey: .date, in: container, debugDescription: "Expected date string to be ISO8601-formatted or compatible.")
        }
        date = parsedDate
        category = try container.decode(Category.self, forKey: .category)
        isExpense = try container.decode(Bool.self, forKey: .isExpense)
    }
    
    // Custom encoding.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(amount, forKey: .amount)
        try container.encode(date, forKey: .date)
        try container.encode(category, forKey: .category)
        try container.encode(isExpense, forKey: .isExpense)
    }
    
    // Helper method for robust date parsing.
    private static func parseDate(from string: String) -> Date? {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: string) { return date }
        
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: string) { return date }
        
        let fallbackFormats = [
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd"
        ]
        for format in fallbackFormats {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            if let date = formatter.date(from: string) { return date }
        }
        return nil
    }
}

struct AuthResponse: Codable {
    let uid: String
    let email: String
    let token: String
}

struct User {
    let uid: String
    let email: String
}

// MARK: - View Models

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
    @Published var isLoadingTransactions: Bool = false  // New flag
    
    // Compute the current balance.
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
    
    // New: Update a transaction.
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
    
    // New: Delete a transaction.
    func deleteTransaction(_ transaction: Transaction, token: String) async {
        do {
            try await APIService.deleteTransaction(transactionID: transaction.id, token: token)
            self.transactions.removeAll { $0.id == transaction.id }
        } catch {
            print("Error deleting transaction: \(error)")
        }
    }
}

// MARK: - Views

/// The root view switches between AuthenticationView and MainTabView.
/// The onChange now uses a two-parameter closure and clears the transactions array to prevent lingering data.
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
        .onChange(of: authVM.token) { old, new in
            financeManager.transactions = [] // Clear previous data
            if let token = new {
                Task { await financeManager.fetchTransactions(token: token) }
            }
        }
    }
}

/// A view for signing in or signing up.
struct AuthenticationView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isSignUp: Bool = false
    @State private var isLoading: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(isSignUp ? "Sign Up" : "Sign In")
                    .font(.largeTitle)
                    .bold()
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                if let errorMessage = authVM.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
                Button(action: {
                    Task {
                        isLoading = true
                        if isSignUp {
                            await authVM.signup(email: email, password: password)
                        } else {
                            await authVM.login(email: email, password: password)
                        }
                        isLoading = false
                    }
                }) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text(isSignUp ? "Sign Up" : "Sign In")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                Button(action: { isSignUp.toggle() }) {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding()
        }
    }
}

/// The main tab view after signing in.
struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "house.fill") }
            TransactionsView()
                .tabItem { Label("Transactions", systemImage: "list.bullet") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}

/// The dashboard view shows the current balance and recent transactions.
struct DashboardView: View {
    @EnvironmentObject var financeManager: FinanceManager
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showingAddTransactionSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Balance card.
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
                    
                    // Quick action buttons.
                    HStack {
                        Button(action: { showingAddTransactionSheet = true }) {
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
                        Button(action: { showingAddTransactionSheet = true }) {
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
                    
                    // Recent transactions.
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
            .sheet(isPresented: $showingAddTransactionSheet) {
                AddTransactionView(isExpense: true)
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

/// A row view for displaying a transaction.
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

/// The transactions view shows the full list with search, filtering, update, and swipe‑to‑delete.
struct TransactionsView: View {
    @EnvironmentObject var financeManager: FinanceManager
    @EnvironmentObject var authVM: AuthViewModel
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
            return filtered.filter { $0.title.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar.
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
                
                // Filter chips.
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
                    Button(action: { showingAddTransactionSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTransactionSheet) {
                AddTransactionView(isExpense: true)
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

/// A simple chip view for filtering.
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

/// A view for adding a new transaction.
struct AddTransactionView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authVM: AuthViewModel
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

/// A new view for updating an existing transaction.
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

/// The settings view includes a sign-out button.
struct SettingsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var financeManager: FinanceManager
    @State private var showingCategoryAnalysis = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Button("Category Analysis") { showingCategoryAnalysis = true }
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

/// A view showing category spending analysis.
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

/// A view showing a progress bar for a given category.
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

// MARK: - App Entry Point

@main
struct SimpleBudgetApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
