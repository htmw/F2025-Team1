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
    
    func append(_ transaction: Transaction) {
        transactions.append(transaction)
        hasFraudulentTransaction = transaction.isFraudulent || hasFraudulentTransaction
    }
}




struct TransactionListView: View {
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
                            Text("\(t.city.isEmpty ? "Unknown City" : t.city), \(t.state.isEmpty ? "Unknown State" : t.state)")
                            Text("\(t.date) \(formatTime(t.time) ?? "---")")
                        }
                        Spacer()
                        Text("$\(t.amount/100).\(String(format: "%02d", t.amount % 100))")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .badge(t.isFraudulent ? Text("!").bold().foregroundStyle(.red) : nil)
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
