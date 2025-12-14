//
//  AdminReportDashboard.swift
//  CreditCardFraudApp
//
//  Created by Xavier Jackson on 12/13/25.
//

import SwiftUI

struct AdminReportDashboard: View {
    @Environment(CreditCardFraudViewModel.self) var vm

    var body: some View {
        VStack(spacing: 16) {
            ReportMetricsView(
                total: vm.transactions.values.flatMap { $0.transactions }.count,
                flagged: vm.transactions.values.flatMap { $0.transactions }.filter { $0.isFraudulent }.count,
                confirmed: 27,
                lossPrevented: 530.0
            )
            FraudBarChart(transactions: vm.transactions.values.flatMap { $0.transactions })
            HighRiskTransactionList(transactions: vm.transactions.values.flatMap { $0.transactions }.filter { $0.isFraudulent })
        }
    }
}

