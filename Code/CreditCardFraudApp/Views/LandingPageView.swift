//
//  LandingPageView.swift
//  CreditCardFraudApp
//
//  Created by Xavier Jackson on 11/17/25.
//

import SwiftUI

struct LandingPageView: View{
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
                                Text("Welcome, David")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Your account overview")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)

                        // Balance Card
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

                            ForEach(vm.recentTransactions.prefix(4), id: \.id) { tx in
                                TransactionListView(amount: tx.amount, description: tx.description)
                                    .padding(.horizontal)
                            }
                        }

                        // Credit Cards Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Credit Cards")
                                    .font(.headline)
                                Spacer()
                                AddCardButton(show: $isShowingAddCreditCard) // ✅ Use the button, not the form view
                            }
                            .padding(.horizontal)

                            ForEach(vm.creditCards, id: \.ccNumber) { cc in
                                CreditCardView( // ✅ Use the display view, not the form
                                    color: cc.iss == "VISA" ? .blue : (cc.iss == "MASTERCARD" ? .orange : .brown),
                                    brand: cc.iss,
                                    number: "**** **** **** \(cc.ccNumber.suffix(4))",
                                    exp: cc.exp,
                                    isFraudulent: vm.transactions[cc.ccNumber]?.hasFraudulentTransaction ?? false
                                )
                                .onTapGesture {
                                    navigationPath.append(cc.ccNumber)
                                }
                                .padding(.horizontal)
                            }
                        }

                        Spacer(minLength: 40)
                    }
                }
                .sheet(isPresented: $isShowingAddCreditCard) {
                    AddCreditCardView(vm: vm, show: $isShowingAddCreditCard)
                        .presentationDetents([.medium])
                }
                .navigationDestination(for: String.self) { ccNumber in
                    TransactionListView(
                        ccNumber: ccNumber,
                        transactions: vm.transactions[ccNumber, default: CreditCardTransactions(ccNumber: ccNumber)].transactions
                    )
                }
            }
            .task {
                vm.loadUserInformation()
                vm.loadTransactions()
            }
        }
    }

