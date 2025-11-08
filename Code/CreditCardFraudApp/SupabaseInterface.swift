//
//  SupabaseInterface.swift
//  CreditCardFraudApp
//
//  Created by Tyler Helmrich on 11/1/25.
//

import Foundation
import Supabase


class ClientCredentials {
    static let defaultClient = SupabaseClient(supabaseURL: URL(string: "https://vddcuogkozydtepyzuyo.supabase.co")!, supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZkZGN1b2drb3p5ZHRlcHl6dXlvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE4NTkzNDYsImV4cCI6MjA3NzQzNTM0Nn0.6N9_AUogGYJwCSvlSakZQ2gNLrkntf_J8F7y92o6uqI")
}

struct CreditCard {
    let number: String
    let expirationDate: String
    let cvc: String
    let issuer: String
    
    init(number: String = "\(Int.random(in: 10000000...99999999))", expirationDate: String = "12/25", cvc: String = "333", issuer: String = "VISA") {
        self.number = number
        self.expirationDate = expirationDate
        self.cvc = cvc
        self.issuer = issuer
    }
}

struct Transaction: Encodable {
    let amount: Int
    let longitude: Double
    let latitude: Double
    let creditCardNumber: String
    let userId: String
    
    init(creditCardNumber: String, amount: Int = Int.random(in: 1...100000), longitude: Double = Double.random(in: -180...180), latitude: Double = Double.random(in: -90...90)) {
        self.amount = amount
        self.longitude = longitude
        self.latitude = latitude
        self.creditCardNumber = creditCardNumber
        self.userId = User.defaultUser.id.uuidString
    }
    
    enum CodingKeys: String, CodingKey {
        case amount = "amount"
        case longitude = "longitude"
        case latitude = "latitude"
        case creditCardNumber = "ccNumber"
        case userId = "userId"
    }
}

struct User {
    let id: UUID
    
    static let defaultUser = User(id: UUID(uuidString: "67c31a0d-7658-458b-9196-b3133b26cd00")!)
}

class SupabaseInterface {
    
    private weak var client: SupabaseClient!
    init(client: SupabaseClient = ClientCredentials.defaultClient) {
        self.client = client
    }
    
    func insert(creditCard: CreditCard) async throws {
        let result = try await client.from("CreditCards").insert(["ccNumber": creditCard.number, "exp": creditCard.expirationDate, "sec": creditCard.cvc, "iss": creditCard.issuer, "userId": User.defaultUser.id.uuidString]).execute()
        print(result)
    }
    
    func insertTransaction(transaction: Transaction) async throws {
        let result = try await client.from("Transactions").insert(transaction).execute()
        print(result)
    }
    
}
