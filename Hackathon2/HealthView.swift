//
//  HealthView.swift
//  Hackathon2
//
//  Created by AI Assistant
//

import SwiftUI

struct HealthData {
    let heartRate: Int
    let heartRateVariability: Double
    let stressLevel: Double
    let activityLevel: String
    let sleepQuality: Double
}

struct HealthView: View {
    let healthData = HealthData(
        heartRate: 72,
        heartRateVariability: 45.2,
        stressLevel: 0.3,
        activityLevel: "moderate",
        sleepQuality: 0.8
    )
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // 标题
                    VStack(spacing: 10) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 44))
                            .foregroundColor(WarmTheme.accent)
                        
                        Text("Health Data")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(WarmTheme.primaryText)
                    }
                    .padding(.top, 40)
                    
                    // 健康数据卡片
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 20) {
                        
                        // 心率
                        HealthCard(
                            icon: "heart.fill",
                            title: "Heart Rate",
                            value: "\(healthData.heartRate)",
                            unit: "BPM",
                            color: WarmTheme.accent
                        )
                        
                        // 心率变异性
                        HealthCard(
                            icon: "waveform.path.ecg",
                            title: "HRV",
                            value: String(format: "%.1f", healthData.heartRateVariability),
                            unit: "ms",
                            color: WarmTheme.accent
                        )
                        
                        // 压力水平
                        HealthCard(
                            icon: "brain.head.profile",
                            title: "Stress Level",
                            value: String(format: "%.1f", healthData.stressLevel * 100),
                            unit: "%",
                            color: WarmTheme.accent
                        )
                        
                        // 活动水平
                        HealthCard(
                            icon: "figure.walk",
                            title: "Activity Level",
                            value: healthData.activityLevel.capitalized,
                            unit: "",
                            color: WarmTheme.accent
                        )
                        
                        // 睡眠质量
                        HealthCard(
                            icon: "moon.fill",
                            title: "Sleep Quality",
                            value: String(format: "%.0f", healthData.sleepQuality * 100),
                            unit: "%",
                            color: WarmTheme.accent
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 50)
                }
            }
        }
    }
}

struct HealthCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 15) {
            // 图标
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)
                .shadow(color: .black.opacity(0.3), radius: 3)
            
            // 标题
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            // 数值
            HStack(alignment: .bottom, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.bottom, 2)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(.ultraThinMaterial)
                .opacity(0.6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    HealthView()
}