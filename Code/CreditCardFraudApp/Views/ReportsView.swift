//
//  ReportsView.swift
//  CreditCardFraudApp
//
//  Created by Xavier Jackson on 12/4/25.
//

import SwiftUI

struct ReportsView: View {
    @Environment(CreditCardFraudViewModel.self) var vm
    let isAdmin: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Fraud Report")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)

                ReportFilterBar()

                if isAdmin {
                    AdminReportDashboard()
                } else {
                    UserReportDashboard()
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Reports")
        }
    }
}

