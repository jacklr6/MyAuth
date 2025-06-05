//
//  SwiftUIView.swift
//  WatchMyAuth Watch App
//
//  Created by Jack Rogers on 6/3/25.
//

import SwiftUI

struct WatchSettingsView: View {
    @AppStorage("showCountdown") private var showCountdown: Bool = true
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section(header: Text("Visuals"), footer: Text("Change the appearance of the app.")) {
                        Toggle("Show Countdown", isOn: $showCountdown)
                        
                        Button(action: {
                            
                        }) {
                            HStack {
                                Text("Delete All Accounts")
                                Spacer()
                                Image(systemName: "trash")
                            }
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(Text("Settings"))
        }
    }
}

#Preview {
    WatchSettingsView()
}
