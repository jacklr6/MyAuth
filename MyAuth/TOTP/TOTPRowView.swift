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
    
    @AppStorage("isAppFocused") private var isAppFocused: Bool = true
    @AppStorage("showProgressView") private var showProgressView: Bool = true
    @AppStorage("timerAccentColorHex") private var timerAccentColorHex: String = "#F19A37"
    @AppStorage("progressAccentColorHex") private var progressAccentColorHex: String = "#F19A37"
    @AppStorage("showCountdown") private var showCountdown: Bool = true
    
    var progress: CGFloat {
        CGFloat(viewModel.timeRemaining) / CGFloat(viewModel.account.seconds)
    }

    var body: some View {
        VStack {
#if os(iOS)
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
                        .blur(radius: isAppFocused ? 0 : 10)
                    
                    HStack {
                        Text("Expires in")
                        Text("\(viewModel.timeRemaining)s")
                            .padding(.leading, -5)
                            .contentTransition(.numericText())
                    }
                    .blur(radius: isAppFocused ? 0 : 10)
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
                            .foregroundColor(isAppFocused ? Color(hex: progressAccentColorHex) : Color.clear)
                            .animation(.bouncy(duration: 0.3, extraBounce: 0.2), value: progress)
                    }
                }
                .frame(height: 5)
            }
#endif

#if os(watchOS)
            VStack {
                HStack {
                    Text(viewModel.account.issuer)
                        .font(.headline)
                    
                    Text(viewModel.account.accountName)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Divider()
                
                HStack {
                    Text(viewModel.code)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .contentTransition(.numericText())
                    
                    if showCountdown == true {
                        Spacer()
                        
                        Text("\(viewModel.timeRemaining)s")
                            .padding(.leading, -5)
                            .contentTransition(.numericText())
                            .font(.footnote)
                            .foregroundColor(Color.green)
                    }
                }
                .animation(.default, value: viewModel.code)
                .animation(.default, value: viewModel.timeRemaining)
            }
#endif
            
        }
        .padding(.vertical, 5)
    }
}
