////
////  HomeAndMentalView.swift
////  Hackathon2
////
////  Created by AI Assistant
////
//
//import SwiftUI
//
//// 扩展Color以支持十六进制颜色代码
//extension Color {
//    init(hex: String) {
//        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
//        var int: UInt64 = 0
//        Scanner(string: hex).scanHexInt64(&int)
//        let a, r, g, b: UInt64
//        switch hex.count {
//        case 3: // RGB (12-bit)
//            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
//        case 6: // RGB (24-bit)
//            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
//        case 8: // ARGB (32-bit)
//            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
//        default:
//            (a, r, g, b) = (1, 1, 1, 0)
//        }
//
//        self.init(
//            .sRGB,
//            red: Double(r) / 255,
//            green: Double(g) / 255,
//            blue:  Double(b) / 255,
//            opacity: Double(a) / 255
//        )
//    }
//}
//
//struct JournalEntry: Identifiable {
//    let id = UUID()
//    let icon: String
//    let iconColor: Color
//    let title: String
//    let content: String
//    let time: String?
//}
//
//struct HomeAndMentalView: View {
//    // 背景颜色 - 米色背景
//    private let backgroundColor = Color(hex: "FDF6F0")
//    private let textColor = Color(hex: "5D4037") // 棕色文字
//    private let accentColor = Color(hex: "8BC34A") // 绿色强调色
//    
//    // 日期数据
//    private let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
//    private let dates = ["25", "26", "27", "28", "29", "30"]
//    @State private var selectedDayIndex = 1 // 默认选中周二(26日)
//    
//    var body: some View {
//        ZStack {
//            // 背景颜色
//            backgroundColor.ignoresSafeArea()
//            
//            VStack(spacing: 20) {
//                // 顶部导航栏
//                topNavBar()
//                
//                // 日期选择器
//                datePicker()
//                
//                // 时间线标题
//                Text("Timeline")
//                    .font(.title3)
//                    .fontWeight(.semibold)
//                    .foregroundColor(textColor)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .padding(.horizontal, 20)
//                    .padding(.top, 10)
//                
//                // 时间线内容
//                timelineContent()
//                
//                Spacer()
//                
//                // 底部添加按钮
//                Button(action: {
//                    // 添加新记录的操作
//                }) {
//                    Image(systemName: "plus")
//                        .font(.title2)
//                        .foregroundColor(.white)
//                        .frame(width: 56, height: 56)
//                        .background(Circle().fill(accentColor))
//                }
//                .padding(.bottom, 20)
//            }
//        }
//    }
//    
//    // MARK: - 子视图
//    
//    // 顶部导航栏
//    private func topNavBar() -> some View {
//        HStack {
//            Button(action: {
//                // 返回按钮操作
//            }) {
//                Circle()
//                    .fill(Color.white)
//                    .frame(width: 36, height: 36)
//                    .overlay(
//                        Image(systemName: "chevron.left")
//                            .foregroundColor(textColor)
//                            .font(.system(size: 16, weight: .medium))
//                    )
//            }
//            
//            Spacer()
//            
//            Text("My Calendar")
//                .font(.system(size: 20, weight: .bold))
//                .foregroundColor(textColor)
//                .padding(.trailing, 36) // 为了居中标题
//        }
//        .padding(.horizontal, 20)
//        .padding(.top, 10)
//    }
//    
//    // 日期选择器
//    private func datePicker() -> some View {
//        ScrollView(.horizontal, showsIndicators: false) {
//            HStack(spacing: 8) {
//                ForEach(0..<weekdays.count, id: \.self) { index in
//                    let isSelected = index == selectedDayIndex
//                    
//                    Button(action: {
//                        selectedDayIndex = index
//                    }) {
//                        VStack(spacing: 4) {
//                            Text(weekdays[index])
//                                .font(.system(size: 14))
//                                .foregroundColor(isSelected ? textColor : Color.gray)
//                            
//                            Text(dates[index])
//                                .font(.system(size: 16, weight: .bold))
//                                .foregroundColor(isSelected ? textColor : Color.gray)
//                            
//                            Circle()
//                                .fill(isSelected ? accentColor : Color.clear)
//                                .frame(width: 4, height: 4)
//                                .padding(.top, 2)
//                        }
//                        .frame(width: 45, height: 65)
//                        .background(
//                            Capsule()
//                                .fill(isSelected ? Color.white : Color.clear)
//                                .overlay(
//                                    Capsule()
//                                        .stroke(isSelected ? accentColor : Color.clear, lineWidth: 1)
//                                )
//                        )
//                    }
//                }
//            }
//            .padding(.horizontal, 16)
//        }
//        .padding(.top, 5)
//    }
//    
//    // 时间线内容
//    private func timelineContent() -> some View {
//        HStack(alignment: .top, spacing: 0) {
//            // 左侧卡片
//            VStack {
//                journalCard(
//                    icon: "😐",
//                    iconColor: Color.purple,
//                    title: "Work-related stress is killing me",
//                    content: "I felt anxious today during the team meeting. Too much work load recently.",
//                    time: "96bpm",
//                    isLeft: true
//                )
//                Spacer()
//            }
//            .frame(width: UIScreen.main.bounds.width * 0.43)
//            
//            // 中间时间线
//            timelineDivider()
//            
//            // 右侧卡片
//            VStack {
//                Spacer().frame(height: 40) // 添加间距使右侧卡片错开
//                journalCard(
//                    icon: "💡",
//                    iconColor: Color.yellow,
//                    title: "Felt Bad, but it's all OK.",
//                    content: "xxxxxxx",
//                    time: nil,
//                    isLeft: false
//                )
//                Spacer()
//            }
//            .frame(width: UIScreen.main.bounds.width * 0.43)
//        }
//        .padding(.top, 10)
//    }
//    
//    // 日记卡片
//    private func journalCard(icon: String, iconColor: Color, title: String, content: String, time: String?, isLeft: Bool) -> some View {
//        VStack(alignment: .leading, spacing: 10) {
//            // 图标始终在顶部
//            ZStack {
//                Circle()
//                    .fill(iconColor)
//                    .frame(width: 36, height: 36)
//                
//                Text(icon)
//                    .font(.system(size: 18))
//            }
//            .frame(maxWidth: .infinity, alignment: .leading)
//            
//            // 心率信息（如果有）
//            if let time = time {
//                HStack(spacing: 4) {
//                    Image(systemName: "waveform.path")
//                        .font(.system(size: 12))
//                        .foregroundColor(.gray)
//                    
//                    Text(time)
//                        .font(.system(size: 14))
//                        .foregroundColor(.gray)
//                }
//                .padding(.top, -5)
//            }
//            
//            // 标题
//            Text(title)
//                .font(.system(size: 15, weight: .bold))
//                .foregroundColor(textColor)
//                .multilineTextAlignment(.leading)
//                .padding(.top, time == nil ? -5 : 0)
//            
//            // 内容
//            Text(content)
//                .font(.system(size: 13))
//                .foregroundColor(.gray)
//                .multilineTextAlignment(.leading)
//                .fixedSize(horizontal: false, vertical: true)
//        }
//        .padding(16)
//        .background(
//            RoundedRectangle(cornerRadius: 20)
//                .fill(Color.white)
//                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
//        )
//    }
//    
//    // 时间线分隔线
//    private func timelineDivider() -> some View {
//        VStack(spacing: 0) {
//            Rectangle()
//                .fill(accentColor)
//                .frame(width: 2)
//                .frame(height: 100)
//            
//            Circle()
//                .fill(accentColor)
//                .frame(width: 8, height: 8)
//            
//            Rectangle()
//                .fill(accentColor)
//                .frame(width: 2)
//                .frame(height: 200)
//        }
//        .frame(width: UIScreen.main.bounds.width * 0.14)
//    }
//}
//
//// MARK: - 预览
//struct HomeAndMentalView_Previews: PreviewProvider {
//    static var previews: some View {
//        HomeAndMentalView()
//    }
//}
