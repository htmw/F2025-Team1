//
//  CreditCardFraudAppApp.swift
//  CreditCardFraudApp
//
//  Created by Tyler Helmrich on 11/1/25.
//

import SwiftUI

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
//            ContentView()
//                .environment(viewModel)
        }
    }
}
