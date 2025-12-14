//
//  UserReportDashboard.swift
//  CreditCardFraudApp
//
//  Created by Xavier Jackson on 12/13/25.
//

import SwiftUI

struct UserReportDashboard: View {
    let vm: CreditCardFraudViewModel

    var body: some View {
        VStack(spacing: 16) {
            ReportMetricsView(total: 3000, flagged: 50, confirmed: 27, lossPrevented: 530)
            FraudBarChart(transactions: vm.transactions.values.flatMap { $0.transactions })
            HighRiskTransactionList(transactions: vm.transactions.values.flatMap { $0.transactions }.filter { $0.isFraudulent })
        }
    }
}
