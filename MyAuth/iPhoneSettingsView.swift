//
//  File.swift
//  MyAuth
//
//  Created by Jack Rogers on 5/25/25.
//

import SwiftUI
import UIKit
import Foundation

struct iPhoneSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @AppStorage("showProgressView") private var showProgressView: Bool = true
    @AppStorage("timerAccentColorHex") private var timerAccentColorHex: String = "#F19A37"
    @State private var timerAccentColor: Color = .orange
    @AppStorage("progressAccentColorHex") private var progressAccentColorHex: String = "#F19A37"
    @State private var progressAccentColor: Color = .orange
    
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
                            
                            NavigationLink(destination: DatePickerView()) {
                                Text("Header Date Format Picker")
                            }
                        }
                    }
                }
                
                VStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .frame(width: UIScreen.main.bounds.width * 0.65, height: 60)
                        .overlay(
                            Text("Tap to Close")
                                .foregroundStyle(.primary)
                                .font(.system(size: 22, weight: .semibold))
                        )
                        .onTapGesture {
                            dismiss()
                        }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                if let savedColor = Color(hex: timerAccentColorHex) {
                    timerAccentColor = savedColor
                }
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
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
                    Section(header: Text("Available Formats"), footer: Text("Tap the circle to choose how the time is displayed above.")) {
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

#Preview {
    iPhoneSettingsView()
//    DatePickerView()
}
