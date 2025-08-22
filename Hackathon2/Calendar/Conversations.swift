import Foundation
import SwiftUI

// MARK: - Data Models
struct Conversation: Identifiable, Codable {
    let id: String
    var title: String
    var tags: [String]
    var startTime: Date
    var endTime: Date
    var messages: [Message]
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case tags
        case startTime = "start_time"
        case endTime = "end_time"
        case messages
    }
    
    init(id: String, title: String, tags: [String], startTime: Date, endTime: Date, messages: [Message]) {
        self.id = id
        self.title = title
        self.tags = tags
        self.startTime = startTime
        self.endTime = endTime
        self.messages = messages
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        tags = try container.decode([String].self, forKey: .tags)
        let startString = try container.decode(String.self, forKey: .startTime)
        let endString = try container.decode(String.self, forKey: .endTime)
        startTime = DateFormatter.iso8601NoTZ.date(from: startString) ?? Date()
        endTime = DateFormatter.iso8601NoTZ.date(from: endString) ?? Date()
        messages = try container.decode([Message].self, forKey: .messages)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(tags, forKey: .tags)
        try container.encode(DateFormatter.iso8601NoTZ.string(from: startTime), forKey: .startTime)
        try container.encode(DateFormatter.iso8601NoTZ.string(from: endTime), forKey: .endTime)
        try container.encode(messages, forKey: .messages)
    }
}

struct Message: Codable {
    var timestamp: Date
    var role: String
    var content: String
    
    enum CodingKeys: String, CodingKey { case timestamp, role, content }
    
    init(timestamp: Date, role: String, content: String) {
        self.timestamp = timestamp
        self.role = role
        self.content = content
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let ts = try container.decode(String.self, forKey: .timestamp)
        timestamp = DateFormatter.iso8601NoTZ.date(from: ts) ?? Date()
        role = try container.decode(String.self, forKey: .role)
        content = try container.decode(String.self, forKey: .content)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(DateFormatter.iso8601NoTZ.string(from: timestamp), forKey: .timestamp)
        try container.encode(role, forKey: .role)
        try container.encode(content, forKey: .content)
    }
}

// MARK: - Store
final class ConversationStore {
    static let shared = ConversationStore()
    
    private let calendar = Calendar.current
    private(set) var conversations: [Conversation] = []
    private var dayToConversations: [String: [Conversation]] = [:] // yyyy-MM-dd -> conversations
    
    private init() {
        load()
        scatterAcrossLast7Days()
    }
    
    func conversations(on date: Date) -> [Conversation] {
        let key = dateKey(date)
        let list = dayToConversations[key] ?? []
        // Return only the conversations that actually happened on this day, sorted by start time
        return list.sorted { $0.startTime < $1.startTime }
    }
    
    func conversation(by id: String) -> Conversation? {
        conversations.first { $0.id == id }
    }
    
    // MARK: - Loading & Mapping
    private func load() {
        if let url = Bundle.main.url(forResource: "conversations", withExtension: "json"),
           let data = try? Data(contentsOf: url) {
            decode(from: data)
            return
        }
        // Fallback to embedded JSON string
        if let data = ConversationStore.embeddedSampleJson.data(using: .utf8) {
            decode(from: data)
        }
    }
    
    private func decode(from data: Data) {
        do {
            let decoded = try JSONDecoder().decode([Conversation].self, from: data)
            conversations = decoded
        } catch {
            print("[ConversationStore] Decode failed: \(error)")
            conversations = []
        }
    }
    
    private func scatterAcrossLast7Days() {
        guard !conversations.isEmpty else { return }
        // Place unique conversations over the last 7 days, preserving one per slot before repeating
        let today = calendar.startOfDay(for: Date())
        let days: [Date] = (0..<7).compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
        var mapped: [Conversation] = []
        let limited = Array(conversations.prefix(10)) // strictly use 10 unique conversations
        for (idx, conv) in limited.enumerated() {
            let targetDay = days[idx % days.count]
            mapped.append(adjust(conv, toDay: targetDay))
        }
        conversations = mapped
        dayToConversations = Dictionary(grouping: mapped, by: { dateKey($0.startTime) })
    }
    
    private func adjust(_ conv: Conversation, toDay targetDay: Date) -> Conversation {
        let newStart = replace(date: conv.startTime, withDayOf: targetDay)
        let newEnd = replace(date: conv.endTime, withDayOf: targetDay)
        let newMessages = conv.messages.map { msg in
            Message(timestamp: replace(date: msg.timestamp, withDayOf: targetDay), role: msg.role, content: msg.content)
        }
        return Conversation(id: conv.id, title: conv.title, tags: conv.tags, startTime: newStart, endTime: newEnd, messages: newMessages)
    }
    
    private func replace(date: Date, withDayOf target: Date) -> Date {
        var comps = calendar.dateComponents([.hour, .minute, .second], from: date)
        let dayComps = calendar.dateComponents([.year, .month, .day], from: target)
        comps.year = dayComps.year
        comps.month = dayComps.month
        comps.day = dayComps.day
        return calendar.date(from: comps) ?? target
    }
    
    private func dateKey(_ date: Date) -> String {
        DateFormatter.yyyyMMdd.string(from: calendar.startOfDay(for: date))
    }
}

// MARK: - Formatters
extension DateFormatter {
    static let iso8601NoTZ: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return f
    }()
    
    static let yyyyMMdd: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    
    static let HHmm: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "HH:mm"
        return f
    }()
}

// MARK: - Embedded JSON (fallback)
extension ConversationStore {
    // Note: also add conversations.json in the repo root of the target (same contents) if you want to ship it as a resource.
    static let embeddedSampleJson = """
[
  {
    "id": "conv-001",
    "title": "Navigating breakup grief 🌱💛",
    "tags": ["#grounding", "#self-compassion", "#journalling", "#deep-breathing", "#checking-in"],
    "start_time": "2025-08-10T07:15:00",
    "end_time": "2025-08-10T07:28:00",
    "messages": [
      {"timestamp": "2025-08-10T07:15:00", "role": "user", "content": "I woke up missing them again. It hurts."},
      {"timestamp": "2025-08-10T07:16:00", "role": "assistant", "content": "I’m really sorry you’re feeling this ache. Let’s take one slow breath together and notice your feet on the floor. What feels heaviest right now?"},
      {"timestamp": "2025-08-10T07:18:00", "role": "user", "content": "The mornings. They feel so empty."},
      {"timestamp": "2025-08-10T07:19:00", "role": "assistant", "content": "That makes a lot of sense. Mornings hold routines and memories. Would a simple grounding ritual help—like three deep breaths and writing one kind line to yourself?"},
      {"timestamp": "2025-08-10T07:21:00", "role": "user", "content": "I can try that."},
      {"timestamp": "2025-08-10T07:23:00", "role": "assistant", "content": "Beautiful. Maybe jot down: “I’m allowed to grieve and still care for myself.” What else would you want future-you to read tomorrow morning?"},
      {"timestamp": "2025-08-10T07:25:00", "role": "user", "content": "That I’m not broken, just healing."},
      {"timestamp": "2025-08-10T07:28:00", "role": "assistant", "content": "Powerful. You’re healing, not broken. I’m here with you—one gentle morning at a time."}
    ]
  },
  {
    "id": "conv-002",
    "title": "From stuck to motivated 🚀✨",
    "tags": ["#activation", "#reframing", "#tiny-steps", "#movement", "#values"],
    "start_time": "2025-08-11T09:05:00",
    "end_time": "2025-08-11T09:20:00",
    "messages": [
      {"timestamp": "2025-08-11T09:05:00", "role": "user", "content": "I can’t get started on my tasks."},
      {"timestamp": "2025-08-11T09:06:00", "role": "assistant", "content": "Thanks for sharing. Let’s shrink the starting line—what’s the tiniest first step that takes under two minutes?"},
      {"timestamp": "2025-08-11T09:08:00", "role": "user", "content": "Maybe opening the doc and listing the sections."},
      {"timestamp": "2025-08-11T09:10:00", "role": "assistant", "content": "Perfect. Framing this as momentum building, not perfection. After the list, a 2‑minute stretch to reset?"},
      {"timestamp": "2025-08-11T09:12:00", "role": "user", "content": "Yeah, that could help."},
      {"timestamp": "2025-08-11T09:14:00", "role": "assistant", "content": "You’ve already shifted from stuck to moving. What value does this work serve for you today—learning, service, stability?"},
      {"timestamp": "2025-08-11T09:16:00", "role": "user", "content": "Stability, mostly."},
      {"timestamp": "2025-08-11T09:18:00", "role": "assistant", "content": "Great anchor. Let’s ride that value: “I build stability by showing up in small steps.” You’ve got this."},
      {"timestamp": "2025-08-11T09:20:00", "role": "user", "content": "Opening the doc now. Thanks."}
    ]
  },
  {
    "id": "conv-003",
    "title": "I got this! 💪🌞",
    "tags": ["#confidence", "#positive-self-talk", "#gratitude", "#celebrating-wins"],
    "start_time": "2025-08-11T10:42:00",
    "end_time": "2025-08-11T10:55:00",
    "messages": [
      {"timestamp": "2025-08-11T10:42:00", "role": "user", "content": "I actually handled a tough email well."},
      {"timestamp": "2025-08-11T10:43:00", "role": "assistant", "content": "That’s a real win! What did you do differently that you’re proud of?"},
      {"timestamp": "2025-08-11T10:45:00", "role": "user", "content": "I paused, rewrote it calmly, and kept it brief."},
      {"timestamp": "2025-08-11T10:47:00", "role": "assistant", "content": "Thoughtful and steady. Let’s bank this: “I can regulate and respond with clarity.” What tiny celebration will you give yourself?"},
      {"timestamp": "2025-08-11T10:49:00", "role": "user", "content": "A short walk outside."},
      {"timestamp": "2025-08-11T10:51:00", "role": "assistant", "content": "Love it. As you walk, note one thing you’re grateful for from this morning."},
      {"timestamp": "2025-08-11T10:53:00", "role": "user", "content": "Grateful I didn’t spiral."},
      {"timestamp": "2025-08-11T10:55:00", "role": "assistant", "content": "That’s strength. “I got this,” indeed—one steady response at a time."}
    ]
  },
  {
    "id": "conv-004",
    "title": "Calming midday overwhelm 🌤️🫶",
    "tags": ["#grounding", "#box-breathing", "#prioritization", "#self-kindness"],
    "start_time": "2025-08-12T11:30:00",
    "end_time": "2025-08-12T11:44:00",
    "messages": [
      {"timestamp": "2025-08-12T11:30:00", "role": "user", "content": "My to‑do list is crowding my head."},
      {"timestamp": "2025-08-12T11:31:00", "role": "assistant", "content": "Let’s clear some space. Box-breathe (4‑in, 4‑hold, 4‑out, 4‑hold). Ready for one cycle?"},
      {"timestamp": "2025-08-12T11:33:00", "role": "user", "content": "Okay, did it."},
      {"timestamp": "2025-08-12T11:35:00", "role": "assistant", "content": "Nicely done. Now: choose one “must”, one “nice-to-do.” Everything else waits."},
      {"timestamp": "2025-08-12T11:37:00", "role": "user", "content": "Must: send the report. Nice: schedule dentist."},
      {"timestamp": "2025-08-12T11:39:00", "role": "assistant", "content": "Perfect. What kind phrase will you say to yourself while you send the report?"},
      {"timestamp": "2025-08-12T11:41:00", "role": "user", "content": "“I can do hard things calmly.”"},
      {"timestamp": "2025-08-12T11:44:00", "role": "assistant", "content": "Beautiful. I’m here while you do it—calm and capable."}
    ]
  },
  {
    "id": "conv-005",
    "title": "After-lunch reset 🧘‍♀️🍃",
    "tags": ["#movement", "#stretching", "#mindfulness", "#compassion", "#reframing"],
    "start_time": "2025-08-12T12:47:00",
    "end_time": "2025-08-12T13:07:00",
    "messages": [
      {"timestamp": "2025-08-12T12:47:00", "role": "user", "content": "I feel sluggish and guilty for not doing more."},
      {"timestamp": "2025-08-12T12:49:00", "role": "assistant", "content": "That’s a heavy combo. Let’s reset with a 60‑second stretch; then we’ll reframe the story. Up for it?"},
      {"timestamp": "2025-08-12T12:51:00", "role": "user", "content": "Stretching now… done."},
      {"timestamp": "2025-08-12T12:53:00", "role": "assistant", "content": "Nice. Reframe: “My energy dips after lunch; I can still move forward gently.” What is one light, achievable action next?"},
      {"timestamp": "2025-08-12T12:56:00", "role": "user", "content": "Reply to two emails."},
      {"timestamp": "2025-08-12T12:58:00", "role": "assistant", "content": "Great. After that, 30 seconds of mindful breathing—just noticing the breath. You’re allowed to go gently."},
      {"timestamp": "2025-08-12T13:03:00", "role": "user", "content": "That helps me not push so hard."},
      {"timestamp": "2025-08-12T13:07:00", "role": "assistant", "content": "Exactly. Gentle doesn’t mean giving up; it means sustainable care."}
    ]
  },
  {
    "id": "conv-006",
    "title": "Working with anxiety 🌬️🧱",
    "tags": ["#grounding", "#5-4-3-2-1", "#reframing", "#wise-mind"],
    "start_time": "2025-08-13T14:10:00",
    "end_time": "2025-08-13T14:24:00",
    "messages": [
      {"timestamp": "2025-08-13T14:10:00", "role": "user", "content": "My chest feels tight before this call."},
      {"timestamp": "2025-08-13T14:11:00", "role": "assistant", "content": "I’m here. Let’s try 5‑4‑3‑2‑1 grounding—name 5 things you see."},
      {"timestamp": "2025-08-13T14:13:00", "role": "user", "content": "Laptop, mug, notebook, pen, window."},
      {"timestamp": "2025-08-13T14:15:00", "role": "assistant", "content": "Good. 4 you can touch?"},
      {"timestamp": "2025-08-13T14:16:00", "role": "user", "content": "Chair, sweater, keyboard, floor."},
      {"timestamp": "2025-08-13T14:18:00", "role": "assistant", "content": "Great. Feel a bit more present? What’s one balanced thought from your wise mind about the call?"},
      {"timestamp": "2025-08-13T14:20:00", "role": "user", "content": "I don’t have to be perfect, just prepared."},
      {"timestamp": "2025-08-13T14:22:00", "role": "assistant", "content": "Exactly. One steady breath—then step in as you are."},
      {"timestamp": "2025-08-13T14:24:00", "role": "user", "content": "Going in now."}
    ]
  },
  {
    "id": "conv-007",
    "title": "Gentle afternoon motivation 🌻📈",
    "tags": ["#behavioral-activation", "#tiny-steps", "#opposite-action", "#self-encouragement"],
    "start_time": "2025-08-14T15:33:00",
    "end_time": "2025-08-14T15:49:00",
    "messages": [
      {"timestamp": "2025-08-14T15:33:00", "role": "user", "content": "I want to procrastinate again."},
      {"timestamp": "2025-08-14T15:34:00", "role": "assistant", "content": "Understandable. Let’s try opposite action in a tiny way—two minutes of focused work. Timer?"},
      {"timestamp": "2025-08-14T15:36:00", "role": "user", "content": "Timer set."},
      {"timestamp": "2025-08-14T15:38:00", "role": "assistant", "content": "Awesome. After the timer, tell me one sentence of progress."},
      {"timestamp": "2025-08-14T15:41:00", "role": "user", "content": "I cleaned up the outline."},
      {"timestamp": "2025-08-14T15:43:00", "role": "assistant", "content": "That’s real movement. Want to stack another two minutes or take a brief stretch first?"},
      {"timestamp": "2025-08-14T15:45:00", "role": "user", "content": "Another two minutes."},
      {"timestamp": "2025-08-14T15:47:00", "role": "assistant", "content": "Go you. “I move by inches and it counts.” I’m cheering you on."},
      {"timestamp": "2025-08-14T15:49:00", "role": "user", "content": "Thanks, that helps."}
    ]
  },
  {
    "id": "conv-008",
    "title": "Early evening decompression 🌆🫁",
    "tags": ["#deep-breathing", "#mindfulness", "#transition-ritual", "#self-compassion"],
    "start_time": "2025-08-14T17:02:00",
    "end_time": "2025-08-14T17:15:00",
    "messages": [
      {"timestamp": "2025-08-14T17:02:00", "role": "user", "content": "My brain is buzzing after work."},
      {"timestamp": "2025-08-14T17:03:00", "role": "assistant", "content": "Let’s mark the transition with three long exhales, shoulders down. Ready?"},
      {"timestamp": "2025-08-14T17:05:00", "role": "user", "content": "Did it."},
      {"timestamp": "2025-08-14T17:07:00", "role": "assistant", "content": "Nice. Next, a 3‑minute “do nothing” window—no screens, just notice the room. How does that sound?"},
      {"timestamp": "2025-08-14T17:09:00", "role": "user", "content": "I can try that."},
      {"timestamp": "2025-08-14T17:11:00", "role": "assistant", "content": "When you return, tell yourself: “Work can end; I can rest now.” Your nervous system deserves quiet."},
      {"timestamp": "2025-08-14T17:13:00", "role": "user", "content": "I feel a little softer already."},
      {"timestamp": "2025-08-14T17:15:00", "role": "assistant", "content": "That softness is you caring for you. Lovely work."}
    ]
  },
  {
    "id": "conv-009",
    "title": "Reframing nighttime worries 🌙🔄",
    "tags": ["#cognitive-reframing", "#worry-time", "#journalling", "#self-soothing"],
    "start_time": "2025-08-15T19:21:00",
    "end_time": "2025-08-15T19:35:00",
    "messages": [
      {"timestamp": "2025-08-15T19:21:00", "role": "user", "content": "My worries are louder at night."},
      {"timestamp": "2025-08-15T19:22:00", "role": "assistant", "content": "That’s common—our brains seek closure. Let’s schedule “worry time” tomorrow (10 minutes). Tonight, we capture the top 3 worries on paper."},
      {"timestamp": "2025-08-15T19:24:00", "role": "user", "content": "Okay, writing them down."},
      {"timestamp": "2025-08-15T19:26:00", "role": "assistant", "content": "Great. Now a gentle reframe for one of them—what would a wise, caring friend say?"},
      {"timestamp": "2025-08-15T19:28:00", "role": "user", "content": "That I’m doing my best with the info I have."},
      {"timestamp": "2025-08-15T19:30:00", "role": "assistant", "content": "Beautiful. End with one soothing action—dim lights, warm tea, or calm music?"},
      {"timestamp": "2025-08-15T19:33:00", "role": "user", "content": "Tea and music."},
      {"timestamp": "2025-08-15T19:35:00", "role": "assistant", "content": "Cozy and kind. You’re allowed to rest."}
    ]
  },
  {
    "id": "conv-010",
    "title": "A hopeful close to the day 🌟💖",
    "tags": ["#gratitude", "#self-compassion", "#sleep-hygiene", "#future-self"],
    "start_time": "2025-08-16T21:05:00",
    "end_time": "2025-08-16T21:18:00",
    "messages": [
      {"timestamp": "2025-08-16T21:05:00", "role": "user", "content": "Today wasn’t perfect, but I tried."},
      {"timestamp": "2025-08-16T21:06:00", "role": "assistant", "content": "Trying counts—a lot. What’s one thing you appreciate about yourself tonight?"},
      {"timestamp": "2025-08-16T21:08:00", "role": "user", "content": "I kept showing up even when I felt tired."},
      {"timestamp": "2025-08-16T21:10:00", "role": "assistant", "content": "That’s resilience. Let’s gift future‑you a sentence to wake up to."},
      {"timestamp": "2025-08-16T21:12:00", "role": "user", "content": "“You’re safe to start small.”"},
      {"timestamp": "2025-08-16T21:14:00", "role": "assistant", "content": "I love that. For sleep hygiene, lights down and one screen‑free wind‑down?"},
      {"timestamp": "2025-08-16T21:16:00", "role": "user", "content": "I’ll read a few pages."},
      {"timestamp": "2025-08-16T21:18:00", "role": "assistant", "content": "Gentle ending. I’m proud of you. Sleep well."}
    ]
  }
]
"""
}

// MARK: - Color Theme
struct WarmTheme {
    // Base palette per style guide
    static let purple = Color(red: 0.45, green: 0.20, blue: 0.85) // Accent
    static let cream = Color.white // keep name for existing usages
    
    static let primaryBackground = Color.white
    static let secondaryBackground = Color(white: 0.95)
    static let cardBackground = Color.white
    
    static let primaryText = Color.black
    static let secondaryText = Color.gray
    static let accentText = Color.black
    
    static let accent = purple
    static let lightAccent = purple.opacity(0.15)
    static let border = Color.gray.opacity(0.15)

    // Legacy colors kept for calendar heatmap, etc.
    static let coral = Color(red: 1.0, green: 0.5, blue: 0.31)
    static let lightCoral = Color(red: 1.0, green: 0.63, blue: 0.48)
    static let peach = Color(red: 0.9, green: 0.85, blue: 0.73)
}


