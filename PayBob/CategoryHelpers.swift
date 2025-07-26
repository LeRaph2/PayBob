//
//  CategoryHelpers.swift
//  PayBob
//
//  Created by Raphael Hanna on 7/25/25.
//

import SwiftUI

struct CategoryManager {
    static let popularCategories = [
        "Food",
        "Drinks", 
        "Transportation",
        "Entertainment",
        "Travel",
        "Shopping",
        "Birthday",
        "Wedding",
        "Utilities",
        "Rent"
    ]
    
    static func getAllCategories(from balances: [Balance]) -> [String] {
        let userCategories = Set(balances.flatMap { $0.tags })
        let allCategories = Set(popularCategories + Array(userCategories))
        return Array(allCategories).sorted()
    }
}

struct CategoryPill: View {
    let category: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color.blue : Color(.secondarySystemBackground))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CategoryFilterView: View {
    let categories: [String]
    @Binding var selectedCategories: Set<String>
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(categories, id: \.self) { category in
                        CategoryPill(
                            category: category,
                            isSelected: selectedCategories.contains(category)
                        ) {
                            if selectedCategories.contains(category) {
                                selectedCategories.remove(category)
                            } else {
                                selectedCategories.insert(category)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Filter by Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        selectedCategories.removeAll()
                    }
                    .disabled(selectedCategories.isEmpty)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CategorySelectionView: View {
    @Binding var selectedTags: Set<String>
    @State private var customCategory = ""
    @State private var showingCustomInput = false
    
    let allCategories = CategoryManager.popularCategories
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Categories")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(allCategories, id: \.self) { category in
                    CategoryPill(
                        category: category,
                        isSelected: selectedTags.contains(category)
                    ) {
                        if selectedTags.contains(category) {
                            selectedTags.remove(category)
                        } else {
                            selectedTags.insert(category)
                        }
                    }
                }
                
                // Add custom category button
                Button(action: { showingCustomInput = true }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Custom")
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.blue, lineWidth: 1)
                    )
                    .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Display selected custom tags
            if !selectedTags.subtracting(allCategories).isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Custom Categories")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    FlowLayout {
                        ForEach(Array(selectedTags.subtracting(allCategories)), id: \.self) { tag in
                            CategoryPill(category: tag, isSelected: true) {
                                selectedTags.remove(tag)
                            }
                        }
                    }
                }
            }
        }
        .alert("Add Custom Category", isPresented: $showingCustomInput) {
            TextField("Category name", text: $customCategory)
            Button("Add") {
                if !customCategory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    selectedTags.insert(customCategory.trimmingCharacters(in: .whitespacesAndNewlines))
                    customCategory = ""
                }
            }
            Button("Cancel", role: .cancel) {
                customCategory = ""
            }
        }
    }
}

struct FlowLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 0
        var currentRowWidth: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            if currentRowWidth + subviewSize.width > maxWidth && currentRowWidth > 0 {
                totalHeight += currentRowHeight + 8
                currentRowWidth = subviewSize.width
                currentRowHeight = subviewSize.height
            } else {
                currentRowWidth += subviewSize.width + (currentRowWidth > 0 ? 8 : 0)
                currentRowHeight = max(currentRowHeight, subviewSize.height)
            }
        }
        
        totalHeight += currentRowHeight
        return CGSize(width: maxWidth, height: totalHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentRowX: CGFloat = bounds.minX
        var currentRowY: CGFloat = bounds.minY
        var currentRowHeight: CGFloat = 0
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            if currentRowX + subviewSize.width > bounds.maxX && currentRowX > bounds.minX {
                currentRowY += currentRowHeight + 8
                currentRowX = bounds.minX
                currentRowHeight = 0
            }
            
            subview.place(
                at: CGPoint(x: currentRowX, y: currentRowY),
                proposal: ProposedViewSize(subviewSize)
            )
            
            currentRowX += subviewSize.width + 8
            currentRowHeight = max(currentRowHeight, subviewSize.height)
        }
    }
} 