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
    private let supabaseInterface = SupabaseInterface()
    
    func insertCreditCard() async {
        creditCards.append(CreditCard())
        do {
            try await supabaseInterface.insert(creditCard: creditCards.last!)
        }
        catch {
            creditCards.removeLast()
        }
    }
    
    func insertTransaction() async {
        guard !creditCards.isEmpty else { return }
        transactions.append(Transaction(creditCardNumber: creditCards.last!.number))
        do {
            try await supabaseInterface.insertTransaction(transaction: transactions.last!)
        }
        catch {
            transactions.removeLast()
        }
    }
}

struct ContentView: View {
    @State var vm = CreditCardFraudViewModel()
    var body: some View {
        VStack(spacing: 20) {
            Button("Insert Credit Card") {
                Task {
                    await vm.insertCreditCard()
                }
            }
            Button("Insert Transaction") {
                Task {
                    await vm.insertTransaction()
                }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
