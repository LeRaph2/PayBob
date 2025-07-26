//
//  AddBalanceView.swift
//  PayBob
//
//  Created by Raphael Hanna on 7/25/25.
//

import SwiftUI
import SwiftData

struct AddBalanceView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var amount: String = ""
    @State private var desc: String = ""
    @State private var otherPersonName: String = ""
    @State private var otherPersonContact: String = ""
    @State private var isOwedToMe: Bool = true
    @State private var selectedTags: Set<String> = []
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var notes: String = ""
    @State private var showingSuccessAlert = false
    
    private let availableTags = BalanceTag.allCases
    
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
                    // Amount Input
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.headline)
                    }
                    
                    // Description
                    TextField("Description", text: $desc)
                    
                    // Type Picker
                    Picker("Type", selection: $isOwedToMe) {
                        Text("Someone owes me").tag(true)
                        Text("I owe someone").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
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
            .navigationTitle("Add Balance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveBalance()
                    }
                    .disabled(!isFormValid)
                    .fontWeight(.semibold)
                }
            }
        }
        .alert("Balance Added!", isPresented: $showingSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your balance has been successfully added.")
        }
    }
    
    private func saveBalance() {
        guard let amountValue = Double(amount), amountValue > 0 else { return }
        
        let newBalance = Balance(
            amount: amountValue,
            description: desc,
            isOwedToMe: isOwedToMe,
            otherPersonName: otherPersonName,
            otherPersonContact: otherPersonContact.isEmpty ? nil : otherPersonContact,
            dueDate: hasDueDate ? dueDate : nil,
            tags: Array(selectedTags),
            notes: notes.isEmpty ? nil : notes
        )
        
        modelContext.insert(newBalance)
        
        do {
            try modelContext.save()
            showingSuccessAlert = true
        } catch {
            print("Error saving balance: \(error)")
        }
    }
}

struct TagButton: View {
    let tag: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(tag)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : color.opacity(0.2))
                .foregroundColor(isSelected ? .white : color)
                .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Update the placeholder AddBalanceView in ContentView.swift to show the real one
struct AddBalanceTabView: View {
    @State private var showingAddBalance = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                VStack(spacing: 16) {
                    Text("Add New Balance")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Track what you owe others or what others owe you")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Button(action: {
                    showingAddBalance = true
                }) {
                    Text("Add Balance")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
            }
            .navigationTitle("Add")
        }
        .sheet(isPresented: $showingAddBalance) {
            AddBalanceView()
        }
    }
}

#Preview {
    AddBalanceView()
        .modelContainer(for: [Balance.self], inMemory: true)
} 