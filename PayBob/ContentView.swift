 //
//  ContentView.swift
//  PayBob
//
//  Created by Raphael Hanna on 7/25/25.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var balances: [Balance]
    
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Dashboard")
                }
            
            PeopleView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("People")
                }
            
            AddBalanceTabView()
                .tabItem {
                    Image(systemName: "plus")
                        .environment(\.symbolVariants, .circle.fill)
                        .font(.title2)
                    Text("Add")
                }
                .accentColor(.blue)
            
            GroupsView()
                .tabItem {
                    Image(systemName: "person.3.fill")
                    Text("Groups")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("Profile")
                }
        }
        .accentColor(.blue)
        .onAppear {
            createSampleDataIfNeeded()
        }
    }
    
    private func createSampleDataIfNeeded() {
        if balances.isEmpty {
            // Create some sample data
            let sampleBalances = [
                Balance(amount: 25.0, description: "Coffee at Starbucks", isOwedToMe: false, otherPersonName: "Alex", tags: ["Food"]),
                Balance(amount: 50.0, description: "Birthday gift", isOwedToMe: true, otherPersonName: "Sarah", tags: ["Birthday", "Gift"]),
                Balance(amount: 120.0, description: "Dinner split", isOwedToMe: true, otherPersonName: "Mike", tags: ["Food", "Dinner"]),
                Balance(amount: 15.0, description: "Uber ride", isOwedToMe: false, otherPersonName: "Emma", tags: ["Transportation"]),
                Balance(amount: 200.0, description: "Wedding gift", isOwedToMe: true, otherPersonName: "John", tags: ["Wedding", "Gift"]),
                Balance(amount: 35.0, description: "Drinks night out", isOwedToMe: false, otherPersonName: "Lisa", tags: ["Drinks", "Entertainment"])
            ]
            
            for balance in sampleBalances {
                modelContext.insert(balance)
            }
            
            try? modelContext.save()
        }
    }
}

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var balances: [Balance]
    @State private var selectedCategories: Set<String> = []
    @State private var showingCategoryFilter = false
    
    var availableCategories: [String] {
        let allCategories = Set(balances.flatMap { $0.tags })
        return Array(allCategories).sorted()
    }
    
    var filteredBalances: [Balance] {
        if selectedCategories.isEmpty {
            return balances
        } else {
            return balances.filter { balance in
                !Set(balance.tags).isDisjoint(with: selectedCategories)
            }
        }
    }
    @State private var showingAddBalance = false
    
    private var iOweBalances: [Balance] {
        filteredBalances.filter { !$0.isOwedToMe && !$0.isSettled }
    }
    
    private var owedToMeBalances: [Balance] {
        filteredBalances.filter { $0.isOwedToMe && !$0.isSettled }
    }
    
    private var totalIOwe: Double {
        iOweBalances.reduce(0) { $0 + $1.amount }
    }
    
    private     var totalOwedToMe: Double {
        owedToMeBalances.reduce(0) { $0 + $1.amount }
    }
    
    var netBalance: Double {
        totalOwedToMe - totalIOwe
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Net Balance Header - Prominent Display
                    VStack(spacing: 16) {
                        Text("Net Balance")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text(netBalance >= 0 ? "+" : "")
                            Text("$\(abs(netBalance), specifier: "%.2f")")
                        }
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(netBalance >= 0 ? .green : .red)
                        
                        Text(netBalance >= 0 ? "You're owed more" : "You owe more")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(netBalance >= 0 ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                            .stroke(netBalance >= 0 ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    
                    // Breakdown Summary
                    HStack(spacing: 20) {
                        SummaryCard(
                            title: "I Owe",
                            amount: totalIOwe,
                            color: .red,
                            icon: "arrow.up.circle.fill"
                        )
                        
                        SummaryCard(
                            title: "Owed to Me",
                            amount: totalOwedToMe,
                            color: .green,
                            icon: "arrow.down.circle.fill"
                        )
                    }
                    .padding(.horizontal)
                    
                    // Category Filter Section
                    if !availableCategories.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Categories")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Button(selectedCategories.isEmpty ? "Filter" : "Clear (\(selectedCategories.count))") {
                                    if selectedCategories.isEmpty {
                                        showingCategoryFilter.toggle()
                                    } else {
                                        selectedCategories.removeAll()
                                    }
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                            .padding(.horizontal)
                            
                            if !selectedCategories.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(Array(selectedCategories), id: \.self) { category in
                                            CategoryPill(category: category, isSelected: true) {
                                                selectedCategories.remove(category)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    
                    // Recent Balances Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text(selectedCategories.isEmpty ? "Recent Balances" : "Filtered Balances")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        if filteredBalances.filter({ !$0.isSettled }).isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.green.opacity(0.6))
                                
                                Text(selectedCategories.isEmpty ? "No active balances! 🎉" : "No balances for selected categories")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(40)
                            .background(Color.green.opacity(0.05))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        } else {
                            LazyVStack(spacing: 8) {
                                ForEach(filteredBalances.filter({ !$0.isSettled }).prefix(10), id: \.id) { balance in
                                    NavigationLink(destination: BalanceDetailView(balance: balance)) {
                                        BalanceRowView(balance: balance)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
            }
            .navigationTitle("Dashboard")
            .sheet(isPresented: $showingCategoryFilter) {
                CategoryFilterView(
                    categories: availableCategories,
                    selectedCategories: $selectedCategories
                )
            }
        }
    }
    

}

struct SummaryCard: View {
    let title: String
    let amount: Double
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            Text("$\(amount, specifier: "%.2f")")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct BalanceSection: View {
    let title: String
    let balances: [Balance]
    let emptyMessage: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !balances.isEmpty {
                    Text("\(balances.count) items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            if balances.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(color.opacity(0.6))
                    
                    Text(emptyMessage)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
                .background(color.opacity(0.05))
                .cornerRadius(12)
                .padding(.horizontal)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(filteredBalances.prefix(10), id: \.id) { balance in
                        NavigationLink(destination: BalanceDetailView(balance: balance)) {
                            BalanceRowView(balance: balance)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct BalanceRowView: View {
    let balance: Balance
    
    var body: some View {
        HStack(spacing: 12) {
            // Amount
            VStack(alignment: .leading, spacing: 2) {
                Text("$\(balance.amount, specifier: "%.2f")")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(balance.isOwedToMe ? .green : .red)
                
                if !balance.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(balance.tags.prefix(2), id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                        if balance.tags.count > 2 {
                            Text("+\(balance.tags.count - 2)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Description and Person
            VStack(alignment: .trailing, spacing: 2) {
                Text(balance.desc)
                    .font(.body)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.trailing)
                
                Text(balance.isOwedToMe ? "from \(balance.otherPersonName)" : "to \(balance.otherPersonName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// Placeholder views for other tabs






struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .modelContainer(for: [User.self, Balance.self, Group.self, GroupMember.self, GroupExpense.self, Transaction.self], inMemory: true)
    }
}
                                
