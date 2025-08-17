////
////  CallView+BackendCommunication.swift
////  Hackathon2
////
////  Created by AI Assistant
////
//
//import SwiftUI
//import AVFoundation
//import Speech
//
//// MARK: - 调试功能扩展
//extension CallView {
//    
//    /// 添加调试消息
//    func addDebugMessage(_ message: String) {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "HH:mm:ss.SSS"
//        let timestamp = formatter.string(from: Date())
//        let debugMessage = "[\(timestamp)] \(message)"
//        debugMessages.append(debugMessage)
//        print("🔍 \(debugMessage)")
//        
//        // 限制调试消息数量
//        if debugMessages.count > 50 {
//            debugMessages.removeFirst()
//        }
//    }
//    
//    /// 设置音频会话
//    func setupAudioSession() {
//        let audioSession = AVAudioSession.sharedInstance()
//        do {
//            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .defaultToSpeaker, .duckOthers])
//            try audioSession.setActive(true)
//            addDebugMessage("Audio session configured successfully")
//        } catch {
//            addDebugMessage("Audio session configuration failed: \(error.localizedDescription)")
//        }
//    }
//}
//
//// MARK: - 后端通信扩展
//extension CallView {
//    
//    /// 发送语音文本到后端
//    func sendSpeechToBackend(_ text: String) {
//        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
//            addDebugMessage("Skipping empty text")
//            return
//        }
//        
//        // 避免重复发送相同内容
//        if text == previousTranscription {
//            addDebugMessage("Skipping duplicate text: \(text)")
//            return
//        }
//        
//        previousTranscription = text
//        addDebugMessage("Preparing to send speech text: \(text)")
//        
//        let url = URL(string: "https://emohunter-biometric-api-6106408799.us-central1.run.app/api/v1/unified/emotion_chat")!
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        let requestBody: [String: Any] = [
//            "message": text,
//            "user_id": userId
//        ]
//        
//        do {
//            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
//            addDebugMessage("Sending request to backend...")
//            
//            URLSession.shared.dataTask(with: request) { data, response, error in
//                DispatchQueue.main.async {
//                    if let error = error {
//                        self.addDebugMessage("Network request failed: \(error.localizedDescription)")
//                        return
//                    }
//                    
//                    guard let data = data else {
//                        self.addDebugMessage("No response data received")
//                        return
//                    }
//                    
//                    do {
//                        if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
//                            self.addDebugMessage("Received backend response: \(jsonResponse)")
//                            
//                            if let audioUrl = jsonResponse["audio_url"] as? String {
//                                self.addDebugMessage("Starting audio download: \(audioUrl)")
//                                self.downloadAudioAndPlay(from: audioUrl)
//                            } else if let responseText = jsonResponse["response"] as? String {
//                                self.addDebugMessage("Received text response, requesting TTS: \(responseText)")
//                                self.requestTTSAudio(for: responseText)
//                            } else {
//                                self.addDebugMessage("No audio URL or text found in response")
//                            }
//                        }
//                    } catch {
//                        self.addDebugMessage("Response parsing failed: \(error.localizedDescription)")
//                    }
//                }
//            }.resume()
//            
//        } catch {
//            addDebugMessage("Request creation failed: \(error.localizedDescription)")
//        }
//    }
//    
//    /// 请求TTS音频
//    func requestTTSAudio(for text: String) {
//        let url = URL(string: "https://emohunter-biometric-api-6106408799.us-central1.run.app/api/v1/unified/tts")!
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        let requestBody: [String: Any] = [
//            "text": text,
//            "user_id": userId
//        ]
//        
//        do {
//            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
//            addDebugMessage("Requesting TTS audio...")
//            
//            URLSession.shared.dataTask(with: request) { data, response, error in
//                DispatchQueue.main.async {
//                    if let error = error {
//                        self.addDebugMessage("TTS request failed: \(error.localizedDescription)")
//                        return
//                    }
//                    
//                    guard let data = data else {
//                        self.addDebugMessage("No TTS response data received")
//                        return
//                    }
//                    
//                    do {
//                        if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
//                           let audioUrl = jsonResponse["audio_url"] as? String {
//                            self.addDebugMessage("Received TTS audio URL: \(audioUrl)")
//                            self.downloadAudioAndPlay(from: audioUrl)
//                        } else {
//                            self.addDebugMessage("No audio URL found in TTS response")
//                        }
//                    } catch {
//                        self.addDebugMessage("TTS response parsing failed: \(error.localizedDescription)")
//                    }
//                }
//            }.resume()
//            
//        } catch {
//            addDebugMessage("TTS request creation failed: \(error.localizedDescription)")
//        }
//    }
//}
//
//// MARK: - 音频处理扩展
//extension CallView {
//    
//    /// 下载并播放音频
//    func downloadAudioAndPlay(from urlString: String) {
//        guard let url = URL(string: urlString) else {
//            addDebugMessage("Invalid audio URL: \(urlString)")
//            return
//        }
//        
//        addDebugMessage("Starting audio file download...")
//        audioDownloadProgress = 0.0
//        
//        URLSession.shared.dataTask(with: url) { data, response, error in
//            DispatchQueue.main.async {
//                if let error = error {
//                    self.addDebugMessage("Audio download failed: \(error.localizedDescription)")
//                    return
//                }
//                
//                guard let data = data else {
//                    self.addDebugMessage("Audio data is empty")
//                    return
//                }
//                
//                self.addDebugMessage("Audio download completed, starting playback")
//                self.audioDownloadProgress = 1.0
//                self.playAudioData(data)
//            }
//        }.resume()
//    }
//    
//    /// 播放音频数据
//    func playAudioData(_ data: Data) {
//        do {
//            // 停止语音识别
//            stopSpeechRecognition()
//            
//            audioPlayer = try AVAudioPlayer(data: data)
//            audioPlayer?.delegate = CallViewAudioPlayerDelegate(callView: self)
//            
//            currentAudioDuration = audioPlayer?.duration ?? 0
//            audioPlaybackProgress = 0.0
//            isPlayingResponse = true
//            
//            audioPlayer?.play()
//            addDebugMessage("Started playing audio, duration: \(currentAudioDuration) seconds")
//            
//            startPlaybackProgressTimer()
//            
//        } catch {
//            addDebugMessage("Audio playback failed: \(error.localizedDescription)")
//            restartSpeechRecognition()
//        }
//    }
//    
//    /// 开始播放进度计时器
//    func startPlaybackProgressTimer() {
//        playbackTimer?.invalidate()
//        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
//            guard let player = self.audioPlayer, player.isPlaying else {
//                self.playbackTimer?.invalidate()
//                return
//            }
//            
//            self.audioPlaybackProgress = Float(player.currentTime / player.duration)
//        }
//    }
//    
//    /// 停止音频播放
//    func stopAudioPlayback() {
//        audioPlayer?.stop()
//        audioPlayer = nil
//        playbackTimer?.invalidate()
//        isPlayingResponse = false
//        audioPlaybackProgress = 0.0
//        addDebugMessage("Audio playback stopped")
//    }
//}
//
//// MARK: - 改进的语音识别扩展
//extension CallView {
//    
//    /// 改进的连续语音识别方法
//    func startImprovedSpeechRecognition() {
//        guard !isMuted,
//              speechRecognizer?.isAvailable == true,
//              SFSpeechRecognizer.authorizationStatus() == .authorized else {
//            addDebugMessage("Speech recognition conditions not met")
//            return
//        }
//        
//        // 停止之前的任务
//        stopSpeechRecognition()
//        addDebugMessage("Starting improved speech recognition")
//        
//        // 配置音频会话
//        setupAudioSession()
//        
//        // 创建识别请求
//        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
//        guard let recognitionRequest = recognitionRequest else {
//            addDebugMessage("Unable to create speech recognition request")
//            return
//        }
//        
//        recognitionRequest.shouldReportPartialResults = true
//        recognitionRequest.requiresOnDeviceRecognition = false
//        
//        // 配置音频引擎
//        let inputNode = audioEngine.inputNode
//        let recordingFormat = inputNode.outputFormat(forBus: 0)
//        
//        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
//            recognitionRequest.append(buffer)
//        }
//        
//        audioEngine.prepare()
//        
//        do {
//            try audioEngine.start()
//            addDebugMessage("Audio engine started successfully")
//        } catch {
//            addDebugMessage("Audio engine startup failed: \(error.localizedDescription)")
//            return
//        }
//        
//        // 开始识别
//        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
//            DispatchQueue.main.async {
//                if let result = result {
//                    let newText = result.bestTranscription.formattedString
//                    self.currentSpeechText = newText
//                    
//                    // 检测是否在说话
//                    self.isSpeaking = !newText.isEmpty
//                    
//                    // 重置定时器
//                    self.speechTimer?.invalidate()
//                    self.speechTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
//                        // 2秒没有新的语音输入，发送到后端
//                        if !self.currentSpeechText.isEmpty {
//                            self.addDebugMessage("Speech recognition completed, sending to backend: \(self.currentSpeechText)")
//                            self.sendSpeechToBackend(self.currentSpeechText)
//                            self.speechHistory.append(self.currentSpeechText)
//                            self.currentSpeechText = ""
//                            self.isSpeaking = false
//                        }
//                    }
//                    
//                    if result.isFinal {
//                        // 识别完成，立即发送并重新开始
//                        self.addDebugMessage("Final recognition result: \(newText)")
//                        self.sendSpeechToBackend(newText)
//                        self.speechHistory.append(newText)
//                        self.currentSpeechText = ""
//                        self.isSpeaking = false
//                        self.restartSpeechRecognition()
//                    }
//                }
//                
//                if let error = error {
//                    self.addDebugMessage("Speech recognition error: \(error.localizedDescription)")
//                    self.restartSpeechRecognition()
//                }
//            }
//        }
//    }
//}
//
//// MARK: - CallView专用音频播放代理
//class CallViewAudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
//    private var callView: CallView
//    
//    init(callView: CallView) {
//        self.callView = callView
//        super.init()
//    }
//    
//    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
//        DispatchQueue.main.async {
//            self.callView.addDebugMessage("Audio playback completed")
//            self.callView.isPlayingResponse = false
//            self.callView.playbackTimer?.invalidate()
//            self.callView.restartSpeechRecognition()
//        }
//    }
//    
//}
