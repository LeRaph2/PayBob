//
//  PayBobApp.swift
//  PayBob
//
//  Created by Raphael Hanna on 7/25/25.
//

import SwiftUI
import SwiftData

@main
struct PayBobApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            Balance.self,
            Group.self,
            GroupMember.self,
            GroupExpense.self,
            Transaction.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
