//
//  HealthView.swift
//  Hackathon2
//
//  Created by AI Assistant
//

import SwiftUI

// Local palette for Insights screen (light theme)
private struct InsightsPalette {
    static let title = Color.black
    static let body = Color.gray
    static let cardBackground = Color.white
    static let shadow = Color.black.opacity(0.08)
    static let accentOrange = Color(red: 1.0, green: 0.60, blue: 0.35)
    static let accentPurple = Color(red: 0.60, green: 0.48, blue: 0.98)
    static let dotActive = Color.black.opacity(0.6)
    static let dotInactive = Color.black.opacity(0.15)
}

struct HealthData {
    let heartRate: Int
    let heartRateVariability: Double
    let stressLevel: Double
    let activityLevel: String
    let sleepQuality: Double
}

struct HealthView: View {
    @State private var topCardIndex: Int = 0
    
    // Static sample data just for layout
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
                VStack(spacing: 22) {
                    header()
                    topCarousel()
                    pageDots(count: 5, selected: topCardIndex)
                        .padding(.top, -2)
                    achievementsHeader()
                    achievementsGrid()
                        .padding(.bottom, 28)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
    }
}

// MARK: - Sections

private extension HealthView {
    func header() -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(white: 0.95))
                .frame(width: 34, height: 34)
                .overlay(Image(systemName: "chevron.left").foregroundColor(.black))
            Text("My Insights")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(InsightsPalette.title)
            Spacer()
        }
    }
    
    func topCarousel() -> some View {
        let cardHeight: CGFloat = 170
        return TabView(selection: $topCardIndex) {
            ForEach(0..<5, id: \.self) { idx in
                HStack(spacing: 16) {
                    StressCard()
                        .frame(maxWidth: .infinity)
                        .frame(height: cardHeight)
                    SleepCard()
                        .frame(maxWidth: .infinity)
                        .frame(height: cardHeight)
                }
                .frame(height: cardHeight)
                .tag(idx)
                .padding(.horizontal, 0)
            }
        }
        .frame(height: cardHeight)
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
    
    func pageDots(count: Int, selected: Int) -> some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                Circle()
                    .fill(i == selected ? InsightsPalette.dotActive : InsightsPalette.dotInactive)
                    .frame(width: 6, height: 6)
            }
        }
    }
    
    func achievementsHeader() -> some View {
        HStack {
            Text("My Achievements")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(InsightsPalette.title)
            Spacer()
        }
        .padding(.top, 8)
    }
    
    func achievementsGrid() -> some View {
        let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]
        return LazyVGrid(columns: columns, spacing: 14) {
            AchievementCard(
                value: "2.4x",
                title: "Happier",
                subtitle: "16% vs last week",
                icon: "face.smiling",
                accent: .yellow,
                trend: .up,
                iconColor: .yellow
            )
            AchievementCard(
                value: "181%",
                title: "Stress Improvements",
                subtitle: "16% vs last week",
                icon: "hand.thumbsup.fill",
                accent: Color.purple.opacity(0.9),
                trend: .up,
                iconColor: InsightsPalette.accentPurple
            )
            AchievementCard(
                value: "0.9x",
                title: "Less Depressive",
                subtitle: "-2.4x vs last week",
                icon: "heart.fill",
                accent: .gray,
                trend: .down,
                iconColor: InsightsPalette.accentOrange

            )
            AchievementCard(
                value: "2",
                title: "Aura pledge streaks",
                subtitle: "keep going!",
                icon: "leaf.fill",
                accent: .green,
                trend: .none,
                iconColor: .green
            )
        }
    }
}

// MARK: - Components

private struct AchievementCard: View {
    enum Trend { case up, down, none }
    let value: String
    let title: String
    let subtitle: String
    let icon: String
    let accent: Color
    let trend: Trend
    var iconColor: Color = .gray
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(InsightsPalette.title)
                Spacer()
                Circle()
                    .fill(Color(white: 0.95))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(iconColor)
                    )
            }
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(InsightsPalette.title)
            HStack(spacing: 6) {
                trendIcon
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(InsightsPalette.body)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(InsightsPalette.cardBackground)
        )
        .shadow(color: InsightsPalette.shadow, radius: 10, x: 0, y: 6)
    }
    
    private var trendIcon: some View {
        switch trend {
        case .up:
            return AnyView(Image(systemName: "arrow.up.right").foregroundColor(.green).font(.system(size: 11, weight: .bold)))
        case .down:
            return AnyView(Image(systemName: "arrow.down.right").foregroundColor(.red).font(.system(size: 11, weight: .bold)))
        case .none:
            return AnyView(Image(systemName: "checkmark.circle.fill").foregroundColor(.green).font(.system(size: 11, weight: .bold)))
        }
    }
}

private struct StressCard: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(LinearGradient(gradient: Gradient(colors: [InsightsPalette.accentOrange, Color.orange.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing))
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Circle().fill(Color.white.opacity(0.25)).frame(width: 14, height: 14)
                    Text("Stress Level")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
                Text("Level 3")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(0..<12) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 8, height: CGFloat([8,14,10,22,30,18,24,34,20,26,12,8][i]))
                    }
                }
            }
            .padding(18)
        }
    }
}

private struct SleepCard: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(LinearGradient(gradient: Gradient(colors: [InsightsPalette.accentPurple, Color.purple.opacity(0.85)]), startPoint: .topLeading, endPoint: .bottomTrailing))
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Circle().fill(Color.white.opacity(0.5)).frame(width: 14, height: 14)
                    Text("Sleep Quality")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
                Text("Good")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                // Dot grid
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(0..<5) { r in
                        HStack(spacing: 6) {
                            ForEach(0..<6) { c in
                                Circle()
                                    .fill(Color.white.opacity((r == 2 && c >= 2 && c <= 4) ? 1.0 : 0.45))
                                    .frame(width: 10, height: 10)
                            }
                        }
                    }
                }
            }
            .padding(18)
        }
    }
}

#Preview {
    HealthView()
}
