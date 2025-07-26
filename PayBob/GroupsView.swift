//
//  GroupsView.swift
//  PayBob
//
//  Created by Raphael Hanna on 7/25/25.
//

import SwiftUI
import SwiftData

struct GroupsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var groups: [Group]
    @State private var showingCreateGroup = false
    
    var activeGroups: [Group] {
        groups.filter { $0.isActive }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if activeGroups.isEmpty {
                    EmptyGroupsView(showingCreateGroup: $showingCreateGroup)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(activeGroups, id: \.id) { group in
                                NavigationLink(destination: GroupDetailView(group: group)) {
                                    GroupRowView(group: group)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Groups")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreateGroup = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateGroup) {
                CreateGroupView()
            }
            .onAppear {
                createSampleGroupsIfNeeded()
            }
        }
    }
    
    private func createSampleGroupsIfNeeded() {
        if groups.isEmpty {
            let sampleGroups = [
                Group(name: "NYC Trip 2025", description: "Weekend getaway with college friends"),
                Group(name: "Roommate Expenses", description: "Shared apartment costs")
            ]
            
            for group in sampleGroups {
                modelContext.insert(group)
            }
            
            try? modelContext.save()
        }
    }
}

struct EmptyGroupsView: View {
    @Binding var showingCreateGroup: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 16) {
                Text("No Groups Yet")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Create a group to split expenses with friends, family, or colleagues")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button(action: {
                showingCreateGroup = true
            }) {
                Text("Create Group")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
    }
}

struct GroupRowView: View {
    let group: Group
    
    var memberCount: Int {
        group.members.count
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if let desc = group.desc {
                        Text(desc)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(group.totalExpenses, specifier: "%.2f")")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    
                    Text("\(memberCount) member\(memberCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Created \(formatDate(group.createdAt))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

struct CreateGroupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var groupName: String = ""
    @State private var groupDescription: String = ""
    @State private var showingSuccessAlert = false
    
    var isFormValid: Bool {
        !groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Group Information")) {
                    TextField("Group name", text: $groupName)
                    TextField("Description (optional)", text: $groupDescription, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(footer: Text("You can add members and expenses after creating the group.")) {
                    EmptyView()
                }
            }
            .navigationTitle("Create Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createGroup()
                    }
                    .disabled(!isFormValid)
                    .fontWeight(.semibold)
                }
            }
        }
        .alert("Group Created!", isPresented: $showingSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your group has been successfully created.")
        }
    }
    
    private func createGroup() {
        let newGroup = Group(
            name: groupName.trimmingCharacters(in: .whitespacesAndNewlines),
            description: groupDescription.isEmpty ? nil : groupDescription
        )
        
        modelContext.insert(newGroup)
        
        do {
            try modelContext.save()
            showingSuccessAlert = true
        } catch {
            print("Error creating group: \(error)")
        }
    }
}

struct GroupDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var group: Group
    @State private var showingAddExpense = false
    @State private var showingAddMember = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Group Header
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(group.name)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            if let desc = group.desc {
                                Text(desc)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("$\(group.totalExpenses, specifier: "%.2f")")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            
                            Text("Total Expenses")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        Button(action: {
                            showingAddExpense = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Expense")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            showingAddMember = true
                        }) {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                Text("Add Member")
                            }
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Members Section
                if !group.members.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Members")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Text("\(group.members.count) member\(group.members.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        
                        LazyVStack(spacing: 8) {
                            ForEach(group.members, id: \.id) { member in
                                MemberRowView(member: member)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Expenses Section
                if !group.expenses.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Expenses")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Text("\(group.expenses.count) expense\(group.expenses.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        
                        LazyVStack(spacing: 8) {
                            ForEach(group.expenses, id: \.id) { expense in
                                ExpenseRowView(expense: expense)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer(minLength: 50)
            }
        }
        .navigationTitle("Group Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView(group: group)
        }
        .sheet(isPresented: $showingAddMember) {
            AddMemberView(group: group)
        }
    }
}

struct MemberRowView: View {
    let member: GroupMember
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(member.user?.name.prefix(1) ?? "?"))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(member.user?.name ?? "Unknown")
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(member.role.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if member.role == "admin" {
                Image(systemName: "crown.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

struct ExpenseRowView: View {
    let expense: GroupExpense
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("$\(expense.amount, specifier: "%.2f")")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if let category = expense.category {
                    Text(category)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(expense.desc)
                    .font(.body)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.trailing)
                
                Text("Paid by \(expense.paidBy)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

// Placeholder views for add functionality
struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    let group: Group
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Add Expense functionality coming soon!")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AddMemberView: View {
    @Environment(\.dismiss) private var dismiss
    let group: Group
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Add Member functionality coming soon!")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .navigationTitle("Add Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    GroupsView()
        .modelContainer(for: [Group.self, GroupMember.self, GroupExpense.self], inMemory: true)
} 