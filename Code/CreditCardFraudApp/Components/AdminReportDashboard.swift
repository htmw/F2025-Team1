//
//  AdminReportDashboard.swift
//  CreditCardFraudApp
//
//  Created by Xavier Jackson on 12/13/25.
//

import SwiftUI

struct AdminReportDashboard: View {
    @Environment(CreditCardFraudViewModel.self) var vm

    private var allTransactions: [Transaction] {
        vm.transactions.values.flatMap { $0.transactions }
    }
    
    private var fraudulentTransactions: [Transaction] {
        allTransactions.filter { $0.isFraudulent }
    }
    
    private var totalTransactions: Int {
        allTransactions.count
    }
    
    private var flaggedCount: Int {
        fraudulentTransactions.count
    }
    
    private var confirmedCount: Int {
        // Confirmed fraud is the same as flagged (manually confirmed via the app)
        flaggedCount
    }
    
    private var lossPrevented: Double {
        // Calculate total amount from fraudulent transactions (amount is in cents)
        Double(fraudulentTransactions.reduce(0) { $0 + $1.amount }) / 100.0
    }

    var body: some View {
        VStack(spacing: 16) {
            ReportMetricsView(
                total: totalTransactions,
                flagged: flaggedCount,
                confirmed: confirmedCount,
                lossPrevented: lossPrevented
            )
            FraudBarChart(transactions: allTransactions)
            HighRiskTransactionList(transactions: fraudulentTransactions)
        }
    }
}

