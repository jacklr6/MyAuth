//
//  File.swift
//  MyAuth
//
//  Created by Jack Rogers on 5/25/25.
//

import SwiftUI
import SwiftData
import UIKit
import Foundation

struct iPhoneSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var accounts: [TOTPAccount]
    
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @AppStorage("showProgressView") private var showProgressView: Bool = true
    @AppStorage("timerAccentColorHex") private var timerAccentColorHex: String = "#F19A37"
    @State private var timerAccentColor: Color = .orange
    @AppStorage("progressAccentColorHex") private var progressAccentColorHex: String = "#F19A37"
    @State private var progressAccentColor: Color = .orange
    @State private var showResetWarning: Bool = false
    @State private var showDeleteWarning: Bool = false
    @State private var checkOSVersion: String = ""
    
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    var isTestFlight: Bool {
        guard let appStoreReceiptURL = Bundle.main.appStoreReceiptURL else {
            return false
        }
        return appStoreReceiptURL.lastPathComponent == "sandboxReceipt"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    List {
                        Section(header: Text("Visuals"), footer: Text("Change the appearance of the app.")) {
                            Toggle(isOn: $isDarkMode) {
                                HStack {
                                    if isDarkMode {
                                        Text("Force Light Mode")
                                    } else {
                                        Text("Force Dark Mode")
                                    }
                                    Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                                        .contentTransition(.symbolEffect(.replace))
                                }
                            }
                            
                            ColorPicker("Countdown Color", selection: $timerAccentColor)
                                .onChange(of: timerAccentColor) {
                                    if let hex = timerAccentColor.toHex {
                                        timerAccentColorHex = hex
                                    }
                                }
                            
                            Toggle(isOn: $showProgressView) {
                                HStack {
                                    Text("Show Progress Bar")
                                    Image(systemName: "slider.horizontal.3")
                                }
                            }
                            
                            if showProgressView {
                                ColorPicker("Progress Bar Color", selection: $progressAccentColor)
                                    .onChange(of: progressAccentColor) {
                                        if let hex = progressAccentColor.toHex {
                                            progressAccentColorHex = hex
                                        }
                                    }
                            }
                            
                            NavigationLink("Header Date Format Picker") {
                                DatePickerView()
                                    .navigationBarBackButtonHidden(true)
                            }
                        }
                        
                        if isTestFlight {
                            Section(header: Text("Developer"), footer: Text("Only available to beta testers in TestFlight.")) {
                                NavigationLink(destination: DeveloperView(), label: {
                                    HStack {
                                        Text("Developer Settings")
                                        Spacer()
                                        Image(systemName: "hammer.fill")
                                    }
                                })
                            }
                        }
                        
                        Section(header: Text("Your Data"), footer: Text("Remove all data in MyAuth.")) {
                            Button(action: {
                                showResetWarning = true
                            }) {
                                HStack {
                                    Text("Reset All Settings")
                                    Spacer()
                                    Image(systemName: "slider.horizontal.2.arrow.trianglehead.counterclockwise")
                                }
                            }
                            .foregroundStyle(.red)
                            .fontWeight(.semibold)
                            .alert(isPresented: $showResetWarning) {
                                Alert(title: Text("Are you sure?"),
                                      message: Text("This resets all settings back to the defaults."),
                                      primaryButton: .destructive(Text("Delete")) { isDarkMode = false; showProgressView = true; timerAccentColorHex = "#F19A37"; timerAccentColor = .orange; progressAccentColorHex = "#F19A37"; progressAccentColor = .orange; showResetWarning = false },
                                      secondaryButton: .cancel() { showResetWarning = false }
                                )
                            }
                            
                            Button(action: {
                                showDeleteWarning = true
                            }) {
                                HStack {
                                    Text("Delete All Accounts")
                                    Spacer()
                                    Image(systemName: "trash")
                                }
                            }
                            .foregroundStyle(.red)
                            .fontWeight(.semibold)
                            .alert(isPresented: $showDeleteWarning) {
                                Alert(title: Text("Are you sure?"),
                                      message: Text("Deleting all accounts will remove all saved accounts and settings."),
                                      primaryButton: .destructive(Text("Delete")) { deleteAllAccounts(); showDeleteWarning = false },
                                      secondaryButton: .cancel() { showDeleteWarning = false }
                                )
                            }
                        }
                        
                        Section {
                            HStack {
                                Spacer()
                                VStack {
                                    Text("MyAuth for \(checkOSVersion) | \(Text("\(appVersion) Beta").fontWeight(.bold).foregroundStyle(LinearGradient(gradient: Gradient(colors: [.green, .blue]), startPoint: .topLeading, endPoint: .bottomTrailing)))")
                                    Text("Jack Rogers | 2025")
                                }
                                .font(.footnote)
                                Spacer()
                            }
                            .foregroundStyle(.secondary)
                            .listRowBackground(Color.clear)
                            .ignoresSafeArea(.all)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                if let savedColor = Color(hex: timerAccentColorHex) {
                    timerAccentColor = savedColor
                }
                if UIDevice.current.userInterfaceIdiom == .pad {
                    checkOSVersion = "iPadOS"
                } else if UIDevice.current.userInterfaceIdiom == .phone {
                    checkOSVersion = "iOS"
                } else if UIDevice.current.userInterfaceIdiom == .tv {
                    checkOSVersion = "TVOS"
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.primary)
                    }
                }
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
    
    private func deleteAllAccounts() {
        for account in accounts {
            KeychainHelper.delete(forKey: account.secret)
            context.delete(account)
        }
    }
}

extension Color {
    init?(hex: String) {
        var hex = hex
        if hex.hasPrefix("#") { hex.removeFirst() }
        
        guard let int = UInt64(hex, radix: 16) else { return nil }
        
        let r, g, b, a: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
            a = 1.0
        case 8:
            r = Double((int >> 24) & 0xFF) / 255
            g = Double((int >> 16) & 0xFF) / 255
            b = Double((int >> 8) & 0xFF) / 255
            a = Double(int & 0xFF) / 255
        default:
            return nil
        }
        
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    var toHex: String? {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }

        let rgba = (
            Int(red * 255) << 24 |
            Int(green * 255) << 16 |
            Int(blue * 255) << 8 |
            Int(alpha * 255)
        )

        return String(format: "#%08X", rgba)
    }
}

struct DatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentTime = Date()
    let dateFormats: [(name: String, format: (Date) -> String)] = [
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
    @AppStorage("selectedFormat") private var selectedFormat: String = "Standard Time"
    @State private var showEditDate: Bool = false
    @State private var isLiveMode = true
    @State private var timer: Timer?
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("Available Formats"), footer: Text("Tap the circle to choose how the time is displayed above \nNote: Some time formats may not display fully on all screen types.")) {
                        ForEach(dateFormats, id: \.name) { format in
                            HStack {
                                Button(action: {
                                    selectedFormat = format.name
                                }) {
                                    Image(systemName: selectedFormat == format.name ? "checkmark" : "circle")
                                        .foregroundColor(selectedFormat == format.name ? .blue : .gray)
                                        .fontWeight(selectedFormat == format.name ? .semibold : .regular)
                                        .contentTransition(.symbolEffect(.replace))
                                }
                                .buttonStyle(.plain)
                                
                                Text(format.name)
                                Spacer()
                                Text(format.format(currentTime))
                                    .foregroundColor(.gray)
                                    .contentTransition(.numericText())
                            }
                        }
                    }
                }
            }
            .navigationTitle("Date Format")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Settings")
                                .padding(.leading, -5)
                        }
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text(currentFormattedDate())
                        .contentTransition(.numericText())
                        .animation(.default, value: currentFormattedDate())
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showEditDate = true
                    }) {
                        Text("Change Date")
                    }
                }
            }
            .animation(.default, value: currentTime)
            .sheet(isPresented: $showEditDate, content: {
                VStack {
                    Toggle("Live Date", isOn: $isLiveMode)
                        .padding()
                    
                    Divider()
                    
                    DatePicker("Choose a Date", selection: $currentTime, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.graphical)
                        .disabled(isLiveMode)
                        .opacity(isLiveMode ? 0.5 : 1.0)
                }
                .padding(.horizontal, 25)
            })
        }
        .onAppear {
            startLiveClock()
        }
        .onChange(of: isLiveMode) {
            if isLiveMode {
                startLiveClock()
            } else {
                stopLiveClock()
            }
        }
        .onDisappear {
            stopLiveClock()
        }
    }
    
    func currentFormattedDate() -> String {
        withAnimation {
            if let formatter = dateFormats.first(where: { $0.name == selectedFormat })?.format {
                return formatter(currentTime)
            }
            return currentTime.formatted()
        }
    }
    
    func startLiveClock() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            currentTime = Date()
        }
    }

    func stopLiveClock() {
        timer?.invalidate()
        timer = nil
    }
}

struct DeveloperView: View {
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section {
                        HStack {
                            Spacer()
                            VStack {
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 48))
                                    .shadow(color: Color.black.opacity(0.6), radius: 6, x: 8, y: 8)
                                Text("Test Accounts")
                                    .font(.system(size: 24, weight: .semibold))
                                Text("Follow the link below to generate a QR Code to test the app on your device!")
                            }
                            Spacer()
                        }
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 8)
                    }
                    .listSectionSpacing(10)
                    
                    Section {
                        Button {
                            if let url = URL(string: "https://stefansundin.github.io/2fa-qr/") {
                                openURL(url)
                            }
                        } label: {
                            Label("Test an Account via QR Codes", systemImage: "qrcode")
                        }
                    }
                    
                    Section {
                        HStack {
                            Spacer()
                            VStack {
                                Image(systemName: "bubble.and.pencil")
                                    .font(.system(size: 48))
                                    .padding(.top, -5)
                                    .shadow(color: Color.black.opacity(0.6), radius: 6, x: 8, y: 8)
                                Text("Submit Feedback")
                                    .font(.system(size: 24, weight: .semibold))
                                Text("Follow the link below to submit feedback to my GitHub Repo or in the TestFlight App!")
                            }
                            Spacer()
                        }
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 8)
                    }
                    
                    Section {
                        Button {
                            if let url = URL(string: "https://github.com/jacklr6/") {
                                openURL(url)
                            }
                        } label: {
                            Label("Submit Feedback via GitHub", systemImage: "network")
                        }
                    }
                    .listSectionSpacing(10)
                    
                    Section {
                        Button {
                            if let url = URL(string: "itms-beta://") {
                                openURL(url)
                            }
                        } label: {
                            Label("Submit Feedback via TestFlight", systemImage: "arrow.turn.up.right")
                        }
                    }
                    .listSectionSpacing(10)
                }
            }
            .navigationTitle(Text("Developer"))
        }
    }
}

#Preview {
    iPhoneSettingsView()
//    DatePickerView()
//    DeveloperView()
}
