//
//  AddCardButton.swift
//  CreditCardFraudApp
//
//  Created by Tyler Helmrich on 11/30/25.
//

import SwiftUI

struct AddCardButton: View {
    @Binding var show: Bool
    var body: some View {
        Button {
            show.toggle()
        } label: {
            Image(systemName: "plus")
                .foregroundColor(.white)
                .font(.title2)
                .padding(4)
                .background {
                    Circle()
                    .fill(Color.black)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add credit card")
    }
}
