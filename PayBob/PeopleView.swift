//
//  PeopleView.swift
//  PayBob
//
//  Created by Raphael Hanna on 7/25/25.
//

import SwiftUI
import SwiftData

struct PeopleView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var balances: [Balance]
    @State private var searchText = ""
    
    var people: [PersonSummary] {
        let groupedBalances = Dictionary(grouping: balances) { $0.otherPersonName }
        
        return groupedBalances.compactMap { (name, personBalances) in
            let activeBalances = personBalances.filter { !$0.isSettled }
            let owedToMe = activeBalances.filter { $0.isOwedToMe }.reduce(0) { $0 + $1.amount }
            let iOwe = activeBalances.filter { !$0.isOwedToMe }.reduce(0) { $0 + $1.amount }
            let netBalance = owedToMe - iOwe
            
            return PersonSummary(
                name: name,
                owedToMe: owedToMe,
                iOwe: iOwe,
                netBalance: netBalance,
                totalBalances: personBalances.count,
                activeBalances: activeBalances.count,
                lastActivity: personBalances.max(by: { $0.updatedAt < $1.updatedAt })?.updatedAt ?? Date()
            )
        }.sorted { person1, person2 in
            if searchText.isEmpty {
                return abs(person1.netBalance) > abs(person2.netBalance)
            } else {
                return person1.name.localizedCaseInsensitiveContains(searchText) && 
                       !person2.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var filteredPeople: [PersonSummary] {
        if searchText.isEmpty {
            return people
        } else {
            return people.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if filteredPeople.isEmpty {
                    EmptyPeopleView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredPeople, id: \.name) { person in
                                NavigationLink(destination: PersonDetailView(person: person, balances: balancesForPerson(person.name))) {
                                    PersonRowView(person: person)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("People")
            .searchable(text: $searchText, prompt: "Search people...")
        }
    }
    
    private func balancesForPerson(_ name: String) -> [Balance] {
        balances.filter { $0.otherPersonName == name }
    }
}

struct PersonSummary {
    let name: String
    let owedToMe: Double
    let iOwe: Double
    let netBalance: Double
    let totalBalances: Int
    let activeBalances: Int
    let lastActivity: Date
}

struct PersonRowView: View {
    let person: PersonSummary
    
    var body: some View {
        HStack {
            // Person Avatar
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(person.name.prefix(1)).uppercased())
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(person.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 16) {
                    if person.activeBalances > 0 {
                        Text("\(person.activeBalances) active")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Last: \(formatDate(person.lastActivity))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                HStack {
                    Text(person.netBalance >= 0 ? "+" : "")
                    Text("$\(abs(person.netBalance), specifier: "%.2f")")
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(person.netBalance >= 0 ? .green : .red)
                
                Text(person.netBalance >= 0 ? "owes you" : "you owe")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct PersonDetailView: View {
    let person: PersonSummary
    let balances: [Balance]
    @Environment(\.modelContext) private var modelContext
    
    var activeBalances: [Balance] {
        balances.filter { !$0.isSettled }
    }
    
    var settledBalances: [Balance] {
        balances.filter { $0.isSettled }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Person Header
                VStack(spacing: 16) {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text(String(person.name.prefix(1)).uppercased())
                                .font(.largeTitle)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        )
                    
                    Text(person.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    // Net Balance Summary
                    VStack(spacing: 8) {
                        HStack {
                            Text(person.netBalance >= 0 ? "+" : "")
                            Text("$\(abs(person.netBalance), specifier: "%.2f")")
                        }
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(person.netBalance >= 0 ? .green : .red)
                        
                        Text(person.netBalance >= 0 ? "owes you" : "you owe them")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(person.netBalance >= 0 ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    )
                }
                
                // Balance Breakdown
                HStack {
                    VStack {
                        Text("$\(person.owedToMe, specifier: "%.2f")")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("Owes You")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text("$\(person.iOwe, specifier: "%.2f")")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                        Text("You Owe")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Active Balances
                if !activeBalances.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Active Balances")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        LazyVStack(spacing: 8) {
                            ForEach(activeBalances, id: \.id) { balance in
                                NavigationLink(destination: BalanceDetailView(balance: balance)) {
                                    BalanceRowView(balance: balance)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Settled Balances
                if !settledBalances.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("History")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        LazyVStack(spacing: 8) {
                            ForEach(settledBalances.prefix(5), id: \.id) { balance in
                                NavigationLink(destination: BalanceDetailView(balance: balance)) {
                                    BalanceRowView(balance: balance)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer(minLength: 50)
            }
        }
        .navigationTitle(person.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct EmptyPeopleView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("No People Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add your first balance to start tracking people you owe or who owe you.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    PeopleView()
        .modelContainer(for: [Balance.self], inMemory: true)
} 