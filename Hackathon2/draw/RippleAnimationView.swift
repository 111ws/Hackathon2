//
//  RippleAnimationView.swift
//  Hackathon2
//
//  Created by 陆氏干饭王 on 03-08-2025.
//


//
//  RippleAnimationView.swift
//  Hackathon
//
//  Created by 陆氏干饭王 on 01-08-2025.
//

import SwiftUI

// 基础涟漪动画（更新为现代发光效果）
struct RippleAnimationView: View {
    @State private var animate = false
    @State private var pulse = false
    
    var body: some View {
        ZStack {
            Color.clear // 透明背景
            
            // 外层光环效果（类似React Native的aura）
            ForEach(0..<3) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.4),
                                Color.blue.opacity(0.2),
                                Color.blue.opacity(0)
                            ]),
                            center: .center,
                            startRadius: 20,
                            endRadius: 100
                        )
                    )
                    .frame(width: 80, height: 80)
                    .scaleEffect(animate ? 2.5 : 1)
                    .opacity(animate ? 0 : 0.6)
                    .animation(
                        Animation.easeOut(duration: 2.0)
                            .delay(Double(index) * 0.5)
                            .repeatForever(autoreverses: false),
                        value: animate
                    )
            }
            
            // 内层涟漪波纹
            ForEach(0..<2) { index in
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.8),
                                Color.blue.opacity(0.4)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: animate ? 180 : 60, height: animate ? 180 : 60)
                    .opacity(animate ? 0 : 0.9)
                    .animation(
                        Animation.easeOut(duration: 2.2)
                            .delay(Double(index) * 0.7)
                            .repeatForever(autoreverses: false),
                        value: animate
                    )
            }
            
            // 中心发光圆点（类似React Native的orb）
            ZStack {
                // 外层光晕
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.5),
                                Color.blue.opacity(0.2),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 25,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)
                    .scaleEffect(pulse ? 1.1 : 1)
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                        value: pulse
                    )
                
                // 中心圆点
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.1),
                                Color.blue
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .shadow(color: Color.blue.opacity(0.8), radius: 15, x: 0, y: 0)
                
                // 内层高光
                Circle()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 20, height: 20)
                    .offset(x: -8, y: -8)
                    .blur(radius: 2)
            }
        }
        .onAppear {
            animate = true
            pulse = true
        }
    }
}

// 高级渐变涟漪动画（更新为更现代的样式）
struct AdvancedGradientRippleAnimation: View {
    @State private var animate = false
    @State private var glow = false
    let color: Color
    let maxSize: CGFloat
    let duration: Double
    let delay: Double
    let count: Int
    let centerColor: Color
    let edgeColor: Color
    
    init(
        color: Color = .blue,
        maxSize: CGFloat = 200,
        duration: Double = 2.5,
        delay: Double = 0.4,
        count: Int = 3,
        centerColor: Color = .blue,
        edgeColor: Color = .clear
    ) {
        self.color = color
        self.maxSize = maxSize
        self.duration = duration
        self.delay = delay
        self.count = count
        self.centerColor = centerColor
        self.edgeColor = edgeColor
    }
    
    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let center = CGPoint(x: size / 2, y: size / 2)
            let base: CGFloat = 60.0
            let scale = maxSize / base
            
            ZStack {
                Color.clear
                
                // 多层光环效果
                ForEach(0..<count, id: \.self) { index in
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    centerColor.opacity(0.6),
                                    centerColor.opacity(0.3),
                                    edgeColor
                                ]),
                                center: .center,
                                startRadius: 15,
                                endRadius: maxSize / 2
                            )
                        )
                        .frame(width: base, height: base)
                        .position(center)
                        .scaleEffect(animate ? scale : 1, anchor: .center)
                        .opacity(animate ? 0 : 0.8)
                        .animation(
                            Animation.easeOut(duration: duration)
                                .delay(Double(index) * delay)
                                .repeatForever(autoreverses: false),
                            value: animate
                        )
                        .overlay(
                            Circle()
                                .stroke(
                                    centerColor.opacity(0.4),
                                    lineWidth: 1
                                )
                                .frame(width: base, height: base)
                                .position(center)
                                .scaleEffect(animate ? scale : 1, anchor: .center)
                                .opacity(animate ? 0 : 0.6)
                                .animation(
                                    Animation.easeOut(duration: duration)
                                        .delay(Double(index) * delay + 0.2)
                                        .repeatForever(autoreverses: false),
                                    value: animate
                                )
                        )
                }
                
                // 中心发光圆点（带发光效果）
                ZStack {
                    // 外层光晕
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    centerColor.opacity(0.8),
                                    centerColor.opacity(0.4),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 35
                            )
                        )
                        .scaleEffect(glow ? 1.2 : 1)
                        .opacity(glow ? 0.6 : 0.8)
                        .animation(
                            Animation.easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: true),
                            value: glow
                        )
                    
                    // 主圆点
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    centerColor.opacity(1.0),
                                    centerColor.opacity(0.7),
                                    centerColor.opacity(0.3)
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 25
                            )
                        )
                        .shadow(color: centerColor.opacity(0.7), radius: 20, x: 0, y: 0)
                    
                    // 内层高光
                    Circle()
                        .fill(Color.white.opacity(0.4))
                        .frame(width: 20, height: 20)
                        .blur(radius: 3)
                        .offset(x: -5, y: -5)
                }
                .frame(width: size * 0.5, height: size * 0.5)
                .position(center)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .center)
            .compositingGroup()
            .drawingGroup()
            .allowsHitTesting(false)
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear {
            animate = true
            glow = true
        }
    }
}

// 保持向后兼容的简单版本
struct CustomRippleAnimation: View {
    @State private var animate = false
    let color: Color
    let maxSize: CGFloat
    let duration: Double
    let delay: Double
    let count: Int
    
    init(color: Color = .blue, maxSize: CGFloat = 200, duration: Double = 2.5, delay: Double = 0.4, count: Int = 3) {
        self.color = color
        self.maxSize = maxSize
        self.duration = duration
        self.delay = delay
        self.count = count
    }
    
    var body: some View {
        AdvancedGradientRippleAnimation(
            color: color,
            maxSize: maxSize,
            duration: duration,
            delay: delay,
            count: count,
            centerColor: color,
            edgeColor: .clear
        )
    }
}

// 使用示例和预览（更新为更现代的展示）
struct RippleAnimationPreview: View {
    var body: some View {
        VStack(spacing: 40) {
            // 标准蓝色涟漪（更新版本）
            Text("现代发光涟漪")
                .font(.caption)
                .foregroundColor(.white)
            RippleAnimationView()
                .frame(width: 200, height: 200)
            
            // 高级渐变涟漪 - 蓝色
            Text("海洋蓝发光")
                .font(.caption)
                .foregroundColor(.white)
            AdvancedGradientRippleAnimation(
                color: .blue,
                maxSize: 180,
                centerColor: Color(red: 0.2, green: 0.5, blue: 0.9),
                edgeColor: .clear
            )
            .frame(width: 200, height: 200)
            
            // 高级渐变涟漪 - 紫色
            Text("暮光紫发光")
                .font(.caption)
                .foregroundColor(.white)
            AdvancedGradientRippleAnimation(
                color: .purple,
                maxSize: 180,
                centerColor: .purple,
                edgeColor: Color.purple.opacity(0.2)
            )
            .frame(width: 200, height: 200)
            
            Spacer()
        }
        .padding()
        .background(Color.black.opacity(0.8))
    }
}

#Preview {
    RippleAnimationPreview()
}
