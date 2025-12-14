//
//  FraudBarChart.swift
//  CreditCardFraudApp
//
//  Created by Xavier Jackson on 12/13/25.
//

import SwiftUI
import Charts

struct FraudBarChart: View {
    let transactions: [Transaction]

    var body: some View {
        Chart {
            let fraudCount = transactions.filter { $0.isFraudulent }.count
            let legitCount = transactions.count - fraudCount

            BarMark(x: .value("Type", "Fraudulent"), y: .value("Count", fraudCount))
                .foregroundStyle(.red)
            BarMark(x: .value("Type", "Legitimate"), y: .value("Count", legitCount))
                .foregroundStyle(.green)
        }
        .frame(height: 200)
        .padding(.horizontal)
    }
}
