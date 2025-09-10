//
//  AudioAPITest.swift
//  Hackathon2
//
//  API音频测试和前端接收标准示例
//

import Foundation
import AVFoundation
import SwiftUI

class AudioAPITestManager: ObservableObject {
    @Published var isLoading = false
    @Published var testResults: [String] = []
    @Published var audioPlayer: AVAudioPlayer?
    @Published var isPlaying = false
    
    private let apiURL = "https://emohunter-api-6106408799.us-central1.run.app/api/v1/text_conversation"
    
    // MARK: - API测试方法
    func testTextConversationAPI(message: String, userId: String = "test_user") {
        isLoading = true
        addTestResult("🚀 开始测试API: \(message)")
        
        guard let url = URL(string: apiURL) else {
            addTestResult("❌ 无效的API URL")
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0
        
        let requestBody = [
            "message": message,
            "user_id": userId
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            addTestResult("✅ 请求体序列化成功")
        } catch {
            addTestResult("❌ JSON序列化失败: \(error.localizedDescription)")
            isLoading = false
            return
        }
        
        let startTime = Date()
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            let responseTime = Date().timeIntervalSince(startTime)
            
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.addTestResult("❌ API请求失败 (\(String(format: "%.2f", responseTime))s): \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    self?.addTestResult("📊 HTTP状态码: \(httpResponse.statusCode)")
                }
                
                guard let data = data else {
                    self?.addTestResult("❌ 没有接收到响应数据")
                    return
                }
                
                self?.parseAPIResponse(data: data, responseTime: responseTime)
            }
        }.resume()
    }
    
    // MARK: - 响应解析
    private func parseAPIResponse(data: Data, responseTime: TimeInterval) {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                addTestResult("✅ API响应解析成功 (\(String(format: "%.2f", responseTime))s)")
                
                // 显示响应内容
                if let userMessage = json["user_message"] as? String {
                    addTestResult("👤 用户消息: \(userMessage)")
                }
                
                if let aiResponse = json["ai_response"] as? String {
                    addTestResult("🤖 AI回复: \(aiResponse)")
                }
                
                if let emotion = json["detected_emotion"] as? String {
                    addTestResult("😊 检测到的情绪: \(emotion)")
                }
                
                if let ttsAvailable = json["tts_available"] as? Bool {
                    addTestResult("🔊 TTS可用: \(ttsAvailable ? "是" : "否")")
                }
                
                if let error = json["error"] as? String {
                    addTestResult("⚠️ API错误: \(error)")
                }
                
                // 检查音频相关字段
                checkAudioFields(in: json)
            }
        } catch {
            addTestResult("❌ 响应解析失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 音频字段检查
    private func checkAudioFields(in json: [String: Any]) {
        // 检查可能的音频URL字段
        if let audioUrl = json["audio_url"] as? String {
            addTestResult("🎵 发现音频URL: \(audioUrl)")
            downloadAndPlayAudio(from: audioUrl)
        } else if let audioData = json["audio_data"] as? String {
            addTestResult("🎵 发现Base64音频数据")
            playAudioFromBase64(audioData)
        } else if let ttsUrl = json["tts_url"] as? String {
            addTestResult("🎵 发现TTS音频URL: \(ttsUrl)")
            downloadAndPlayAudio(from: ttsUrl)
        } else {
            addTestResult("❌ 响应中未找到音频数据")
            addTestResult("💡 建议: API可能需要额外的TTS请求")
        }
    }
    
    // MARK: - 音频下载和播放
    func downloadAndPlayAudio(from urlString: String) {
        guard let url = URL(string: urlString) else {
            addTestResult("❌ 无效的音频URL: \(urlString)")
            return
        }
        
        addTestResult("📥 开始下载音频文件...")
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.addTestResult("❌ 音频下载失败: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    self?.addTestResult("❌ 音频数据为空")
                    return
                }
                
                self?.addTestResult("✅ 音频下载完成，大小: \(data.count) bytes")
                self?.playAudioData(data)
            }
        }.resume()
    }
    
    func playAudioFromBase64(_ base64String: String) {
        guard let data = Data(base64Encoded: base64String) else {
            addTestResult("❌ Base64音频数据解码失败")
            return
        }
        
        addTestResult("✅ Base64音频数据解码成功，大小: \(data.count) bytes")
        playAudioData(data)
    }
    
    private func playAudioData(_ data: Data) {
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.prepareToPlay()
            
            if let duration = audioPlayer?.duration {
                addTestResult("🎵 音频时长: \(String(format: "%.2f", duration))秒")
            }
            
            isPlaying = true
            audioPlayer?.play()
            addTestResult("▶️ 开始播放音频")
            
            // 监听播放完成
            DispatchQueue.main.asyncAfter(deadline: .now() + (audioPlayer?.duration ?? 0)) {
                self.isPlaying = false
                self.addTestResult("⏹️ 音频播放完成")
            }
            
        } catch {
            addTestResult("❌ 音频播放失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 辅助方法
    private func addTestResult(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        testResults.append("[\(timestamp)] \(message)")
        print("🔍 \(message)")
        
        // 限制日志数量
        if testResults.count > 50 {
            testResults.removeFirst()
        }
    }
    
    func clearResults() {
        testResults.removeAll()
    }
    
    func stopAudio() {
        audioPlayer?.stop()
        isPlaying = false
        addTestResult("⏹️ 音频播放已停止")
    }
}

// MARK: - SwiftUI测试界面
struct AudioAPITestView: View {
    @StateObject private var testManager = AudioAPITestManager()
    @State private var testMessage = "Hello, how are you today?"
    @State private var userId = "test_user_001"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 输入区域
                VStack(alignment: .leading, spacing: 10) {
                    Text("API测试参数")
                        .font(.headline)
                    
                    TextField("测试消息", text: $testMessage)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("用户ID", text: $userId)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // 控制按钮
                HStack(spacing: 15) {
                    Button("测试API") {
                        testManager.testTextConversationAPI(message: testMessage, userId: userId)
                    }
                    .disabled(testManager.isLoading)
                    .buttonStyle(.borderedProminent)
                    
                    if testManager.isPlaying {
                        Button("停止播放") {
                            testManager.stopAudio()
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Button("清除日志") {
                        testManager.clearResults()
                    }
                    .buttonStyle(.bordered)
                }
                
                // 测试结果
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 5) {
                        ForEach(testManager.testResults, id: \.self) { result in
                            Text(result)
                                .font(.system(.caption, design: .monospaced))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 2)
                        }
                    }
                }
                .background(Color.black.opacity(0.05))
                .cornerRadius(10)
                
                Spacer()
            }
            .padding()
            .navigationTitle("音频API测试")
        }
    }
}

// MARK: - 前端音频接收标准
/*
前端接收音频文件的标准:

1. **API响应格式检查**:
   - 检查响应中的 `audio_url` 字段（音频文件URL）
   - 检查响应中的 `audio_data` 字段（Base64编码的音频数据）
   - 检查响应中的 `tts_available` 字段（TTS是否可用）
   - 检查响应中的 `error` 字段（错误信息）

2. **音频格式支持**:
   - MP3格式（推荐，兼容性最好）
   - WAV格式（无损，文件较大）
   - M4A格式（Apple设备优化）

3. **下载和缓存**:
   - 使用URLSession下载音频文件
   - 实现下载进度监控
   - 考虑音频文件缓存策略

4. **播放控制**:
   - 使用AVAudioPlayer播放音频
   - 实现播放进度监控
   - 提供播放/暂停/停止控制

5. **错误处理**:
   - 网络错误处理
   - 音频格式不支持错误
   - 播放失败错误处理

6. **用户体验**:
   - 显示加载状态
   - 显示播放进度
   - 提供音量控制
   - 支持后台播放（如需要）

7. **性能优化**:
   - 音频预加载
   - 内存管理
   - 并发下载控制
*/