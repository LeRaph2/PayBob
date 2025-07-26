//
//  BalanceDetailView.swift
//  PayBob
//
//  Created by Raphael Hanna on 7/25/25.
//

import SwiftUI
import SwiftData

struct BalanceDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var balance: Balance
    
    @State private var showingEditView = false
    @State private var showingPaymentView = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Card
                VStack(spacing: 16) {
                    HStack {
                        Text("$\(balance.amount, specifier: "%.2f")")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(balance.isOwedToMe ? .green : .red)
                        
                        Spacer()
                        
                        Image(systemName: balance.isOwedToMe ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                            .font(.title)
                            .foregroundColor(balance.isOwedToMe ? .green : .red)
                    }
                    
                    VStack(spacing: 8) {
                        Text(balance.desc)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(balance.isOwedToMe ? "from \(balance.otherPersonName)" : "to \(balance.otherPersonName)")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    
                    // Tags
                    if !balance.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(balance.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.2))
                                        .foregroundColor(.blue)
                                        .cornerRadius(16)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Details Section
                VStack(spacing: 16) {
                    DetailRow(title: "Status", value: balance.isSettled ? "Settled" : "Outstanding", valueColor: balance.isSettled ? .green : .orange)
                    
                    if let contact = balance.otherPersonContact {
                        DetailRow(title: "Contact", value: contact)
                    }
                    
                    if let dueDate = balance.dueDate {
                        DetailRow(title: "Due Date", value: formatDateMedium(dueDate), valueColor: dueDate < Date() ? .red : .primary)
                    }
                    
                    DetailRow(title: "Created", value: formatDate(balance.createdAt))
                    
                    if let notes = balance.notes {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text(notes)
                                .font(.body)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                // Action Buttons
                if !balance.isSettled {
                    VStack(spacing: 12) {
                        Button(action: {
                            showingPaymentView = true
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Mark as Settled")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                        }
                        
                        HStack(spacing: 12) {
                            Button(action: {
                                showingEditView = true
                            }) {
                                HStack {
                                    Image(systemName: "pencil")
                                    Text("Edit")
                                }
                                .font(.headline)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                            }
                            
                            Button(action: {
                                showingDeleteAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Delete")
                                }
                                .font(.headline)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer(minLength: 50)
            }
        }
        .navigationTitle("Balance Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditView) {
            EditBalanceView(balance: balance)
        }
        .alert("Settle Balance", isPresented: $showingPaymentView) {
            Button("Cancel", role: .cancel) { }
            Button("Settle") {
                settleBalance()
            }
        } message: {
            Text("Mark this balance as settled? This action cannot be undone.")
        }
        .alert("Delete Balance", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteBalance()
            }
        } message: {
            Text("Are you sure you want to delete this balance? This action cannot be undone.")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDateMedium(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func settleBalance() {
        balance.isSettled = true
        balance.updatedAt = Date()
        
        // Add a settlement transaction
        let settlementTransaction = Transaction(
            amount: balance.amount,
            description: "Balance settled",
            type: "settlement"
        )
        balance.transactions.append(settlementTransaction)
        
        try? modelContext.save()
    }
    
    private func deleteBalance() {
        modelContext.delete(balance)
        try? modelContext.save()
        dismiss()
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
}

struct EditBalanceView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var balance: Balance
    
    @State private var amount: String
    @State private var desc: String
    @State private var otherPersonName: String
    @State private var otherPersonContact: String
    @State private var selectedTags: Set<String>
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    @State private var notes: String
    
    private let availableTags = BalanceTag.allCases
    
    init(balance: Balance) {
        self.balance = balance
        _amount = State(initialValue: String(balance.amount))
        _desc = State(initialValue: balance.desc)
        _otherPersonName = State(initialValue: balance.otherPersonName)
        _otherPersonContact = State(initialValue: balance.otherPersonContact ?? "")
        _selectedTags = State(initialValue: Set(balance.tags))
        _hasDueDate = State(initialValue: balance.dueDate != nil)
        _dueDate = State(initialValue: balance.dueDate ?? Date())
        _notes = State(initialValue: balance.notes ?? "")
    }
    
    var isFormValid: Bool {
        !amount.isEmpty && 
        !desc.isEmpty && 
        !otherPersonName.isEmpty &&
        Double(amount) != nil &&
        Double(amount)! > 0
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Balance Details")) {
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.headline)
                    }
                    
                    TextField("Description", text: $desc)
                }
                
                Section(header: Text("Person")) {
                    TextField("Name", text: $otherPersonName)
                    TextField("Phone or Email (Optional)", text: $otherPersonContact)
                }
                
                Section(header: Text("Tags")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                        ForEach(availableTags, id: \.self) { tag in
                            TagButton(
                                tag: tag.rawValue,
                                isSelected: selectedTags.contains(tag.rawValue),
                                color: Color(tag.color)
                            ) {
                                if selectedTags.contains(tag.rawValue) {
                                    selectedTags.remove(tag.rawValue)
                                } else {
                                    selectedTags.insert(tag.rawValue)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Due Date")) {
                    Toggle("Set due date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Due date", selection: $dueDate, displayedComponents: .date)
                    }
                }
                
                Section(header: Text("Notes (Optional)")) {
                    TextField("Add any additional notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Balance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!isFormValid)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func saveChanges() {
        guard let amountValue = Double(amount), amountValue > 0 else { return }
        
        balance.amount = amountValue
        balance.desc = desc
        balance.otherPersonName = otherPersonName
        balance.otherPersonContact = otherPersonContact.isEmpty ? nil : otherPersonContact
        balance.tags = Array(selectedTags)
        balance.dueDate = hasDueDate ? dueDate : nil
        balance.notes = notes.isEmpty ? nil : notes
        balance.updatedAt = Date()
        
        dismiss()
    }
}

#Preview {
    let balance = Balance(
        amount: 50.0,
        description: "Birthday gift",
        isOwedToMe: true,
        otherPersonName: "Sarah",
        tags: ["Birthday", "Gift"]
    )
    
    NavigationView {
        BalanceDetailView(balance: balance)
    }
    .modelContainer(for: [Balance.self], inMemory: true)
} 