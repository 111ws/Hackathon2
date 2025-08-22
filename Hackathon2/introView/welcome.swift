//
//  welcome.swift
//  Aura calling
//
//  Created by Macbook pro on 2025/8/20.
//

import SwiftUI


// 空闲状态视图
struct Welcome: View {
    @State private var navigateToVoiceSelection = false
    @State private var glow = false
    
    var body: some View {
        NavigationStack {
            ZStack{
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 1.0, green: 0.72, blue: 0.50),
                        Color(red: 0.84, green: 0.71, blue: 0.62),
                        Color(red: 1.0, green: 0.76, blue: 0.58)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer().frame(height:200)
                  
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 150, height: 150)
                        .overlay(
                            AdvancedGradientRippleAnimation(
                                color: Color.white,
                                maxSize: 180,
                                centerColor: Color.white,
                                edgeColor: .clear
                            )
                            .frame(width: 300, height: 300)
                        )
                    Spacer()                        .frame(height: 250)

                    
                    // 底部文字按钮
                    Button(action: {
                        navigateToVoiceSelection = true
                    }) {
                        ZStack(){
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    WarmTheme.cream.opacity(0.55),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: glow ? 46 : 36
                            )
                            .blur(radius: glow ? 16 : 10)
                            Text("Hi,Aura")
                                .font(.title2.weight(.bold))
                                .foregroundColor(WarmTheme.cream)
                                .shadow(color: WarmTheme.cream.opacity(0.35), radius: glow ? 26 : 14, x: 0, y: 0)
                                .shadow(color: WarmTheme.accent.opacity(0.15), radius: glow ? 40 : 22, x: 0, y: 0)
                                .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: glow)
                        }
                        .navigationDestination(isPresented: $navigateToVoiceSelection) {
                            VoiceSelectionView()
                        }
                    }
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    Welcome()
}
