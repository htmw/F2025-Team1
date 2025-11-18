//
//  LandingPageView.swift
//  CreditCardFraudApp
//
//  Created by Xavier Jackson on 11/17/25.
//

import SwiftUI

struct TransactionRow{
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

struct CreditCardView{
    let color: Color
    let brand: String
    let number: String
    
    var body: some View {
        ZStack{
            RoundedRectangle(cornerRadius: 16)
                .fill(color)
                .frame(height: 110)
        }
    }
}

struct LandingPageView: View{
    var body: some View {
        VStack(spacing: 20){
            // Header Component
            HStack{
                Image(systemName: "banknote") //Placeholder for Logo
                Text("App Name")
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
                Text("Username")
                    .foregroundColor(.gray)
            }
            .padding()
            
            // Navigation Component
            HStack(spacing: 30) {
                Text("Home")
                Text("Account")
                Text("Dashboard")
            }
            .font(.headline)
            .padding(.horizontal)
            
            Divider()
            
            // Recent Transactions
            VStack(alignment: .leading,spacing: 15){
                Text("Credit Cards")
                    .font(.headline)
                CreditCard
            }
        }
    }
}
