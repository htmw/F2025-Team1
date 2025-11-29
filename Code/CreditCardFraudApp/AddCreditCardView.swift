//
//  AddCreditCardView.swift
//  CreditCardFraudApp
//
//  Created by Tyler Helmrich on 11/29/25.
//

import SwiftUI

struct AddCreditCardView: View {
    var vm: CreditCardFraudViewModel
    @Binding var show: Bool
    @State var number: String = ""
    @State var exp: String = ""
    @State var sec: String = ""
    @State var iss: String = "Visa"
    
    let issuers = ["American Express", "Discover", "Visa", "Mastercard"]
    
    var body: some View {
        Form {
            Section(header: Text("Credit Card Information")) {
                TextField("Card Number", text: $number)
                    .keyboardType(.numberPad)
                
                HStack {
                    TextField("Exp (MM/YY)", text: $exp)
                        .onChange(of: exp) { oldValue, newValue in
                            // Format as MM/YY
                            let formatted = formatExpirationDate(newValue)
                            if formatted != newValue {
                                exp = formatted
                            }
                        }
                    
                    TextField("CVV", text: $sec)
                        .keyboardType(.numberPad)
                        .onChange(of: sec) { oldValue, newValue in
                            // Limit to 3 digits
                            let numbers = newValue.filter { $0.isNumber }
                            let limited = String(numbers.prefix(3))
                            if limited != newValue {
                                sec = limited
                            }
                        }
                }
                
                Picker("Issuer", selection: $iss) {
                    ForEach(issuers, id: \.self) { issuer in
                        Text(issuer).tag(issuer)
                    }
                }
            }
            
            Button("Add Credit Card") {
                vm.addCreditCard(ccNumber: number, exp: exp, sec: sec, iss: iss)
                show = false
            }
            .disabled(number.isEmpty || exp.isEmpty || sec.isEmpty)
        }
    }
    
    private func formatExpirationDate(_ input: String) -> String {
        // Remove all non-numeric characters
        let numbers = input.filter { $0.isNumber }
        
        // Limit to 4 digits
        let limited = String(numbers.prefix(4))
        
        // Format as MM/YY
        if limited.count <= 2 {
            return limited
        } else {
            let month = String(limited.prefix(2))
            let year = String(limited.dropFirst(2))
            return "\(month)/\(year)"
        }
    }
}

