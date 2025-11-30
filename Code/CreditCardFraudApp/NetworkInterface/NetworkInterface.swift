//
//  NetworkInterface.swift
//  CreditCardFraudApp
//
//  Created by Tyler Helmrich on 11/16/25.
//


import Foundation

public protocol NetworkInterface {
    func fetch<T: Decodable>(_ url: URL, completion: @escaping (Result<T, Error>) -> Void)
    
    /// Get User Information
    /// - Parameters:
    ///   - completion: Completion handler with result containing parsed UserInformationResponse
    func getUserInformation(completion: @escaping (Result<UserInformationResponse, Error>) -> Void)
    
    /// Get User Transactions
    /// - Parameters:
    ///   - completion: Completion handler with result containing parsed TransactionsResponse
    func getUserTransactions(completion: @escaping (Result<TransactionsResponse, Error>) -> Void)
    
    /// Get Daily Report
    /// - Parameters:
    ///   - startTime: Start time in ISO 8601 format (e.g., "2025-11-01T00:00:00Z")
    ///   - endTime: End time in ISO 8601 format (e.g., "2025-11-09T00:00:00Z")
    ///   - completion: Completion handler with result
    func getDailyReport(startTime: String, endTime: String, completion: @escaping (Result<Data, Error>) -> Void)
    
    /// Create Transaction
    /// - Parameters:
    ///   - request: The transaction request data (userId will be automatically included from init)
    ///   - completion: Completion handler with result
    func createTransaction(_ request: CreateTransactionRequest, completion: @escaping (Result<Data, Error>) -> Void)
    
    /// Update Transaction Fraud Status
    /// - Parameters:
    ///   - request: The update request data
    ///   - completion: Completion handler with result
    func updateTransactionFraudStatus(_ request: UpdateTransactionFraudStatusRequest, completion: @escaping (Result<Data, Error>) -> Void)
    
    /// Create Credit Card
    /// - Parameters:
    ///   - request: The credit card request data (userId will be automatically included from init)
    ///   - completion: Completion handler with result
    func createCreditCard(_ request: CreateCreditCardRequest, completion: @escaping (Result<Data, Error>) -> Void)
}

// MARK: - API Models

public struct CreateTransactionRequest: Codable {
    public var userId: String
    public let ccNumber: String
    public let longitude: Double
    public let latitude: Double
    public let amount: Double
    public let fraud_flag: Bool
    
    public init(userId: String, ccNumber: String, longitude: Double, latitude: Double, amount: Double, fraud_flag: Bool) {
        self.userId = userId
        self.ccNumber = ccNumber
        self.longitude = longitude
        self.latitude = latitude
        self.amount = amount
        self.fraud_flag = fraud_flag
    }
}

public struct CreateCreditCardRequest: Codable {
    public var userId: String
    public let ccNumber: String
    public let exp: String
    public let sec: String
    public let iss: String
    
    public init(userId: String, ccNumber: String, exp: String, sec: String, iss: String) {
        self.userId = userId
        self.ccNumber = ccNumber
        self.exp = exp
        self.sec = sec
        self.iss = iss
    }
}

public struct UpdateTransactionFraudStatusRequest: Codable {
    // Add fields based on API requirements
    // This is a placeholder - adjust based on actual API needs
    
    public init() {}
}

// MARK: - Response Models

public struct NetworkCreditCard: Codable {
    public let ccNumber: String
    public let exp: String
    public let iss: String
    public let created_at: String
    
    public init(ccNumber: String, exp: String, iss: String, created_at: String) {
        self.ccNumber = ccNumber
        self.exp = exp
        self.iss = iss
        self.created_at = created_at
    }
}

public struct NetworkUser: Codable {
    public let id: String
    public let name: String
    public let isAdmin: Bool
    public let creditCards: [NetworkCreditCard]
    
    public init(id: String, name: String, isAdmin: Bool, creditCards: [NetworkCreditCard]) {
        self.id = id
        self.name = name
        self.isAdmin = isAdmin
        self.creditCards = creditCards
    }
}

public struct UserInformationResponse: Codable {
    public let user: NetworkUser
    
    public init(user: NetworkUser) {
        self.user = user
    }
}

public struct TransactionDetail: Codable {
    public let userId: String
    public let ccNumber: String
    public let date: String
    public let time: String
    public let longitude: Double
    public let latitude: Double
    public let locationName: String
    public let city: String
    public let state: String
    public let amount: Int
    public let created_at: String
    public let fraud_flag: Bool
    public let fraud_reason: String?
    public let fraud_checked_at: String?
    public let txn_id: String
    public let ts: String
}

public struct TransactionsResponse: Codable {
    public let transactions: [TransactionDetail]
    
    public init(transactions: [TransactionDetail]) {
        self.transactions = transactions
    }
}

// MARK: - NetworkInterface Implementation

class NetworkInterfaceImpl: NetworkInterface {
    private let baseURL: String
    private let adminSecret: String
    private let userId: String
    private let session: URLSession
    
    init(baseURL: String, adminSecret: String, userId: String, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.adminSecret = adminSecret
        self.userId = userId
        self.session = session
    }
    
    // MARK: - Protocol Implementation
    
    func fetch<T: Decodable>(_ url: URL, completion: @escaping (Result<T, Error>) -> Void) {
        var request = URLRequest(url: url)
        request.setValue(adminSecret, forHTTPHeaderField: "x-admin-secret")
        
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            
            guard let data = data else {
                completion(.failure(URLError(.zeroByteResource)))
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - API Methods
    
    /// Get User Information
    /// - Parameters:
    ///   - completion: Completion handler with result containing parsed UserInformationResponse
    func getUserInformation(completion: @escaping (Result<UserInformationResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/functions/v1/app-middleware/user") else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue(adminSecret, forHTTPHeaderField: "x-admin-secret")
        request.setValue(userId, forHTTPHeaderField: "user_id")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 60
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let data = data else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                print(String(data: data, encoding: .utf8) ?? "No data")
                let userInfo = try decoder.decode(UserInformationResponse.self, from: data)
                completion(.success(userInfo))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    /// Get User Transactions
    /// - Parameters:
    ///   - completion: Completion handler with result containing parsed TransactionsResponse
    func getUserTransactions(completion: @escaping (Result<TransactionsResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/functions/v1/app-middleware/transactions") else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue(adminSecret, forHTTPHeaderField: "x-admin-secret")
        request.setValue(userId, forHTTPHeaderField: "user_id")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 60
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let data = data else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let transactionsResponse = try decoder.decode(TransactionsResponse.self, from: data)
                completion(.success(transactionsResponse))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    /// Get Daily Report
    /// - Parameters:
    ///   - startTime: Start time in ISO 8601 format (e.g., "2025-11-01T00:00:00Z")
    ///   - endTime: End time in ISO 8601 format (e.g., "2025-11-09T00:00:00Z")
    ///   - completion: Completion handler with result
    func getDailyReport(startTime: String, endTime: String, completion: @escaping (Result<Data, Error>) -> Void) {
        var components = URLComponents(string: "\(baseURL)/functions/v1/app-middleware/dailyreport")
        components?.queryItems = [
            URLQueryItem(name: "startTime", value: startTime),
            URLQueryItem(name: "endTime", value: endTime)
        ]
        
        guard let url = components?.url else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(adminSecret, forHTTPHeaderField: "x-admin-secret")
        
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let data = data else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            
            completion(.success(data))
        }.resume()
    }
    
    /// Create Transaction
    /// - Parameters:
    ///   - request: The transaction request data (userId will be automatically included from init)
    ///   - completion: Completion handler with result
    func createTransaction(_ request: CreateTransactionRequest, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/functions/v1/app-middleware/transactions") else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(adminSecret, forHTTPHeaderField: "x-admin-secret")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create request with userId from init
        let requestWithUserId = CreateTransactionRequest(
            userId: userId,
            ccNumber: request.ccNumber,
            longitude: request.longitude,
            latitude: request.latitude,
            amount: request.amount,
            fraud_flag: request.fraud_flag
        )
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(requestWithUserId)
        } catch {
            completion(.failure(error))
            return
        }
        
        session.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let data = data else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            
            completion(.success(data))
        }.resume()
    }
    
    /// Update Transaction Fraud Status
    /// - Parameters:
    ///   - request: The update request data
    ///   - completion: Completion handler with result
    func updateTransactionFraudStatus(_ request: UpdateTransactionFraudStatusRequest, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/functions/v1/app-middleware/transactions") else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PUT"
        urlRequest.setValue(adminSecret, forHTTPHeaderField: "x-admin-secret")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            completion(.failure(error))
            return
        }
        
        session.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let data = data else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            
            completion(.success(data))
        }.resume()
    }
    
    /// Create Credit Card
    /// - Parameters:
    ///   - request: The credit card request data (userId will be automatically included from init)
    ///   - completion: Completion handler with result
    func createCreditCard(_ request: CreateCreditCardRequest, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/functions/v1/app-middleware/creditcard") else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(adminSecret, forHTTPHeaderField: "x-admin-secret")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create request with userId from init
        let requestWithUserId = CreateCreditCardRequest(
            userId: userId,
            ccNumber: request.ccNumber,
            exp: request.exp,
            sec: request.sec,
            iss: request.iss
        )
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(requestWithUserId)
        } catch {
            completion(.failure(error))
            return
        }
        
        session.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let data = data else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            
            completion(.success(data))
        }.resume()
    }
}
