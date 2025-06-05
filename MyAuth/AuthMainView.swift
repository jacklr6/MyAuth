//
//  ContentView.swift
//  MyAuth
//
//  Created by Jack Rogers on 5/18/25.
//

import SwiftUI
import SwiftData

struct AuthMainView: View {
    @Environment(\.modelContext) private var context
    @Query private var accounts: [TOTPAccount]
    @State var viewModels: [TOTPAccountViewModel] = []
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    
    @AppStorage("selectedFormat") private var selectedFormat: String = "Standard Time"
    var formattedDate: String {
        let formats: [(name: String, format: (Date) -> String)] = [
            ("Abbreviated Date", { $0.formatted(date: .abbreviated, time: .omitted) }),
            ("Long Date", { $0.formatted(date: .long, time: .omitted) }),
            ("Full Date", { $0.formatted(date: .complete, time: .omitted) }),
            ("Numeric", { $0.formatted(date: .numeric, time: .omitted) }),
            ("Time & Zone", { $0.formatted(date: .omitted, time: .complete) }),
            ("Long Time", { $0.formatted(date: .omitted, time: .standard) }),
            ("Standard Time", { $0.formatted(date: .omitted, time: .shortened) }),
            ("Day of Year", { $0.formatted(.dateTime.dayOfYear()) }),
            ("Week of Year", { $0.formatted(.dateTime.week()) }),
            ("Weekday", { $0.formatted(.dateTime.weekday()) }),
            ("Era", { $0.formatted(.dateTime.era()) }),
            ("Quarter", { $0.formatted(.dateTime.quarter()) })
        ]
        
        let format = formats.first(where: { $0.name == selectedFormat })?.format
        return format?(Date()) ?? Date().formatted()
    }
    
    @State private var isPresentingScanner = false
    @State private var currentTime = Date()
    @State private var settingsAlert: Bool = false
    @State private var profileAlert: Bool = false
    @State private var showNoAccount: Double = 0
    @State private var showMoreAccountInfo: Double = 0
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModels.isEmpty {
                    VStack {
                        ZStack {
                            Image(systemName: "seal.fill")
                                .font(.system(size: 56))
                                .symbolEffect(.rotate.clockwise.byLayer, options: .speed(0.2))
                            Image(systemName: "checkmark")
                                .font(.system(size: 27, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        Text("No Accounts Found")
                            .font(.title)
                            .fontWeight(.semibold)
                        Text("Tap the plus in the top right hand corner to add an account!")
                    }
                    .frame(width: UIScreen.main.bounds.width * 0.8)
                    .multilineTextAlignment(.center)
                    .offset(y: -40)
                    .opacity(showNoAccount)
                    .animation(.easeInOut(duration: 0.6), value: showNoAccount)
                } else {
                    List {
                        ForEach(viewModels) { viewModel in
                            NavigationLink(destination: EditAccount(account: viewModel.account)) {
                                TOTPRowView(viewModel: viewModel)
                                    .transition(.opacity)
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    context.delete(viewModel.account)
                                    try? context.save()
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        
                        if showMoreAccountInfo == 1 {
                            Section {
                                HStack {
                                    Spacer()
                                    VStack {
                                        Image(systemName: "info.circle")
                                            .font(.system(size: 32))
                                            .padding(1)
                                        Text("See More Info")
                                            .font(.headline)
                                        Text("Tap on an account to see more information about that account.")
                                    }
                                    .multilineTextAlignment(.center)
                                    .padding(7)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: accounts)
                }
            }
            .onAppear {
                createViewModels()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    withAnimation() {
                        showNoAccount = 1
                    }
                })
            }
            .onChange(of: accounts) { _, _ in
                createViewModels()
            }
            .navigationTitle("MyAuth")
            .sheet(isPresented: $settingsAlert) { iPhoneSettingsView() }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack {
                        Button(action: {
                            profileAlert.toggle()
                        }) {
                            Image(systemName: "person.circle")
                        }
                    }
                    .font(.system(size: 16))
                    .padding(7)
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
                
                ToolbarItem(placement: .principal) {
                    HStack {
                        Text("\(formattedDate)")
                            .contentTransition(.numericText())
                    }
                    .animation(.default, value: currentTime)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        Button(action: {
                            isPresentingScanner = true
                        }) {
                            Image(systemName: "plus")
                        }
                        .sheet(isPresented: $isPresentingScanner) {
                            QRScannerView { result in
                                isPresentingScanner = false
                                withAnimation {
                                    handleScannedURL(result)
                                }
                            }
                        }
                        .frame(width: 40)
                        
                        Button(action: {
                            settingsAlert.toggle()
                        }) {
                            Image(systemName: "gearshape.fill")
                        }
                    }
                    .font(.system(size: 16))
                    .padding(7)
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
            }
        }
        .alert("Profile", isPresented: $profileAlert) {
            Button("Ok", role: .cancel) { profileAlert = false }
        } message: {
            Text("Profile will come in a future release.")
        }
        .onAppear {
            startTimer()
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
    
    func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            currentTime = Date()
        }
    }
    
    func handleScannedURL(_ urlString: String) {
        guard let url = URLComponents(string: urlString),
              url.scheme == "otpauth",
              url.host == "totp",
              let label = url.path.removingPercentEncoding?.dropFirst(),
              let secret = url.queryItems?.first(where: { $0.name == "secret" })?.value else {
            print("❌ Invalid otpauth URL")
            return
        }

        let components = label.split(separator: ":")
        let issuer = url.queryItems?.first(where: { $0.name == "issuer" })?.value ?? String(components.first ?? "Unknown")
        let accountName = components.count > 1 ? String(components[1]) : String(components.first ?? "Account")
        
        let keychainKey = secret
        KeychainHelper.save(secret, forKey: keychainKey)
        
        let account = TOTPAccount(issuer: issuer, accountName: accountName, secret: keychainKey, seconds: 30)
        context.insert(account)
    }
    
    private func createViewModels() {
        viewModels = accounts.map { TOTPAccountViewModel(account: $0) }
    }
}

#Preview {
    AuthMainView()
        .modelContainer(previewContainer)
}

let previewContainer: ModelContainer = {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TOTPAccount.self, configurations: config)
    
    Task { @MainActor in
        let sampleData = [
            TOTPAccount(issuer: "GitHub", accountName: "user@example.com", secret: "JBSWY3DPEHPK3PXP", seconds: 30),
            TOTPAccount(issuer: "Google", accountName: "user@gmail.com", secret: "JBSWY3DPEHPK3PXP", seconds: 30)
        ]
        for account in sampleData {
            container.mainContext.insert(account)
        }
    }

    return container
}()

