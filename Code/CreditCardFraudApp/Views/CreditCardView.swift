//
//  CreditCardView.swift
//  CreditCardFraudApp
//
//  Created by Xavier Jackson on 11/30/25.
//
import SwiftUI

struct CreditCardView: View {
    let color: Color
    let brand: String
    let number: String
    let exp: String
    let isFraudulent: Bool
    let balance: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Balance")
                .font(.caption)
                .foregroundColor(.gray)

            Text("$\(String(format: "%.2f", balance))")
                .font(.title2)
                .fontWeight(.bold)

            Text(number)
                .font(.subheadline)
                .foregroundColor(.gray)

            Text(exp)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 16).fill(color))
        .overlay(
            isFraudulent ?
            Circle()
                .fill(Color.red)
                .frame(width: 24, height: 24)
                .overlay(Text("!").foregroundColor(.white).bold())
                .offset(x: 12, y: -12)
            : nil,
            alignment: .topTrailing
        )
        .shadow(radius: 4)
    }
}

