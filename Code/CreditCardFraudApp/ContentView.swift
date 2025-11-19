//
//  ContentView.swift
//  CreditCardFraudApp
//
//  Created by Tyler Helmrich on 11/1/25.
//

import SwiftUI

@Observable
class CreditCardFraudViewModel {
    var isSending: Bool = false
    var creditCards: [CreditCard] = []
    var transactions: [Transaction] = []
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
        isLoading = true
        errorMessage = nil
        
        repository.getUserTransactions { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                self.isLoading = false
                
                switch result {
                case .success(let transactions):
                    self.transactions = transactions
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct ContentView: View {
    @Environment(CreditCardFraudViewModel.self) var vm
    
    var body: some View {
<<<<<<< HEAD
            List{
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
            }
    }
}

////#Preview {
//    ContentView(
//    )
//}
=======
        List {
            ForEach(vm.transactions, id: \.id) { t in
                HStack {
                    VStack(alignment: .leading) {
                        Text(t.location.isEmpty ? "Location" : t.location)
                        Text("\(t.city.isEmpty ? "City" : t.city), \(t.state.isEmpty ? "State" : t.state)")
                        Text("\(t.date) \(t.time)")
                    }
                    Spacer()
                    Text("$\(t.amount/100).\(String(format: "%02d", t.amount % 100))")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
        }
        .task {
            vm.loadTransactions()
        }
        .overlay {
            if vm.isLoading {
                ProgressView()
            }
        }
        .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
            Button("OK") {
                vm.errorMessage = nil
            }
        } message: {
            if let errorMessage = vm.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

// #Preview {
//     let networkInterface = NetworkInterfaceImpl(
//         baseURL: "https://vddcuogkozydtepyzuyo.supabase.co",
//         adminSecret: "edge_admin@3333",
//         userId: "67c31a0d-7658-458b-9196-b3133b26cd00"
//     )
//     let repository = Repository(networkInterface: networkInterface)
//     let viewModel = CreditCardFraudViewModel(repository: repository)
    
//     ContentView()
//         .environment(viewModel)
// }
>>>>>>> d6dfad7d946d297c05e6df8263b7d285b10fb276
}
}
