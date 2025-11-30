//
//  CreditCardFraudAppApp.swift
//  CreditCardFraudApp
//
//  Created by Tyler Helmrich on 11/1/25.
//

import SwiftUI

@Observable
class CreditCardFraudViewModel {
    var isSending: Bool = false
    var creditCards: [CreditCard] = []
    var transactions: [String: CreditCardTransactions] = [:]
    var isLoading: Bool = false
    var errorMessage: String?
    
    private let repository: Repository
    
    init(repository: Repository) {
        self.repository = repository
    }
    
    func loadUserInformation() {
        isLoading = true
        errorMessage = nil
        
        repository.getUserInformation { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                self.isLoading = false

                switch result {
                case .success(let user):
                    self.creditCards = user.creditCards
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func loadTransactions() {
        repository.getUserTransactions { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }

                switch result {
                case .success(let transactions):
                    var map: [String: CreditCardTransactions] = [:]
                    transactions.forEach {
                        if let ccts = map[$0.ccNumber] {
                            ccts.append($0)
                        } else {
                            let ccts = CreditCardTransactions(ccNumber: $0.ccNumber)
                            ccts.append($0)
                            map[$0.ccNumber] = ccts
                        }
                    }
                    
                    self.transactions = map
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
//        transactions = [
//            Transaction(creditCardNumber: "8973458973", location: "Blah", city: "Blahblah", state: "NY", date: "39/34/23", time: "NOW"),
//            Transaction(creditCardNumber: "8973458973", location: "Blah", city: "Blahblah", state: "NY", date: "39/34/23", time: "NOW"),
//            Transaction(creditCardNumber: "8973458973", location: "Blah", city: "Blahblah", state: "NY", date: "39/34/23", time: "NOW"),
//            Transaction(creditCardNumber: "8973458973", location: "Blah", city: "Blahblah", state: "NY", date: "39/34/23", time: "NOW"),
//        ]
    }
    
    func addCreditCard(ccNumber: String, exp: String, sec: String, iss: String) {
        isLoading = true
        errorMessage = nil
        
        repository.addCreditCard(ccNumber: ccNumber, exp: exp, sec: sec, iss: iss) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                self.isLoading = false
                
                switch result {
                case .success:
                    // Reload user information to get the updated credit cards list
                    self.loadUserInformation()
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// Indicates where the app starts
@main
struct CreditCardFraudApp: App {
    // Wire together the dependencies
    private let networkInterface: NetworkInterface
    private let repository: Repository
    private let viewModel: CreditCardFraudViewModel
    
    init() {
        // Initialize NetworkInterface with configuration
        self.networkInterface = NetworkInterfaceImpl(
            baseURL: "https://vddcuogkozydtepyzuyo.supabase.co",
            adminSecret: "edge_admin@3333",
            userId: "67c31a0d-7658-458b-9196-b3133b26cd00",
            session: .shared
        )
        
        // Initialize Repository with NetworkInterface
        self.repository = Repository(networkInterface: networkInterface)
        
        // Initialize ViewModel with Repository
        self.viewModel = CreditCardFraudViewModel(repository: repository)
    }
    
    var body: some Scene {
        WindowGroup {
            LandingPageView()
                .environment(viewModel)
        }
    }
}
