//
//  LandingPageView.swift
//  CreditCardFraudApp
//
//  Created by Xavier Jackson on 11/17/25.
//

import SwiftUI



struct LandingPageView: View{
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
                    Text("Credit Cards")
                        .font(.headline)
                    
                    TransactionRow(amount: "$2,000.00", description: "Vacation")
                    TransactionRow(amount: "$1,500.00", description: "Business Travel")
                    
                    
                    Divider()
                    
                    // Credit Cards
                    VStack(alignment: .leading, spacing: 16){
                        Text("Credit Cards")
                            .font(.headline)
                    }
                    
                    
                    CreditCardView(color: .orange, brand: "Mastercard", number: "**** **** **** 5678")
                        .onTapGesture {
                            navigationPath.append("Hello World")
                        }
                        .navigationDestination(for:String.self, destination: {_ in
                            
                            TransactionListView()
                            
                        })
                    
                    CreditCardView(color: .blue, brand: "Visa", number: "**** **** **** 1234")
                        .onTapGesture {
                            navigationPath.append("Hello World")
                        }
                        .navigationDestination(for:String.self, destination: {_ in
                            
                            TransactionListView()
                            
                        })

                    //                AddCardButton()
                }
                .padding(.horizontal)
                
                Spacer()
            }
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
    
    var body: some View {
        ZStack{
            RoundedRectangle(cornerRadius: 16)
                .fill(color)
                .frame(height: 110)
            
            VStack(alignment: .leading, spacing: 8){
                Text(brand)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(number)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
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
