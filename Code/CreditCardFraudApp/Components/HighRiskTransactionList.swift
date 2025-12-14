//
//  HighRiskTransactionList.swift
//  CreditCardFraudApp
//
//  Created by Xavier Jackson on 12/13/25.
//

import SwiftUI

struct HighRiskTransactionList: View {
    let transactions: [Transaction]

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("High-Risk Transactions")
                    .font(.headline)
                Spacer()
                Button("View All") {
                    // TODO: navigate to full list
                }
            }

            ForEach(transactions.prefix(1)) { tx in
                VStack(alignment: .leading, spacing: 4) {
                    Text("Txn #(tx.id.uuidString.prefix(6))")
                    Text("Card: •••• (tx.ccNumber.suffix(4))")
                    Text("Time: (tx.date.formatted(date: .omitted, time: .shortened))")
                    Text("Location: (tx.city), (tx.state)")
                    Text("Amount: $(Double(tx.amount)/100, specifier: \("%.2f")) - Online")
                    Text("Risk Level: HIGH")
                        .foregroundColor(.red)
                        .bold()
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
        .padding(.top)
    }
}
