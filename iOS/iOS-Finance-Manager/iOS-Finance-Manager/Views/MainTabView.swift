//
//  MainTabView.swift
//  iOS-Finance-Manager
//
//  Created by Quang Nguyen, Aiden Le, Anh Phan on 4/14/25.
//

import SwiftUI

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
