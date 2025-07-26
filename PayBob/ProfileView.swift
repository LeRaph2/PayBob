//
//  ProfileView.swift
//  PayBob
//
//  Created by Raphael Hanna on 7/25/25.
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var balances: [Balance]
    @Query private var groups: [Group]
    
    private var totalOwed: Double {
        balances.filter { !$0.isOwedToMe && !$0.isSettled }.reduce(0) { $0 + $1.amount }
    }
    
    private var totalOwedToUser: Double {
        balances.filter { $0.isOwedToMe && !$0.isSettled }.reduce(0) { $0 + $1.amount }
    }
    
    private var netBalance: Double {
        totalOwedToUser - totalOwed
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text("U")
                                    .font(.title)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            )
                        
                        VStack(spacing: 4) {
                            Text("PayBob User")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("Tracking your finances")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Financial Summary
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Financial Summary")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            SummaryRow(title: "You Owe", amount: totalOwed, color: .red)
                            SummaryRow(title: "Owed to You", amount: totalOwedToUser, color: .green)
                            
                            Divider()
                            
                            SummaryRow(
                                title: "Net Balance", 
                                amount: abs(netBalance), 
                                color: netBalance >= 0 ? .green : .red,
                                prefix: netBalance >= 0 ? "+" : "-"
                            )
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Activity Stats
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Activity")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                            StatCard(title: "Total Balances", value: "\(balances.count)", icon: "list.number")
                            StatCard(title: "Active Groups", value: "\(groups.filter { $0.isActive }.count)", icon: "person.3.fill")
                            StatCard(title: "Settled", value: "\(balances.filter { $0.isSettled }.count)", icon: "checkmark.circle.fill")
                            StatCard(title: "Overdue", value: "\(overdueCount)", icon: "exclamationmark.circle.fill")
                        }
                        .padding(.horizontal)
                    }
                    
                    // Settings Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Settings")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        VStack(spacing: 1) {
                            SettingsRow(title: "Notifications", icon: "bell.fill", action: {})
                            SettingsRow(title: "Export Data", icon: "square.and.arrow.up.fill", action: {})
                            SettingsRow(title: "Privacy Policy", icon: "hand.raised.fill", action: {})
                            SettingsRow(title: "About PayBob", icon: "info.circle.fill", action: {})
                        }
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // App Version
                    VStack(spacing: 8) {
                        Text("PayBob")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Text("Version 1.0.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Made with ❤️ for better financial tracking")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    Spacer(minLength: 50)
                }
            }
            .navigationTitle("Profile")
        }
    }
    
    private var overdueCount: Int {
        balances.filter { !$0.isSettled && $0.dueDate != nil && $0.dueDate! < Date() }.count
    }
}

struct SummaryRow: View {
    let title: String
    let amount: Double
    let color: Color
    var prefix: String = ""
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(prefix)$\(amount, specifier: "%.2f")")
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct SettingsRow: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [Balance.self, Group.self], inMemory: true)
} 