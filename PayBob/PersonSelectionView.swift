//
//  PersonSelectionView.swift
//  PayBob
//
//  Created by Raphael Hanna on 7/25/25.
//

import SwiftUI
import SwiftData

struct PersonSelectionView: View {
    @Binding var selectedPersonName: String
    @Binding var selectedPersonContact: String
    @Environment(\.modelContext) private var modelContext
    @Query private var balances: [Balance]
    @State private var isShowingPersonList = false
    
    var existingPeople: [PersonInfo] {
        let groupedBalances = Dictionary(grouping: balances) { $0.otherPersonName }
        return groupedBalances.map { (name, personBalances) in
            let contact = personBalances.first?.otherPersonContact ?? ""
            return PersonInfo(name: name, contact: contact)
        }.sorted { $0.name < $1.name }
    }
    
    var filteredPeople: [PersonInfo] {
        if selectedPersonName.isEmpty {
            return existingPeople
        } else {
            return existingPeople.filter { 
                $0.name.localizedCaseInsensitiveContains(selectedPersonName) 
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Person")
                .font(.headline)
            
            HStack {
                TextField("Enter person's name", text: $selectedPersonName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: selectedPersonName) { _, newValue in
                        isShowingPersonList = !newValue.isEmpty && !filteredPeople.isEmpty
                    }
                
                Button(action: { isShowingPersonList.toggle() }) {
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            
            if !selectedPersonContact.isEmpty {
                TextField("Contact (optional)", text: $selectedPersonContact)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Show filtered suggestions
            if isShowingPersonList && !filteredPeople.isEmpty {
                VStack(spacing: 1) {
                    ForEach(filteredPeople.prefix(5), id: \.name) { person in
                        Button(action: {
                            selectedPersonName = person.name
                            selectedPersonContact = person.contact
                            isShowingPersonList = false
                        }) {
                            HStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.2))
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Text(String(person.name.prefix(1)).uppercased())
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.blue)
                                    )
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(person.name)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    if !person.contact.isEmpty {
                                        Text(person.contact)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                .shadow(radius: 2)
            }
            
            if !selectedPersonName.isEmpty && !existingPeople.contains(where: { $0.name == selectedPersonName }) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("New Person")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    TextField("Contact (optional)", text: $selectedPersonContact)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
        }
    }
}

struct PersonInfo {
    let name: String
    let contact: String
}

#Preview {
    @Previewable @State var personName = ""
    @Previewable @State var personContact = ""
    
    return PersonSelectionView(
        selectedPersonName: $personName,
        selectedPersonContact: $personContact
    )
    .padding()
    .modelContainer(for: [Balance.self], inMemory: true)
} 