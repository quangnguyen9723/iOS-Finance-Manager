//
//  Models.swift
//  iOS-Finance-Manager
//
//  Created by Quang Nguyen, Aiden Le, Anh Phan on 4/14/25.
//

import Foundation
import SwiftUI

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
    
    init(id: String = UUID().uuidString, title: String, amount: Double, date: Date, category: Category, isExpense: Bool) {
        self.id = id
        self.title = title
        self.amount = amount
        self.date = date
        self.category = category
        self.isExpense = isExpense
    }
    
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
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(amount, forKey: .amount)
        try container.encode(date, forKey: .date)
        try container.encode(category, forKey: .category)
        try container.encode(isExpense, forKey: .isExpense)
    }
    
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

struct TransactionSummary: Codable {
    let totalExpenses: Double
    let totalIncome: Double
    
    enum CodingKeys: String, CodingKey {
        case totalExpenses = "total_expenses"
        case totalIncome = "total_income"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let expensesString = try container.decode(String.self, forKey: .totalExpenses)
        let incomeString = try container.decode(String.self, forKey: .totalIncome)
        guard let expenses = Double(expensesString),
              let income = Double(incomeString) else {
            throw DecodingError.dataCorruptedError(forKey: .totalExpenses, in: container, debugDescription: "Invalid summary values")
        }
        totalExpenses = expenses
        totalIncome = income
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("\(totalExpenses)", forKey: .totalExpenses)
        try container.encode("\(totalIncome)", forKey: .totalIncome)
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
