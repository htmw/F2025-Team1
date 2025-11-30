//
//  FraudDetection.swift
//  CreditCardFraudApp
//
//  Created by Xavier Jackson on 11/30/25.
//

import Foundation

struct FraudDetectionModel: Identifiable, Codable {
    let id: UUID
    
    // Core features for detection
    let transactionTime: Date
    let amount: Double
    let creditCardNumber: String
    
    // Optional: link back to transaction
    let transactionId: UUID?
}
