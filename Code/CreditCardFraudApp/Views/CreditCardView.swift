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
            // Brand logo + title row
            HStack {
                brandLogo
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 24)
                Spacer()
                Text(brand)
                    .font(.caption)
                    .foregroundColor(.white)
            }

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

    // MARK: - Brand Logo
    private var brandLogo: Image {
        switch brand.uppercased() {
        case "VISA":
            return Image("visa_logo")       // Add visa_logo asset in Assets.xcassets
        case "MASTERCARD":
            return Image("mastercard_logo") // Add mastercard_logo asset
        case "AMEX":
            return Image("amex_logo")       // Add amex_logo asset
        case "DISCOVER":
            return Image("discover_logo")   // Add discover_logo asset
        default:
            return Image(systemName: "creditcard") // fallback SF Symbol
        }
    }
}
