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
    @State private var selectedTab: Tab = .home
    
    enum Tab: Hashable {
        case home
        case call
        case camera
        case health
    }
    
    var body: some View {
        ZStack {
            appBackground
            
            TabView(selection: $selectedTab) {
                // Home
                IdleView(callManager: callManager)
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                    .tag(Tab.home)
                
                // Call
                callTabContent()
                    .tabItem {
                        Label("Call", systemImage: "phone.fill")
                    }
                    .tag(Tab.call)
                
                // Camera preview
                SimpleCameraView()
                    .tabItem {
                        Label("Camera", systemImage: "camera.fill")
                    }
                    .tag(Tab.camera)
                
                // Calendar
                CalendarView()
                    .tabItem {
                        Label("Calendar", systemImage: "calendar")
                    }
                    .tag(Tab.health)
            }
        }
        .onAppear {
            // Demo: auto-trigger an incoming call after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                callManager.startCall()
            }
        }
        .onChange(of: callManager.callState) { newState in
            // 当来电响铃或已连接时，自动切换到通话页；结束后返回首页
            switch newState {
            case .ringing, .connected:
                selectedTab = .call
            case .ended:
                selectedTab = .home
            case .idle:
                break
            }
        }
    }
    
    // MARK: - Subviews
    private var appBackground: some View {
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
    }
    
    @ViewBuilder
    private func callTabContent() -> some View {
        if callManager.callState == .idle {
            // 在未通话时展示一个进入通话的入口
            VStack(spacing: 20) {
                Image(systemName: "phone.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.white)
                Text("Ready to call")
                    .foregroundColor(.white)
                    .font(.title3)
                Button {
                    // 立即触发来电（用于本地演示）
                    callManager.startCall()
                } label: {
                    Label("Start Call", systemImage: "phone.arrow.up.right")
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding()
        } else {
            StandaloneCallViewWrapper()
        }
    }
}

#Preview {
    ContentView()
}
