//
//  ReportMetricsView.swift
//  CreditCardFraudApp
//
//  Created by Xavier Jackson on 12/13/25.
//

import SwiftUI

struct ReportMetricsView: View {
    let total: Int
    let flagged: Int
    let confirmed: Int
    let lossPrevented: Double

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                MetricBox(title: "Total Transactions", value: "(total)", subtitle: "+4.3% vs last month")
                MetricBox(title: "Flagged as Fraud", value: "(flagged)", subtitle: "(Double(flagged)/Double(total)*100, specifier: \("%.1f"))% of total")
            }
            HStack {
                MetricBox(title: "Confirmed Fraud", value: "(confirmed)", subtitle: "(Double(confirmed)/Double(flagged)*100, specifier: \("%.1f"))% of flagged")
                MetricBox(title: "Loss Prevented", value: "$(lossPrevented, specifier: \("%.2f"))", subtitle: "")
            }
        }
    }
}

struct MetricBox: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(value)
                .font(.title)
                .bold()
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .frame(maxWidth: .infinity)
    }
}
