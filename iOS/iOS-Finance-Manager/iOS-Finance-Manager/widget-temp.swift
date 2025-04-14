////
////  widget-temp.swift
////  iOS-Finance-Manager
////
////  Created by Quang Nguyen on 4/13/25.
////
//
//import WidgetKit
//import SwiftUI
//
//// MARK: - Timeline Entry
//
//struct FinanceEntry: TimelineEntry {
//    let date: Date
//    let balance: Double
//    let lastTransactionTitle: String?
//}
//
//// MARK: - Timeline Provider
//
//struct FinanceProvider: TimelineProvider {
//    func placeholder(in context: Context) -> FinanceEntry {
//        FinanceEntry(date: Date(), balance: 1234.56, lastTransactionTitle: "Lunch at Cafe")
//    }
//    
//    func getSnapshot(in context: Context, completion: @escaping (FinanceEntry) -> Void) {
//        let entry = FinanceEntry(date: Date(), balance: 1234.56, lastTransactionTitle: "Lunch at Cafe")
//        completion(entry)
//    }
//    
//    func getTimeline(in context: Context, completion: @escaping (Timeline<FinanceEntry>) -> Void) {
//        // Read shared data from UserDefaults using App Group.
//        // In your main app, write to UserDefaults(suiteName: "group.com.yourcompany.finance")
//        let sharedDefaults = UserDefaults(suiteName: "group.com.yourcompany.finance")
//        let balance = sharedDefaults?.double(forKey: "balance") ?? 0
//        let lastTransaction = sharedDefaults?.string(forKey: "lastTransaction")
//        
//        let entry = FinanceEntry(
//            date: Date(),
//            balance: balance,
//            lastTransactionTitle: lastTransaction
//        )
//        
//        // Refresh after 15 minutes.
//        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(900)))
//        completion(timeline)
//    }
//}
//
//// MARK: - Widget View
//
//struct FinanceWidgetEntryView: View {
//    var entry: FinanceProvider.Entry
//    
//    var body: some View {
//        ZStack {
//            Color(UIColor.systemBackground)
//            VStack(alignment: .leading) {
//                Text("Current Balance")
//                    .font(.headline)
//                    .foregroundColor(.primary)
//                Text("\(entry.balance, specifier: "%.2f")")
//                    .font(.title)
//                    .fontWeight(.bold)
//                    .foregroundColor(entry.balance >= 0 ? .green : .red)
//                if let lastTx = entry.lastTransactionTitle, !lastTx.isEmpty {
//                    Text("Last: \(lastTx)")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                        .padding(.top, 4)
//                } else {
//                    Text("No recent transaction")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                        .padding(.top, 4)
//                }
//                Spacer()
//            }
//            .padding()
//        }
//    }
//}
//
//// MARK: - Widget Configuration
//
//@main
//struct FinanceWidget: Widget {
//    let kind: String = "FinanceWidget"
//    
//    var body: some WidgetConfiguration {
//        StaticConfiguration(kind: kind, provider: FinanceProvider()) { entry in
//            FinanceWidgetEntryView(entry: entry)
//        }
//        .configurationDisplayName("Finance Manager")
//        .description("View your account balance and recent transaction.")
//        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
//    }
//}
