//
//  ReportsView.swift
//  CreditCardFraudApp
//
//  Created by Xavier Jackson on 12/4/25.
//

import SwiftUI

struct ReportsView: View {
    let vm: CreditCardFraudViewModel
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
                    AdminReportDashboard(vm: vm)
                } else {
                    UserReportDashboard(vm: vm)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Reports")
        }
    }
}

