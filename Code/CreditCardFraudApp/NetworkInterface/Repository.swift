//
//  Repository.swift
//  CreditCardFraudApp
//
//  Created by Tyler Helmrich on 11/16/25.
//

import Foundation

class Repository {
    private let networkInterface: NetworkInterface
    
    init(networkInterface: NetworkInterface) {
        self.networkInterface = networkInterface
    }
    
    /// Get User Information
    /// - Parameter completion: Completion handler with result containing User presentation model
    func getUserInformation(completion: @escaping (Result<User, Error>) -> Void) {
        networkInterface.getUserInformation { result in
            switch result {
            case .success(let userInfoResponse):
                // Convert network model (NetworkUser) to presentation model (User)
                let user = User(
                    id: userInfoResponse.user.id,
                    name: userInfoResponse.user.name,
                    creditCards: userInfoResponse.user.creditCards.map { networkCard in
                        CreditCard(
                            ccNumber: networkCard.ccNumber,
                            exp: networkCard.exp,
                            iss: networkCard.iss,
                            created_at: networkCard.created_at,
                            balance: 0.0
                            
                        )
                    }
                )
                completion(.success(user))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Get User Transactions
    /// - Parameter completion: Completion handler with result containing array of Transaction presentation models
    func getUserTransactions(completion: @escaping (Result<[Transaction], Error>) -> Void) {
        networkInterface.getUserTransactions { result in
            switch result {
            case .success(let transactionsResponse):
                // Convert network models to presentation models
                let transactions = transactionsResponse.transactions.map { transactionDetail in
                    Transaction(
                        id: UUID(uuidString: transactionDetail.txn_id) ?? UUID(),
                        creditCardNumber: transactionDetail.ccNumber,
                        location: transactionDetail.locationName,
                        city: transactionDetail.city,
                        state: transactionDetail.state,
                        date: transactionDetail.date,
                        time: transactionDetail.time,
                        amount: transactionDetail.amount,
                        longitude: transactionDetail.longitude,
                        latitude: transactionDetail.latitude,
                        userId: transactionDetail.userId,
                        isFraudulent: transactionDetail.fraud_flag
                    )
                }
                completion(.success(transactions))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Add Credit Card
    /// - Parameters:
    ///   - ccNumber: Credit card number
    ///   - exp: Expiration date (MM/YY format)
    ///   - sec: Security code
    ///   - iss: Issuer (e.g., "Visa", "Mastercard")
    ///   - completion: Completion handler with result
    func addCreditCard(ccNumber: String, exp: String, sec: String, iss: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let request = CreateCreditCardRequest(
            userId: "", // Will be set by NetworkInterface
            ccNumber: ccNumber,
            exp: exp,
            sec: sec,
            iss: iss
        )
        
        networkInterface.createCreditCard(request) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func updateTransactionFraudStatus(_ transaction: Transaction, isFraudulent: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        let updateTransactionRequest = UpdateTransactionFraudStatusRequest(transactionId: transaction.id, fraud_flag: isFraudulent, fraud_reason: nil)
        
        networkInterface.updateTransactionFraudStatus(updateTransactionRequest) { result in
            if case let Result.failure(error) = result {
                completion(.failure(error))
                return
            } else {
                completion(.success(()))
            }
        }
    }
}

