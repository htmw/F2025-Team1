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
                .foregroundColor(.white)

            Text("$\(String(format: "%.2f", balance))")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(number)
                .font(.subheadline)
                .foregroundColor(.white)

            Text("Exp: \(exp)")
                .font(.subheadline)
                .foregroundColor(.white)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color)
        )
        .overlay(
            isFraudulent ?
            Circle()
                .fill(Color.red)
                .frame(width: 24, height: 24)
                .overlay(
                    Text("!")
                        .foregroundColor(.white)
                        .font(.caption)
                        .bold()
                )
                .offset(x: 12, y: -12)
            : nil,
            alignment: .topTrailing
        )
        .shadow(radius: 4)
    }
}
