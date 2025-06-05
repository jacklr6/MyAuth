//
//  EditAccount.swift
//  MyAuth
//
//  Created by Jack Rogers on 5/19/25.
//

import SwiftUI
import LocalAuthentication
import Security

struct EditAccount: View {
    @Bindable var account: TOTPAccount
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("isAppFocused") private var isAppFocused: Bool = true
    
    @State private var isUnlocked: Bool = false
    let availableIcons = ["GitHub", "Google"]
    @State private var iconAvailable: Bool = false
    @State private var animateIcon: Bool = false

    var body: some View {
        NavigationStack {
            VStack {
                VStack {
                    if iconAvailable == true {
                        Image("\(account.issuer)")
                            .resizable()
                            .frame(width: 100, height: 100)
                    } else {
                        Image(systemName: animateIcon ? "photo.badge.exclamationmark" : "photo.badge.checkmark")
                            .font(.system(size: 80))
                            .frame(width: 100, height: 100)
                            .contentTransition(.symbolEffect)
                            .symbolRenderingMode(animateIcon ? .multicolor : .monochrome)
                    }
                    
                    Text("\(account.issuer)")
                        .font(.system(size: 55, weight: .semibold))
                    
                    Text("\(account.accountName)")
                }
                .multilineTextAlignment(.center)
                .frame(width: UIScreen.main.bounds.width, height: 240)
                .background(Color(.systemGray6))
                
                VStack {
                    HStack {
                        Text("Time Before Refresh:")
                            .frame(width: 100)
                        
                        Divider()
                            .frame(height: 55)
                        
                        VStack {
                            Slider(value: $account.seconds, in: 5...90, step: 5) {
                                Text("Seconds")
                            } minimumValueLabel: {
                                Text("5")
                            } maximumValueLabel: {
                                Text("90")
                            }
                            
                            Text("\(String(format: "%.0f" ,account.seconds)) Seconds")
                                .contentTransition(.numericText())
                        }
                        .padding(.leading, 5)
                    }
                    
                    HStack {
                        VStack {
                            Text("Secret Code:")
                            Text("*Keep Private!*")
                                .font(.footnote)
                        }
                        .frame(width: 100)
                        
                        Divider()
                            .frame(height: 55)
                        
                        Text("\(account.secret)")
                            .monospaced()
                            .blur(radius: isAppFocused ? 0 : 10)
                            .blur(radius: isUnlocked ? 0 : 10)
                            .frame(maxWidth: .infinity)
                            .onTapGesture {
                                if isUnlocked == false {
                                    authenticateUser()
                                } else {
                                    isUnlocked = false
                                }
                            }
                            .onDisappear {
                                isUnlocked = false
                            }
                    }
                }
                .frame(width: UIScreen.main.bounds.width * 0.85)
                .animation(.default, value: account.seconds)
                
                Spacer()
            }
        }
        .onAppear {
            checkIconAvailability()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                animateIcon = true
            })
        }
        .navigationTitle("Edit Account")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    try? context.save()
                    dismiss()
                }
            }
        }
    }
    
    func checkIconAvailability() {
        if availableIcons.contains(account.issuer) {
            iconAvailable = true
        }
    }
    
    func authenticateUser() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Unlock Your Account") { success, authenticationError in
                if success {
                    DispatchQueue.main.async {
                        isUnlocked = true
                    }
                } else {
                    isUnlocked = false
                }
            }
        }
    }
}

#Preview {
    EditAccount(account: TOTPAccount(issuer: "Apple", accountName: "user@example.com", secret: "JBSWY3DPEHPK3PXP", seconds: 30))
}
