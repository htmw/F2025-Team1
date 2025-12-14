//
//  AccountView.swift
//  CreditCardFraudApp
//
//  Created by Xavier Jackson on 12/4/25.
//

import SwiftUI

struct AccountPageView: View { @Environment(CreditCardFraudViewModel.self) var vm
    @State private var isShowingReports = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Top Bar
            HStack {
                Image(systemName: "chevron.left")
                Spacer()
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 32, height: 32)
                Text("David Smith")
                    .font(.headline)
                Spacer()
                Image(systemName: "bell.fill")
            }
            .padding(.horizontal)
            
            // Action Buttons
            HStack(spacing: 16) {
                Button("Transaction") {
                    // navigate or scroll to transaction section
                }
                .buttonStyle(.borderedProminent)
                
                Button("Reports") {
                    isShowingReports = true
                }
                .buttonStyle(.bordered)
            }
            
            // Cards and Accounts
            VStack(alignment: .leading, spacing: 12) {
                Text("Cards and Accounts ((vm.creditCards.count))")
                    .font(.headline)
                    .padding(.horizontal)
                
                ForEach(vm.creditCards, id: \.ccNumber) { cc in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Balance")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("$(String(format: \("%.2f"), cc.balance))")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(cc.ccNumber.chunked(by: 4).joined(separator: " "))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text("Exp: (cc.exp)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray6)))
                    .padding(.horizontal)
                }
            }
            
            // Recent Transactions
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Transactions")
                    .font(.headline)
                    .padding(.horizontal)
                
                let recent = Array(
                    vm.transactions.values
                        .flatMap { $0.transactions }
                        .sorted(by: { $0.date > $1.date })
                        .prefix(2)
                )
                
                ForEach(recent) { tx in
                    VStack(alignment: .leading) {
                        Text(tx.location)
                            .font(.subheadline)
                        Text("$(String(format: \("%.2f"), Double(tx.amount)))")
                            .font(.headline)
                        Text(tx.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray5)))
                    .padding(.horizontal)
                }
            }
            
            
            Spacer()
        }
        .sheet(isPresented: $isShowingReports) {
            ReportsView(vm: vm, isAdmin: false)
        }
    }
    
}
