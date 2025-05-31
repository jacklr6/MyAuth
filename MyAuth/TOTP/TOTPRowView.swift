//
//  TOTPRowView.swift
//  MyAuth
//
//  Created by Jack Rogers on 5/18/25.
//

import SwiftUI
import SwiftData

struct TOTPRowView: View {
    @Environment(\.modelContext) private var context
    @ObservedObject var viewModel: TOTPAccountViewModel
    @State private var currentTime = Date()
    
    @AppStorage("showProgressView") private var showProgressView: Bool = true
    @AppStorage("timerAccentColorHex") private var timerAccentColorHex: String = "#F19A37"
    @AppStorage("progressAccentColorHex") private var progressAccentColorHex: String = "#F19A37"
    
    var progress: CGFloat {
        CGFloat(viewModel.timeRemaining) / CGFloat(viewModel.account.seconds)
    }

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(viewModel.account.issuer)
                        .font(.headline)
                    Text(viewModel.account.accountName)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(viewModel.code)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .contentTransition(.numericText())
                    
                    HStack {
                        Text("Expires in")
                        Text("\(viewModel.timeRemaining)s")
                            .padding(.leading, -5)
                            .contentTransition(.numericText())
                    }
                    .font(.caption)
                    .foregroundColor(Color(hex: timerAccentColorHex))
                }
                .animation(.default, value: viewModel.code)
                .animation(.default, value: viewModel.timeRemaining)
            }
            
            if showProgressView {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .frame(height: 5)
                            .foregroundColor(.gray.opacity(0.2))
                        
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .frame(width: geometry.size.width * progress, height: 5)
                            .foregroundColor(Color(hex: progressAccentColorHex))
                            .animation(.bouncy(duration: 0.3, extraBounce: 0.2), value: progress)
                    }
                }
                .frame(height: 5)
            }
        }
        .padding(.vertical, 5)
    }
}

#Preview {
    AuthMainView()
        .modelContainer(previewContainer1)
}

let previewContainer1: ModelContainer = {
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
