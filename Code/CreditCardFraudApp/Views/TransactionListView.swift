//
//  ContentView.swift
//  CreditCardFraudApp
//
//  Created by Tyler Helmrich on 11/1/25.
//

import SwiftUI

class CreditCardTransactions {
    var ccNumber: String
    var hasFraudulentTransaction: Bool
    var transactions: [Transaction]
    
    init(ccNumber: String, hasFraudulentTransaction: Bool = false, transactions: [Transaction] = []) {
        self.ccNumber = ccNumber
        self.hasFraudulentTransaction = hasFraudulentTransaction
        self.transactions = transactions
    }
    
    func deepCopy() -> CreditCardTransactions {
        return CreditCardTransactions(ccNumber: ccNumber, hasFraudulentTransaction: hasFraudulentTransaction, transactions: transactions)
    }
    
    func append(_ transaction: Transaction) {
        transactions.append(transaction)
        hasFraudulentTransaction = transaction.isFraudulent || hasFraudulentTransaction
    }
}




struct TransactionListView: View {
    @Environment(CreditCardFraudViewModel.self) var vm
    let ccNumber: String
    let transactions: [Transaction]
    private let posixFormatter = getPosixDateFormatter()
    private let displayFormatter = getDateFormatter()
    
    var body: some View {
        VStack(alignment: .leading) {
            
            Text(ccNumber)
                .font(.title)
                .bold()
                .padding(.horizontal)
            
            List {
                
                ForEach(transactions, id: \.id) { t in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(t.location.isEmpty ? "---" : t.location)
                            let cityText = t.city.isEmpty ? "Unknown City" : t.city
                            let stateText = t.state.isEmpty ? "Unknown State" : t.state
                            Text("\(cityText), \(stateText)")
                            Text(displayFormatter.string(from: t.date))
                        }
                        Spacer()
                        let dollars = t.amount / 100
                        let cents = String(format: "%02d", t.amount % 100)
                        Text("$\(dollars).\(cents)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .badge(fraudBadge(isFraudulent: t.isFraudulent))
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        transactionSwipeActions(t)
                    }
                }
            }
        }
//        .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
//            Button("OK") {
//                vm.errorMessage = nil
//            }
//        } message: {
//            if let errorMessage = vm.errorMessage {
//                Text(errorMessage)
//            }
//        }
    }
    
    private static func getPosixDateFormatter() -> DateFormatter {
        let parseFormatter = DateFormatter()
        parseFormatter.locale = Locale(identifier: "en_US_POSIX")
        parseFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        parseFormatter.dateFormat = "HH:mm:ss.SSSSSSX"
        
        return parseFormatter
    }
    
    private static func getDateFormatter() -> DateFormatter {
        let displayFormatter = DateFormatter()
        displayFormatter.locale = Locale.current
        displayFormatter.timeZone = TimeZone.current
        displayFormatter.dateFormat = "H:mm a"
        
        return displayFormatter
    }

    private func formatTime(_ raw: String) -> String? {
        guard let date = posixFormatter.date(from: raw) else { return nil }
        return displayFormatter.string(from: date)
    }

    @ViewBuilder
    private func transactionSwipeActions(_ t: Transaction) -> some View {
        if t.isFraudulent {
            Button(action: {
                vm.updateFraudStatus(t, false)
            }) {
                Label("Approve", systemImage: "checkmark")
            }
            .tint(.green)
        } else {
            Button(action: {
                vm.updateFraudStatus(t, true)
            }) {
                Label("Deny", systemImage: "exclamationmark")
            }
            .tint(.red)
        }
    }

    private func fraudBadge(isFraudulent: Bool) -> Text? {
        if isFraudulent {
            return Text("!").bold().foregroundStyle(.red)
        } else {
            return nil
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
