//
//  Transaction.swift
//  CreditCardFraudApp
//
//  Created by Tyler Helmrich on 11/16/25.
//

import Foundation


struct Transaction {
    let id: UUID
    let amount: Int
    let longitude: Double
    let latitude: Double
    let location: String
    let city: String
    let state: String
    let date: String
    let time: String
    let ccNumber: String
    let userId: String
    var isFraudulent: Bool
    
    init(id: UUID = UUID(), creditCardNumber: String, location: String, city: String, state: String, date: String, time: String, amount: Int = Int.random(in: 1...100000), longitude: Double = Double.random(in: -180...180), latitude: Double = Double.random(in: -90...90), userId: String = "67c31a0d-7658-458b-9196-b3133b26cd00", isFraudulent: Bool = false) {
        self.id = id
        self.amount = amount
        self.longitude = longitude
        self.latitude = latitude
        self.ccNumber = creditCardNumber
        self.userId = userId
        self.location = location
        self.city = city
        self.state = state
        self.date = date
        self.time = time
        self.isFraudulent = isFraudulent
    }
}

