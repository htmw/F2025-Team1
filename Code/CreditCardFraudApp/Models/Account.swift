//
//  Account.swift
//  CreditCardFraudApp
//
//  Created by Xavier Jackson on 11/30/25.
//

import Foundation

struct AccountModel: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let name: String
    let balance: Double
    let limit: Double
    let createdAt: String
    
    var usedPercentage: Double {
        return balance / limit
    }

// Optional: include recent transactions and linked cards
// let recentTransactions: [Transaction]
// let creditCards: [CreditCard]
}
