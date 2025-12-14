//
//  ReportFilterBar.swift
//  CreditCardFraudApp
//
//  Created by Xavier Jackson on 12/13/25.
//

import SwiftUI

struct ReportFilterBar: View {
    @State private var selectedFilter: String = "Today"
    var onFilterChange: ((String) -> Void)? = nil

    var body: some View {
        HStack {
            ForEach(["Today", "Week", "Month", "Custom"], id: \.self) { label in
                Button(label) {
                    selectedFilter = label
                    onFilterChange?(label)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedFilter == label ? Color.blue.opacity(0.2) : Color(.systemGray5))
                .cornerRadius(8)
            }
        }
    }
}
