//
//  remoteView.swift
//  Hackathon2
//
//  Created by AI Assistant
//

import SwiftUI

struct remoteView: View {
    var body: some View {
        ZStack {
            // 背景颜色 - 来自ContentView.swift L28-39
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
                
                Color.black.opacity(0.1)
            }
            .ignoresSafeArea()
            
            // 中间的涟漪波纹动画
            VStack {
//                Spacer()
//                    .frame(height: -UIScreen.main.bounds.height   )
                AdvancedGradientRippleAnimation(
                    color: .white,
                    maxSize: 180,
                    centerColor: .white,
                    edgeColor: Color.white.opacity(0.2)
                )
                .frame(width: 4000, height: 400)
                
                Spacer()
            }
        }
    }
}

#Preview {
    remoteView()
}
