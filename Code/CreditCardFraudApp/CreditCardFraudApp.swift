//
//  CreditCardFraudAppApp.swift
//  CreditCardFraudApp
//
//  Created by Tyler Helmrich on 11/1/25.
//

import SwiftUI
import Pushy
import UserNotifications

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
                guard let self = self else { return }

                switch result {
                case .success:
                    let creditCardTransactions = self.transactions.first(where: { $0.key == transaction.ccNumber })
                    guard let transactionList = creditCardTransactions?.value else {
                        return
                    }
                    let transactionIndex = transactionList.transactions.firstIndex(where: { $0.id == transaction.id })
                    guard let index = transactionIndex else {
                        return
                    }
                    
                    Task { @MainActor in
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "MM/dd/yyyy"
                        let dateString = dateFormatter.string(from: transaction.date)
                        
                        let timeFormatter = DateFormatter()
                        timeFormatter.dateFormat = "HH:mm"
                        let timeString = timeFormatter.string(from: transaction.date)
                        
                        let updatedTransaction = Transaction(
                            id: transaction.id,
                            creditCardNumber: transaction.ccNumber,
                            location: transaction.location,
                            city: transaction.city,
                            state: transaction.state,
                            dateString: dateString,
                            timeString: timeString,
                            amount: transaction.amount,
                            longitude: transaction.longitude,
                            latitude: transaction.latitude,
                            userId: transaction.userId,
                            isFraudulent: isFraudulent
                        )
                        transactionList.transactions[index] = updatedTransaction
                        
                        let copy = transactionList.deepCopy()
                        copy.hasFraudulentTransaction = transactionList.transactions.contains(where: { $0.isFraudulent })
                        
                        self.transactions[transaction.ccNumber] = copy
                    }
                case .failure(let error):
                    // Handle error if necessary, e.g., set errorMessage
                    self.errorMessage = error.localizedDescription
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

    func login(email: String, password: String, completion: ((Swift.Result<Void, Error>) -> Void)? = nil) {
        isLoading = true
        errorMessage = nil
        
        repository.login(email: email, password: password) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                self.isLoading = false
                
                switch result {
                case .success:
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
    @State private var showLogin: Bool = false
    
    var body: some Scene {
        WindowGroup {
            if appDelegate.isSignedIn {
                LandingPageView()
                    .environment(appDelegate.viewModel)
                    .task {
                        // If the user was already signed in (restored from UserDefaults),
                        // try to persist the device token to the backend now.
                        appDelegate.persistPushTokenIfNeeded()
                    }
            } else {
                if showLogin {
                    LoginView(
                        onLoginSuccess: {
                            appDelegate.isSignedIn = true
                            appDelegate.persistPushTokenIfNeeded()
                        },
                        onCreateAccountRequested: {
                            showLogin = false
                        }
                    )
                    .environment(appDelegate.viewModel)
                } else {
                    SignUpView(
                        onSignUpSuccess: {
                            appDelegate.isSignedIn = true
                            appDelegate.persistPushTokenIfNeeded()
                        },
                        onLoginRequested: {
                            showLogin = true
                        }
                    )
                    .environment(appDelegate.viewModel)
                }
            }
//            AccountView()
//            ReportsView(isAdmin: true)
        }
    }
}


@Observable
class CreditCardFraudAppDelegate: NSObject, UIApplicationDelegate {
    private enum UserDefaultsKeys {
        static let userId = "userId"
        static let pushyToken = "pushyToken"
        static let pushyTokenPersisted = "pushyTokenPersistedToBackend"
        static let pushyTokenPersistedValue = "pushyTokenPersistedValue"
    }
    
    var isSignedIn: Bool
    let networkInterface: NetworkInterface
    let repository: Repository
    let viewModel: CreditCardFraudViewModel
    
    var window: UIWindow?
    
    override init() {
        let storedUserId = (UserDefaults.standard.string(forKey: UserDefaultsKeys.userId) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let hasStoredUserId = !storedUserId.isEmpty
        
        self.isSignedIn = hasStoredUserId
        
        self.networkInterface = NetworkInterfaceImpl(
            baseURL: "https://vddcuogkozydtepyzuyo.supabase.co",
            adminSecret: "edge_admin@3333",
            userId: hasStoredUserId ? storedUserId : "67c31a0d-7658-458b-9196-b3133b26cd00",
            session: .shared
        )
        
        self.repository = Repository(networkInterface: networkInterface)
        self.viewModel = CreditCardFraudViewModel(repository: repository)
        
        super.init()
    }

    /// Persist the Pushy device token to Supabase if the user is signed in and we haven't done it yet.
    func persistPushTokenIfNeeded() {
        guard isSignedIn else { return }

        let token = (UserDefaults.standard.string(forKey: UserDefaultsKeys.pushyToken) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !token.isEmpty else { return }

        let alreadyPersisted = UserDefaults.standard.bool(forKey: UserDefaultsKeys.pushyTokenPersisted)
        let persistedValue = (UserDefaults.standard.string(forKey: UserDefaultsKeys.pushyTokenPersistedValue) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if alreadyPersisted && persistedValue == token {
            return
        }

        networkInterface.registerPushNotificationToken(token: token) { result in
            switch result {
            case .success:
                UserDefaults.standard.set(true, forKey: UserDefaultsKeys.pushyTokenPersisted)
                UserDefaults.standard.set(token, forKey: UserDefaultsKeys.pushyTokenPersistedValue)
                print("Pushy token persisted to backend")
            case .failure(let error):
                // Leave flags unset so we can retry later.
                print("Failed to persist Pushy token to backend: \(error.localizedDescription)")
            }
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        let pushy = Pushy(application)
        
        pushy.register({ (error, deviceToken) in
            // Handle registration errors
            if error != nil {
                return print ("Registration failed: \(error!.localizedDescription)")
            }
            
            // Print device token to console
            print("Pushy device token: \(deviceToken)")
            
            // Persist the token locally; it will be sent to the backend only once the user is signed in.
            let existing = (UserDefaults.standard.string(forKey: UserDefaultsKeys.pushyToken) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if existing != deviceToken {
                // Token changed -> mark as not persisted so we re-send once signed in.
                UserDefaults.standard.set(false, forKey: UserDefaultsKeys.pushyTokenPersisted)
                UserDefaults.standard.set("", forKey: UserDefaultsKeys.pushyTokenPersistedValue)
            }
            UserDefaults.standard.set(deviceToken, forKey: UserDefaultsKeys.pushyToken)

            // If we're already signed in, attempt to persist immediately.
            self.persistPushTokenIfNeeded()
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
            UNUserNotificationCenter.current().setBadgeCount(0) { error in
                if let error = error {
                    print("Error setting badge count: \(error.localizedDescription)")
                }
            }
            
            // Call this completion handler when you finish processing
            // the notification (after any asynchronous operations, if applicable)
            completionHandler(UIBackgroundFetchResult.newData)
        })
        
        return true
    }
}

