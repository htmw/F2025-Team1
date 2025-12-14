//
//  CreditCardFraudAppApp.swift
//  CreditCardFraudApp
//
//  Created by Tyler Helmrich on 11/1/25.
//

import SwiftUI
import Pushy

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
    
    func updateFraudStatus(_ transaction: Transaction, _ isFraudulent: Bool) {
        repository.updateTransactionFraudStatus(
            transaction,
            isFraudulent: isFraudulent,
            completion: { [weak self] result in
                guard let transactionList = self?.transactions.first(where: { $0.key == transaction.ccNumber })?.value else {
                    return
                }
                guard let index = transactionList.transactions.firstIndex(where: { $0.id == transaction.id }) else {
                    return
                }
                
                DispatchQueue.main.async {
                    transactionList.transactions[index] = Transaction(
                        id: transaction.id,
                        creditCardNumber: transaction.ccNumber,
                        location: transaction.location,
                        city: transaction.city,
                        state: transaction.state,
                        dateString: "TODO",   // pass proper string
                        timeString: "TODO",   // pass proper string
                        amount: transaction.amount,
                        longitude: transaction.longitude,
                        latitude: transaction.latitude,
                        userId: transaction.userId,
                        isFraudulent: isFraudulent
                    )
                    
                    let copy = transactionList.deepCopy()
                    copy.hasFraudulentTransaction = transactionList.transactions.contains(where: { $0.isFraudulent })
                    
                    self?.transactions[transaction.ccNumber] = copy
                }
            }
        )
    }
    
    func signup(email: String, password: String, completion: ((Swift.Result<Void, Error>) -> Void)? = nil) {
        isLoading = true
        errorMessage = nil
        
        repository.signup(email: email, password: password) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                self.isLoading = false
                
                switch result {
                case .success:
                    // Signup successful
                    completion?(.success(()))
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    completion?(.failure(error))
                }
            }
        }
    }
}

// Indicates where the app starts
@main
struct CreditCardFraudApp: App {
    // Wire together the dependencies
    @UIApplicationDelegateAdaptor(CreditCardFraudAppDelegate.self) var appDelegate
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
//            LandingPageView()
//            SignUpView()
//            AccountView()
            ReportsView(isAdmin: true)
                .environment(viewModel)
        }
    }
}


class CreditCardFraudAppDelegate: NSObject, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        let pushy = Pushy(application)
        
        pushy.register({ (error, deviceToken) in
            // Handle registration errors
            if error != nil {
                return print ("Registration failed: \(error!.localizedDescription)")
            }
            
            // Print device token to console
            print("Pushy device token: \(deviceToken)")
            
            // Persist the token locally and send it to your backend later
            UserDefaults.standard.set(deviceToken, forKey: "pushyToken")
        })
        
        // Enable in-app notification banners (iOS 10+)
        pushy.toggleInAppBanner(true)

        // Handle incoming notifications
        pushy.setNotificationHandler({ (data, completionHandler) in
            // Print notification payload
            print("Received notification: \(data)")
            
            // Show an alert dialog
            let alert = UIAlertController(title: "Incoming Notification", message: data["message"] as? String, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.window?.rootViewController?.present(alert, animated: true, completion: nil)
            
            // Reset iOS badge number (and clear all app notifications)
            UIApplication.shared.applicationIconBadgeNumber = 0
            
            // Call this completion handler when you finish processing
            // the notification (after any asynchronous operations, if applicable)
            completionHandler(UIBackgroundFetchResult.newData)
        })
        
        return true
    }
}
