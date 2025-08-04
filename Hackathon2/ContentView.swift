//
//  ContentView.swift
//  Hackathon
//
//  Created by 陆氏干饭王 on 01-08-2025.
//

import SwiftUI
import AVFoundation
import CallKit
import PushKit

// 通话状态枚举
enum CallState {
    case idle
    case ringing
    case connected
    case ended
}

struct ContentView: View {
    @StateObject private var callManager = CallManager()
    
    var body: some View {
        ZStack {
            // 背景渐变
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.98, green: 0.75, blue: 0.65),
                        Color(red: 0.99, green: 0.85, blue: 0.55)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.4)
              
            }
            .ignoresSafeArea()
            
            VStack {
                if callManager.callState == .idle {
                    IdleView(callManager: callManager)
                } else {
                    CallView(callManager: callManager)
                }
            }
        }
        .onAppear {
            // 应用启动后设置1分钟后的来电
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                callManager.startCall()
            }
        }
    }
}

#Preview {
    ContentView()
}
