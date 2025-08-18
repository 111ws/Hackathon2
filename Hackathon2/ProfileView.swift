import SwiftUI

struct ProfileView: View {
	@State private var isPro: Bool = true
	private let userName: String = "Jessica Miller"
	private let joinedText: String = "Joined June 2025"
	private let signedInEmail: String = "fokaetos@gmail.com"
	private let appVersion: String = "0.001.1"

	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(spacing: 24) {
					header()
					menuSection()
					footer()
					signOutButton()
				}
				.padding(.horizontal, 20)
				.padding(.top, 24)
				.padding(.bottom, 40)
			}
			.background(Color.black.opacity(0.9))
			.navigationTitle("")
		}
	}

	@ViewBuilder
	private func header() -> some View {
		HStack(alignment: .center, spacing: 16) {
			VStack(alignment: .leading, spacing: 6) {
				HStack(spacing: 8) {
					Text(userName)
						.font(.title3).bold()
						.foregroundColor(.white)
					if isPro {
						Text("Pro")
							.font(.caption)
							.foregroundColor(.white.opacity(0.8))
							.padding(.horizontal, 8)
							.padding(.vertical, 2)
							.background(Color.white.opacity(0.08), in: Capsule())
					}
				}
				Text(joinedText)
					.font(.footnote)
					.foregroundColor(.white.opacity(0.7))
			}
			Spacer()
			Circle()
				.fill(Color.white.opacity(0.12))
				.frame(width: 72, height: 72)
		}
	}

	@ViewBuilder
	private func menuSection() -> some View {
		VStack(spacing: 16) {
			navRow(title: "Account and Subscription") {
				ManageSubscriptionView()
			}
			navRow(title: "Notification and Privacy") {
				NotificationPrivacyView()
			}
			navRow(title: "Accessibility") {
				AccessibilitySettingsView()
			}
			navRow(title: "Terms and Conditions") {
				TermsAndConditionsView()
			}
		}
	}

	@ViewBuilder
	private func footer() -> some View {
		VStack(spacing: 6) {
			Text("Logged in as \(signedInEmail)")
				.font(.footnote)
				.foregroundColor(.white.opacity(0.6))
			Text("Version \(appVersion)")
				.font(.footnote)
				.foregroundColor(.white.opacity(0.6))
		}
		.frame(maxWidth: .infinity)
		.padding(.top, 8)
	}

	@ViewBuilder
	private func signOutButton() -> some View {
		Button(action: {}) {
			Text("Sign Out")
				.font(.headline)
				.foregroundColor(.white)
				.frame(maxWidth: .infinity)
				.padding(.vertical, 14)
		}
		.background(Color.white.opacity(0.15))
		.cornerRadius(10)
	}

	@ViewBuilder
	private func navRow<Content: View>(title: String, @ViewBuilder destination: @escaping () -> Content) -> some View {
		NavigationLink(destination: destination().navigationBarTitleDisplayMode(.inline)) {
			HStack {
				Text(title)
					.foregroundColor(.white)
				Spacer()
				Image(systemName: "chevron.right")
					.foregroundColor(.white.opacity(0.6))
			}
			.padding(.horizontal, 16)
			.padding(.vertical, 14)
			.background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
		}
	}
}

// MARK: - Manage Subscription
struct ManageSubscriptionView: View {
	var body: some View {
		List {
			Section("Manage Subscription") {
				HStack {
					Text("Aura Premium")
					Spacer()
					Text("Annual")
				}
				HStack {
					Text("2024-2-15 – 2025-2-14")
					Spacer()
				}
			}
			Section("Aura Pledge") {
				row("2025-05", value: "$3.13")
				row("2025-06", value: "$2.21")
				row("2025-07", value: "$3.01")
			}
			Section {
				Button("Export Data") {}
				Button(role: .destructive) { } label: { Text("Delete Account").foregroundColor(.red) }
			}
		}
		.listStyle(.insetGrouped)
		.navigationTitle("Manage Subscription")
	}

	private func row(_ title: String, value: String) -> some View {
		HStack {
			Text(title)
			Spacer()
			Text(value)
		}
	}
}

// MARK: - Notification & Privacy
struct NotificationPrivacyView: View {
	@State private var proactiveCheckins: Bool = true
	@State private var weeklyInsights: Bool = true
	@State private var healthPermission: Bool = true
	@State private var cameraPermission: Bool = false

	var body: some View {
		List {
			Section {
				Toggle("Proactive Checkins", isOn: $proactiveCheckins).tint(.green)
				HStack {
					Text("Quiet Hours")
					Spacer()
					Text("12PM–10AM").foregroundColor(.secondary)
				}
				Toggle("Weekly Insights", isOn: $weeklyInsights).tint(.green)
				Toggle("HealthKit Permission", isOn: $healthPermission).tint(.green)
				Toggle("Camera Permission", isOn: $cameraPermission).tint(.green)
			}
			Section {
				NavigationLink("Privacy Policy") { Text("Privacy Policy (placeholder)").padding() }
			}
		}
		.listStyle(.insetGrouped)
		.navigationTitle("")
	}
}

// MARK: - Accessibility
struct AccessibilitySettingsView: View {
	@State private var reduceMotion: Bool = true
	@State private var highContrast: Bool = false
	@State private var voice: String = "Anna"

	var body: some View {
		List {
			Section {
				HStack { Text("Text Size"); Spacer(); Text("–").foregroundColor(.secondary) }
				HStack { Text("Aura’s Voice"); Spacer(); Text(voice).foregroundColor(.secondary) }
				HStack { Text("Speech Rate"); Spacer(); Text("1.0x").foregroundColor(.secondary) }
				Toggle("Reduce Motion", isOn: $reduceMotion).tint(.green)
				Toggle("High Contrast", isOn: $highContrast).tint(.green)
			}
		}
		.listStyle(.insetGrouped)
		.navigationTitle("")
	}
}

// MARK: - Terms & Conditions
struct TermsAndConditionsView: View {
	var body: some View {
		List {
			NavigationLink("Terms of Service") { Text("Terms of Service (placeholder)").padding() }
			NavigationLink("Medical Disclaimer") { Text("Medical Disclaimer (placeholder)").padding() }
			NavigationLink("Acknowledgements") { Text("Acknowledgements (placeholder)").padding() }
		}
		.listStyle(.insetGrouped)
		.navigationTitle("")
	}
}


