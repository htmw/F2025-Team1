//
//  LoginView.swift
//  CreditCardFraudApp
//
//  Created by Arth Patel on 11/30/25.
//

import SwiftUI

struct LoginView: View {
    @Environment(CreditCardFraudViewModel.self) var vm

    // MARK: - State
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    
    /// Optional callback so the app can move to LandingPageView
    var onLoginSuccess: (() -> Void)? = nil
    
    /// Optional callback to switch to SignUpView
    var onCreateAccountRequested: (() -> Void)? = nil

    var body: some View {
        ZStack {
            // Background light grey
            Color(.systemGray6)
                .ignoresSafeArea()

            VStack(spacing: 24) {

                // MARK: - Title + Shield Icon
                VStack(spacing: 8) {
                    Text("Credit Card Fraud Detection")
                        .font(.headline)
                        .foregroundColor(.black)

                    Image(systemName: "shield.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color.blue)
                }
                .padding(.top, 40)

                // MARK: - Center Card
                VStack(alignment: .leading, spacing: 16) {

                    // Welcome text
                    VStack(spacing: 4) {
                        Text("Welcome")
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text("Sign in to continue")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)

                    // Email field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email Address")
                            .font(.caption)
                            .foregroundColor(.gray)

                        TextField("name@example.com", text: $email)
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }

                    // Password field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Password")
                            .font(.caption)
                            .foregroundColor(.gray)

                        HStack {
                            Group {
                                if isPasswordVisible {
                                    TextField("Enter your password", text: $password)
                                } else {
                                    SecureField("Enter your password", text: $password)
                                }
                            }
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                            Button(action: {
                                isPasswordVisible.toggle()
                            }) {
                                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                    }

                    // Security note
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)

                        Text("Your credentials are encrypted securely")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    
                    if let errorMessage = vm.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .padding(.top, 4)
                    }

                    // Log In button
                    Button(action: {
                        guard !email.isEmpty else {
                            vm.errorMessage = "Email is required"
                            return
                        }
                        
                        guard !password.isEmpty else {
                            vm.errorMessage = "Password is required"
                            return
                        }
                        
                        vm.login(email: email, password: password) { result in
                            switch result {
                            case .success:
                                onLoginSuccess?()
                            case .failure:
                                // Error is already set in vm.errorMessage
                                break
                            }
                        }
                    }) {
                        HStack {
                            if vm.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            
                            Text(vm.isLoading ? "Logging In..." : "Log In")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .background(Color(.systemBlue))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .disabled(vm.isLoading)
                    .padding(.top, 4)

                    // Forgot password
                    Button(action: {
                        // TODO: Forgot password flow
                        print("Forgot Password tapped")
                    }) {
                        Text("Forgot Password")
                            .font(.footnote)
                            .foregroundColor(Color(.systemBlue))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)

                    // "Don't have an account? Create"
                    HStack(spacing: 4) {
                        Text("Don’t have an account?")
                            .font(.footnote)
                            .foregroundColor(.gray)

                        Button(action: {
                            onCreateAccountRequested?()
                        }) {
                            Text("Create")
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(.systemBlue))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)

                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(18)
                .shadow(color: Color.black.opacity(0.12),
                        radius: 20, x: 0, y: 12)

                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Preview

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        let networkInterface = NetworkInterfaceImpl(baseURL: "", adminSecret: "", userId: "")
        let repo = Repository(networkInterface: networkInterface)
        let vm = CreditCardFraudViewModel(repository: repo)
        
        Group {
            LoginView()
                .environment(vm)
                .previewDevice("iPhone 17 Pro")

            LoginView()
                .preferredColorScheme(.dark)
                .environment(vm)
                .previewDevice("iPhone 17 Pro")
        }
    }
}
