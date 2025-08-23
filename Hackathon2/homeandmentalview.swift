//
//  HomeAndMentalView.swift
//  Hackathon2
//
//  Created by AI Assistant
//

import SwiftUI

struct MentalHealthMetric {
    let title: String
    let value: Double
    let icon: String
    let color: Color
}

struct HomeAndMentalView: View {
    // 示例数据
    let mentalHealthMetrics = [
        MentalHealthMetric(title: "情绪水平", value: 0.7, icon: "face.smiling", color: .blue),
        MentalHealthMetric(title: "睡眠质量", value: 0.6, icon: "bed.double", color: .purple),
        MentalHealthMetric(title: "压力水平", value: 0.4, icon: "brain.head.profile", color: .orange),
        MentalHealthMetric(title: "专注度", value: 0.8, icon: "lightbulb", color: .green)
    ]
    
    @State private var selectedDate = Date()
    
    var body: some View {
        ZStack {
            // 背景颜色
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // 顶部导航栏
                    topNavBar()
                    
                    // 日期选择器
                    datePicker()
                    
                    // 心理健康指标卡片
                    mentalHealthCards()
                    
                    // 日记条目
                    journalEntrySection()
                    
                    // 健康建议
                    healthTipsSection()
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    // MARK: - 子视图
    
    // 顶部导航栏
    private func topNavBar() -> some View {
        HStack {
            Text("我的健康")
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            Button(action: {
                // 日历图标点击操作
            }) {
                Image(systemName: "calendar")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
        }
        .padding(.top, 8)
    }
    
    // 日期选择器
    private func datePicker() -> some View {
        HStack(spacing: 12) {
            ForEach(-2...2, id: \.self) { offset in
                let date = Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
                let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                
                Button(action: {
                    selectedDate = date
                }) {
                    VStack(spacing: 4) {
                        Text(dayOfWeek(from: date))
                            .font(.caption)
                            .foregroundColor(isSelected ? .white : .gray)
                        
                        Text(String(Calendar.current.component(.day, from: date)))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(isSelected ? .white : .primary)
                        
                        if isSelected {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 4, height: 4)
                        } else {
                            Circle()
                                .fill(Color.clear)
                                .frame(width: 4, height: 4)
                        }
                    }
                    .frame(width: 40, height: 70)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(isSelected ? Color.blue : Color.gray.opacity(0.1))
                    )
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // 心理健康指标卡片
    private func mentalHealthCards() -> some View {
        VStack(spacing: 16) {
            Text("心理健康指标")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(mentalHealthMetrics, id: \.title) { metric in
                    mentalHealthCard(metric: metric)
                }
            }
        }
    }
    
    // 单个心理健康指标卡片
    private func mentalHealthCard(metric: MentalHealthMetric) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: metric.icon)
                    .font(.title3)
                    .foregroundColor(metric.color)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(metric.color.opacity(0.1))
                    )
                
                Spacer()
                
                Text(String(format: "%.0f%%", metric.value * 100))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            Text(metric.title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ProgressView(value: metric.value)
                .progressViewStyle(LinearProgressViewStyle(tint: metric.color))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
    
    // 日记条目部分
    private func journalEntrySection() -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("今日日记")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    // 添加日记操作
                }) {
                    Text("添加")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            
            if true { // 替换为实际条件：是否有日记
                journalEntryCard()
            } else {
                emptyJournalView()
            }
        }
    }
    
    // 日记条目卡片
    private func journalEntryCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "face.smiling")
                    .font(.title3)
                    .foregroundColor(.yellow)
                
                Text("心情不错")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("14:30")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("今天是充实的一天，完成了所有计划的任务，并且有时间进行了30分钟的冥想。感觉精力充沛，心情愉快。")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
    
    // 空日记视图
    private func emptyJournalView() -> some View {
        VStack(spacing: 8) {
            Image(systemName: "square.and.pencil")
                .font(.largeTitle)
                .foregroundColor(.gray)
            
            Text("今天还没有记录日记")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: {
                // 添加日记操作
            }) {
                Text("记录一下今天的心情")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.blue))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
    
    // 健康建议部分
    private func healthTipsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("健康建议")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            healthTipCard(
                icon: "brain.head.profile",
                title: "减轻压力",
                description: "尝试进行5分钟的深呼吸练习，有助于缓解压力和焦虑。",
                color: .orange
            )
            
            healthTipCard(
                icon: "bed.double",
                title: "改善睡眠",
                description: "睡前一小时避免使用电子设备，有助于提高睡眠质量。",
                color: .purple
            )
        }
    }
    
    // 健康建议卡片
    private func healthTipCard(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
    
    // 辅助函数：获取星期几
    private func dayOfWeek(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}

// MARK: - 预览
struct HomeAndMentalView_Previews: PreviewProvider {
    static var previews: some View {
        HomeAndMentalView()
    }
}