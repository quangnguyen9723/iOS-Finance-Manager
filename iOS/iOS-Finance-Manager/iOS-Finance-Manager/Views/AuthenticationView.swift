//
//  AuthenticationView.swift
//  iOS-Finance-Manager
//
//  Created by Quang Nguyen, Aiden Le, Anh Phan on 4/14/25.
//

import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isSignUp: Bool = false
    @State private var isLoading: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(isSignUp ? "Sign Up" : "Sign In")
                    .font(.largeTitle)
                    .bold()
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                if let errorMessage = authVM.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
                Button(action: {
                    Task {
                        isLoading = true
                        if isSignUp {
                            await authVM.signup(email: email, password: password)
                        } else {
                            await authVM.login(email: email, password: password)
                        }
                        isLoading = false
                    }
                }) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text(isSignUp ? "Sign Up" : "Sign In")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                Button(action: { isSignUp.toggle() }) {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding()
        }
    }
}
