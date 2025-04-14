//
//  Finance_Manager_Widget.swift
//  Finance-Manager-Widget
//
//  Created by Quang Nguyen on 4/14/25.
//
import WidgetKit
import SwiftUI

struct FinanceManagerEntry: TimelineEntry {
    let date: Date
    let currentBalance: Double
    let totalIncome: Double
    let totalExpenses: Double
}

struct FinanceManagerTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> FinanceManagerEntry {
        FinanceManagerEntry(date: Date(), currentBalance: 0.0, totalIncome: 0.0, totalExpenses: 0.0)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (FinanceManagerEntry) -> Void) {
        completion(loadEntry())
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<FinanceManagerEntry>) -> Void) {
        let entry = loadEntry()
        let timeline = Timeline(entries: [entry],
                                policy: .after(Date().addingTimeInterval(15 * 60)))
        completion(timeline)
    }
    
    private func loadEntry() -> FinanceManagerEntry {
        let defaults = UserDefaults(suiteName:"group.finance.manager")
        let balance = defaults?.double(forKey: "currentBalance") ?? 0.0
        let income = defaults?.double(forKey: "totalIncome") ?? 0.0
        let expenses = defaults?.double(forKey: "totalExpenses") ?? 0.0
        return FinanceManagerEntry(date: Date(), currentBalance: balance, totalIncome: income, totalExpenses: expenses)
    }
}

struct FinanceManagerWidgetEntryView : View {
    var entry: FinanceManagerTimelineProvider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Finance Overview")
                .font(.headline)
            Text("Balance: \(entry.currentBalance, format: .currency(code: "USD"))")
                .font(.title2)
                .fontWeight(.bold)
            HStack {
                VStack(alignment: .leading) {
                    Text("Income")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text("\(entry.totalIncome, format: .currency(code: "USD"))")
                        .font(.caption)
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text("Expense")
                        .font(.caption)
                        .foregroundColor(.red)
                    Text("\(entry.totalExpenses, format: .currency(code: "USD"))")
                        .font(.caption)
                }
            }
        }
        .padding()
        .widgetURL(URL(string: "myapp://dashboard"))
    }
}

struct Finance_Manager_Widget: Widget {
    let kind: String = "FinanceManagerWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FinanceManagerTimelineProvider()) { entry in
            FinanceManagerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Finance Overview")
        .description("View your current balance and summary of income & expenses.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct FinanceWidget_Previews: PreviewProvider {
    static var previews: some View {
        FinanceManagerWidgetEntryView(entry: FinanceManagerEntry(date: Date(), currentBalance: 1234.56, totalIncome: 2000, totalExpenses: 765.44))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
