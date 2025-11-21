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
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 20){
                // Header Component
                HStack{
                    Image(systemName: "banknote") //Placeholder for Logo
                    Text("Fraud Stopper")
                        .font(.title)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding(8)
                
                
                Divider()
                
                // Recent Transactions
                VStack(alignment: .leading,spacing: 15){
                    Group {
                        Text("Credit Cards")
                            .font(.headline)
                        
                        TransactionRow(amount: "$2,000.00", description: "Vacation")
                        TransactionRow(amount: "$1,500.00", description: "Business Travel")
                        
                        
                        Divider()
                        
                        Text("Credit Cards")
                            .font(.headline)
                    }
                    .padding(.horizontal)
                    
                    ScrollView {
                        ForEach(vm.creditCards, id: \.ccNumber) { cc in
                            CreditCardView(color: cc.iss == "VISA" ? .blue : (cc.iss == "MASTERCARD" ? .orange : .brown), brand: cc.iss, number: "**** **** **** \(cc.ccNumber.suffix(4))", exp: cc.exp, isFraudulent: (vm.transactions[cc.ccNumber]?.hasFraudulentTransaction ?? false))
                                .onTapGesture {
                                    navigationPath.append(cc.ccNumber)
                                }
                                .padding(.horizontal)
                        }
                    }
                    
                    //                AddCardButton()
                }
                
                Spacer()
            }
            .navigationDestination(for:String.self, destination: {
                TransactionListView(ccNumber: $0, transactions: vm.transactions[$0, default: CreditCardTransactions(ccNumber: $0)].transactions)
            })
        }
        .task {
            vm.loadUserInformation()
            vm.loadTransactions()
        }
    }
    
}

// Subviews

struct TransactionRow: View{
    let amount: String
    let description: String
    
    var body: some View {
        HStack {
            Text(amount)
                .fontWeight(.semibold)
            
            Spacer()
            
            Text(description)
                .foregroundColor(.gray)
        }
    }
}

struct CreditCardView: View{
    let color: Color
    let brand: String
    let number: String
    let exp: String
    let isFraudulent: Bool
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 16)
                .fill(color)
                .frame(height: 110)
            
            VStack(alignment: .leading){
                Text(brand)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack {
                    Text(number)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    Spacer()
                    
                    Text(exp)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
                
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if isFraudulent {
                ZStack {
                    Circle()
                        .foregroundStyle(.red)
                        .frame(height: 24)
                    Text("!")
                        .bold()
                        .foregroundStyle(.white)
                }
                .offset(x: 6, y: -6)
            }
        }
        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
    }
}

struct AddCardButton: View {
    var body: some View{
        Button {
            // Add card action
        } label: {
            ZStack {
                Circle()
                    .fill(Color.black)
                    .frame(width: 50, height: 50)
                Image(systemName: "plus")
                    .foregroundColor(.white)
                    .font(.title2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add credit card")
    }
}

// Preview

struct LandingPageView_Previews: PreviewProvider{
    static var previews: some View {
        Group {
            LandingPageView()
                .previewDevice("iPhone 16 Pro Max")
            LandingPageView()
                .preferredColorScheme(.dark)
                .previewDevice("iPhone 16 Pro Max")
        }
    }
}
