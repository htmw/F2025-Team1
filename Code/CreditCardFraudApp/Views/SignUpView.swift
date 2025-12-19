//
//  SignUpView.swift
//  CreditCardFraudApp
//
//  Created by Arth Patel on 11/30/25.
//

import SwiftUI

/// Checkbox style for the "I agree to the Terms & Conditions" toggle
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .font(.system(size: 18))
                    .foregroundColor(configuration.isOn ? .blue : .secondary)

                configuration.label
            }
        }
        .buttonStyle(.plain)
    }
}

struct SignUpView: View {
    @Environment(CreditCardFraudViewModel.self) var vm

    // MARK: - Form State
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var agreeToTerms: Bool = false

    /// Optional callback so the app can move to LandingPageView later
    var onSignUpSuccess: (() -> Void)? = nil
    
    /// Optional callback to switch to LoginView
    var onLoginRequested: (() -> Void)? = nil

    var body: some View {
        ZStack {
            // Background like your Figma (light gradient)
            LinearGradient(
                colors: [
                    Color(.systemGray6),
                    Color(.systemGray5)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {
                // MARK: - App title & icon at top
                VStack(spacing: 8) {
                    Text("Credit Card Fraud Detection")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                }
                .padding(.top, 40)

                Spacer()

                // MARK: - White Card
                VStack(alignment: .leading, spacing: 20) {

                    // Title + subtitle
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Create Account")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Fill in your details to get started")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    // Full Name
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Full Name")
                            .font(.footnote)
                            .foregroundColor(.secondary)

                        TextField("Enter your full name", text: $fullName)
                            .textContentType(.name)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }

                    // Email
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email Address")
                            .font(.footnote)
                            .foregroundColor(.secondary)

                        TextField("name@example.com", text: $email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }

                    // Password
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Password")
                            .font(.footnote)
                            .foregroundColor(.secondary)

                        SecureField("Password", text: $password)
                            .textContentType(.newPassword)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }

                    // Confirm Password
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Confirm Password")
                            .font(.footnote)
                            .foregroundColor(.secondary)

                        SecureField("Confirm password", text: $confirmPassword)
                            .textContentType(.newPassword)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }

                    // Terms & Conditions checkbox
                    Toggle(isOn: $agreeToTerms) {
                        Text("I agree to the Terms & Conditions")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .toggleStyle(CheckboxToggleStyle())
                    .padding(.top, 4)
                    
                    // Error message display
                    if let errorMessage = vm.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .padding(.top, 4)
                    }

                    // Sign Up button
                    Button {
                        // Validate passwords match
                        guard password == confirmPassword else {
                            vm.errorMessage = "Passwords do not match"
                            return
                        }
                        
                        // Validate email is not empty
                        guard !email.isEmpty else {
                            vm.errorMessage = "Email is required"
                            return
                        }
                        
                        // Validate password is not empty
                        guard !password.isEmpty else {
                            vm.errorMessage = "Password is required"
                            return
                        }
                        
                        // Call the signup function
                        vm.signup(email: email, password: password) { result in
                            switch result {
                            case .success:
                                // Signup successful, call the success callback
                                onSignUpSuccess?()
                            case .failure:
                                // Error is already set in vm.errorMessage
                                break
                            }
                        }
                    } label: {
                        HStack {
                            if vm.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(vm.isLoading ? "Signing Up..." : "Sign Up")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .background(agreeToTerms ? Color.blue : Color.blue.opacity(0.5))
                    .cornerRadius(10)
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 3)
                    .padding(.top, 4)
                    .disabled(!agreeToTerms || vm.isLoading) // must tick the checkbox and not be loading

                    // "Already have an account? Log in"
                    HStack(spacing: 4) {
                        Spacer()

                        Text("Already have an account?")
                            .font(.footnote)
                            .foregroundColor(.secondary)

                        Button("Log in") {
                            onLoginRequested?()
                        }
                        .font(.footnote.weight(.semibold))
                    }
                    .padding(.top, 4)

                }
                .padding(24)
                .background(Color.white)
                .cornerRadius(24)
                .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
                .padding(.horizontal, 24)

                Spacer()
            }
        }
    }
}

#Preview {
    SignUpView()
}
