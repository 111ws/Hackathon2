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

enum CallState {
    case idle
    case ringing
    case connected
    case ended
}

struct ContentView: View {
    @StateObject private var callManager = CallManager()
    @State private var selectedTab: Tab = .calendar
    
    enum Tab: Hashable {
        case dashboard
        case insights
        case callview
        case calendar
        case profile
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                appBackground
                TabView(selection: $selectedTab) {
                    // Dashboard
                    HomeAndMentalView()
                        .tabItem { Label("Dashboard", systemImage: "house.fill") }
                        .tag(Tab.dashboard)

                    // Insights (Health)
                    HealthView()
                        .tabItem { Label("Insights", systemImage: "heart.fill") }
                        .tag(Tab.insights)
                    StandaloneCallViewWrapper()
                       .tag(Tab.callview)
                    // Calendar
                    CalendarView()
                        .tabItem { Label("Calendar", systemImage: "calendar") }
                        .tag(Tab.calendar)

                    // Profile
                    ProfileView()
                        .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                        .tag(Tab.profile)
                }
                .toolbar(.hidden, for: .tabBar)
                .overlay(alignment: .bottom) {
                    CustomTabBar(selected: $selectedTab)
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .onAppear { }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }
    
    // MARK: - Subviews
    private var appBackground: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.8, green: 0.75, blue: 0.65),
                    Color(red: 0.9, green: 0.5, blue: 0.5)
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
}

// MARK: - Custom Tab Bar (matches design)
private struct CustomTabBar: View {
    @Binding var selected: ContentView.Tab
    
    private let barHeight: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background bar
            Rectangle()
                .fill(Color(.sRGB, red: 0.25, green: 0.25, blue: 0.25, opacity: 1))
                .frame(height: barHeight)
                .ignoresSafeArea(edges: .bottom)
            
            // Five equidistant items (center blue pill is a non-navigation button)
            HStack(alignment: .bottom, spacing: 0) {
               // tabButton(.dashboard, title: "Dashboard", systemImage: "house.fill")
               // tabButton(.insights, title: "Insights", systemImage: "heart.fill")
                centerPillButton()
               // tabButton(.calendar, title: "Calendar", systemImage: "calendar")
                //tabButton(.profile, title: "Profile", systemImage: "person.crop.circle")
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 27)
            .frame(height: barHeight)
        }
        
    }
    
   func tabButton(_ tab: ContentView.Tab, title: String, systemImage: String) -> some View {
        let isSelected = selected == tab
        return VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.white : Color.gray.opacity(0.35))
                    .frame(width: 36, height: 36)
                Image(systemName: systemImage)
                    .foregroundColor(isSelected ? Color.black : Color.white.opacity(0.9))
            }
            Text(title)
                .font(.caption2)
                .foregroundColor(isSelected ? Color.white : Color.gray.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .contentShape(Rectangle())
        .onTapGesture { withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { selected = tab } }
    }
   
    // Center blue pill button (does not navigate)
    private func centerPillButton() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26)
                .fill(Color(red: 0.35, green: 0.75, blue: 0.95))
                .frame(width: 66, height: 76)
                .offset(y: -50)
                .shadow(color: Color.black.opacity(0.35), radius: 8, x: 0, y: 3)
            // Optional icon can be added here if desired
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .contentShape(Rectangle())
    }
    }


// Temporary placeholder for Profile tab
struct ProfilePlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle")
                .foregroundStyle(.white)
                .font(.system(size: 64))
            Text("Profile coming soon")
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }
}

#Preview {
    ContentView()
}
