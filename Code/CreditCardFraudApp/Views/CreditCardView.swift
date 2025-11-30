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

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 16)
                .fill(color)
                .frame(height: 110)

            VStack(alignment: .leading) {
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
