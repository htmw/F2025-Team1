//
//  LandingPageView.swift
//  CreditCardFraudApp
//
//  Created by Xavier Jackson on 11/17/25.
//

import SwiftUI

struct LandingPageView: View {
    @Environment(CreditCardFraudViewModel.self) var vm
    @State private var navigationPath = NavigationPath()
    @State private var isShowingAddCreditCard: Bool = false
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with greeting and profile
                    HStack {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            
                            Text("Fraud Stopper")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            Text("Welcome, David Smith")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("You can see all card information here")
                                .font(.subheadline)
                            .foregroundColor(.gray)                        }
                        Spacer()
                        
                        NavigationLink(value: "reports") {
                            Label("Reports", systemImage: "doc.text.fill")
                                .labelStyle(.iconOnly)
                        }
                    }
                    .padding(.horizontal)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Total Balance")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("$4,570.80")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        ProgressView(value: 0.87) {
                            Text("87% used of $5,000")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .progressViewStyle(.linear)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray6)))
                    .padding(.horizontal)
                    
                    // Recent Transactions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Transactions")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        //                        ForEach(vm.recentTransactions.prefix(4), id: \.id) { tx in
                        //                            TransactionListView(amount: tx.amount, description: tx.description)
                        //                                .padding(.horizontal)
                        //                        }
                    }
                    
                    // Credit Cards Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Credit Cards")
                                .font(.headline)
                            Spacer()
                            AddCardButton(show: $isShowingAddCreditCard)
                        }
                        .padding(.horizontal)
                        
                        ForEach(vm.creditCards, id: \.ccNumber) { cc in
                            CreditCardView(
                                color: {
                                    switch cc.iss.uppercased() {
                                    case "VISA": return .blue
                                    case "MASTERCARD": return .red
                                    case "AMEX", "AMERICAN EXPRESS": return .purple // ✅ Amex styling
                                    case "DISCOVER": return .orange
                                    default: return .brown
                                    }
                                }(),
                                brand: cc.iss,
                                number: "**** **** **** \(cc.ccNumber.suffix(4))",
                                exp: cc.exp,
                                isFraudulent: vm.transactions[cc.ccNumber]?.hasFraudulentTransaction ?? false,
                                balance: 100
                            )
                            .onTapGesture {
                                navigationPath.append(cc.ccNumber)
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
                .sheet(isPresented: $isShowingAddCreditCard) {
                    AddCreditCardView(vm: vm, show: $isShowingAddCreditCard)
                        .presentationDetents([.medium])
                }
                .navigationDestination(for: String.self) { destination in
                    if destination == "reports" {
                        ReportsView(isAdmin: true)
                    } else {
                        TransactionListView(
                            ccNumber: destination,
                            transactions: vm.transactions[destination, default: CreditCardTransactions(ccNumber: destination)].transactions
                        )
                    }
                }
            }
            .task {
                vm.loadUserInformation()
                vm.loadTransactions()
            }
            .overlay {
                if vm.isLoading {
                    ProgressView("Loading...")
                } else if let errorMessage = vm.errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundStyle(.red)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                }
            }
        }
    }
}

extension String {
        func chunked(by chunkSize: Int) -> [String] {
            stride(from: 0, to: count, by: chunkSize).map {
                let start = index(startIndex, offsetBy: $0)
                let end = index(start, offsetBy: chunkSize, limitedBy: endIndex) ?? endIndex
                return String(self[start..<end])
            }
        }
    }
