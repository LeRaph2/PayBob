//
//  Models.swift
//  PayBob
//
//  Created by Raphael Hanna on 7/25/25.
//

import Foundation
import SwiftData

// MARK: - User Model
@Model
final class User {
    var id: String
    var name: String
    var email: String?
    var phoneNumber: String?
    var avatarData: Data?
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade) var balances: [Balance] = []
    @Relationship(deleteRule: .cascade) var groupMemberships: [GroupMember] = []
    
    init(name: String, email: String? = nil, phoneNumber: String? = nil) {
        self.id = UUID().uuidString
        self.name = name
        self.email = email
        self.phoneNumber = phoneNumber
        self.createdAt = Date()
    }
}

// MARK: - Balance Model
@Model
final class Balance {
    var id: String
    var amount: Double
    var desc: String
    var isOwedToMe: Bool // true if someone owes me, false if I owe someone
    var otherPersonName: String
    var otherPersonContact: String?
    var dueDate: Date?
    var tags: [String] = []
    var createdAt: Date
    var updatedAt: Date
    var isSettled: Bool = false
    var notes: String?
    
    @Relationship(deleteRule: .cascade) var transactions: [Transaction] = []
    @Relationship(inverse: \User.balances) var user: User?
    var group: Group?
    
    init(amount: Double, description: String, isOwedToMe: Bool, otherPersonName: String, otherPersonContact: String? = nil, dueDate: Date? = nil, tags: [String] = [], notes: String? = nil) {
        self.id = UUID().uuidString
        self.amount = amount
        self.desc = description
        self.isOwedToMe = isOwedToMe
        self.otherPersonName = otherPersonName
        self.otherPersonContact = otherPersonContact
        self.dueDate = dueDate
        self.tags = tags
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Group Model
@Model
final class Group {
    var id: String
    var name: String
    var desc: String?
    var createdAt: Date
    var isActive: Bool = true
    var totalExpenses: Double = 0.0
    
    @Relationship(deleteRule: .cascade) var members: [GroupMember] = []
    @Relationship(deleteRule: .cascade) var expenses: [GroupExpense] = []
    
    init(name: String, description: String? = nil) {
        self.id = UUID().uuidString
        self.name = name
        self.desc = description
        self.createdAt = Date()
    }
}

// MARK: - Group Member Model
@Model
final class GroupMember {
    var id: String
    var role: String = "member" // "admin", "member"
    var joinedAt: Date
    
    @Relationship(inverse: \User.groupMemberships) var user: User?
    @Relationship(inverse: \Group.members) var group: Group?
    
    init(user: User, group: Group, role: String = "member") {
        self.id = UUID().uuidString
        self.role = role
        self.joinedAt = Date()
        self.user = user
        self.group = group
    }
}

// MARK: - Group Expense Model
@Model
final class GroupExpense {
    var id: String
    var amount: Double
    var desc: String
    var paidBy: String // User ID who paid
    var splitType: String = "equal" // "equal", "percentage", "custom"
    var splitData: Data? // JSON data for custom splits
    var category: String?
    var createdAt: Date
    var receipt: Data? // Image data for receipt
    
    @Relationship(inverse: \Group.expenses) var group: Group?
    
    init(amount: Double, description: String, paidBy: String, splitType: String = "equal", category: String? = nil) {
        self.id = UUID().uuidString
        self.amount = amount
        self.desc = description
        self.paidBy = paidBy
        self.splitType = splitType
        self.category = category
        self.createdAt = Date()
    }
}

// MARK: - Transaction Model
@Model
final class Transaction {
    var id: String
    var amount: Double
    var desc: String
    var type: String // "payment", "adjustment", "interest"
    var createdAt: Date
    
    @Relationship(inverse: \Balance.transactions) var balance: Balance?
    
    init(amount: Double, description: String, type: String = "payment") {
        self.id = UUID().uuidString
        self.amount = amount
        self.desc = description
        self.type = type
        self.createdAt = Date()
    }
}

// MARK: - Helper Enums
enum BalanceTag: String, CaseIterable {
    case birthday = "Birthday"
    case trip = "Trip"
    case gift = "Gift"
    case dinner = "Dinner"
    case groceries = "Groceries"
    case utilities = "Utilities"
    case rent = "Rent"
    case entertainment = "Entertainment"
    case transportation = "Transportation"
    case other = "Other"
    
    var color: String {
        switch self {
        case .birthday: return "pink"
        case .trip: return "blue"
        case .gift: return "purple"
        case .dinner: return "orange"
        case .groceries: return "green"
        case .utilities: return "yellow"
        case .rent: return "red"
        case .entertainment: return "indigo"
        case .transportation: return "teal"
        case .other: return "gray"
        }
    }
}
