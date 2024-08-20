import SwiftUI
import MessageUI

struct SettingsView: View {
    @State private var isShowingMailView = false
    @State private var isShowingIconSelection = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    
    let appVersion = "Alpha 1.0.0"
    
    var body: some View {
        Form {
            NotificationsSection(notificationsEnabled: $notificationsEnabled)
            FeedbackSection(isShowingMailView: $isShowingMailView) // Passa il parametro corretto
            IconSection()
            AboutSection(appVersion: appVersion)
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $isShowingIconSelection) {
            IconSelectionView()
        }
    }
    
    private func IconSection() -> some View {
        Section(header: Text("App Icon")) {
            Button(action: {
                isShowingIconSelection = true
            }) {
                Text("Change App Icon")
            }
        }
    }
}

struct NotificationsSection: View {
    @Binding var notificationsEnabled: Bool
    @State private var selectedHour: Int = 8
    @State private var selectedMinute: Int = 0

    var body: some View {
        Section(header: Text("Notifications")) {
            Toggle("Daily Reminder", isOn: $notificationsEnabled)
                .onChange(of: notificationsEnabled) { newValue in
                    if newValue {
                        requestNotificationPermission()
                    } else {
                        removeNotifications()
                    }
                }
            
            if notificationsEnabled {
                HStack {
                    Picker("Hour", selection: $selectedHour) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text(String(format: "%02d", hour)).tag(hour)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(width: 60, height: 100) // Altezza ridotta per compattezza
                    
                    Picker("Minute", selection: $selectedMinute) {
                        ForEach(0..<60, id: \.self) { minute in
                            Text(String(format: "%02d", minute)).tag(minute)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(width: 60, height: 100) // Altezza ridotta per compattezza
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 10) // Spazio tra il Toggle e i Picker
                .onChange(of: selectedHour) { _ in scheduleNotification() }
                .onChange(of: selectedMinute) { _ in scheduleNotification() }
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                scheduleNotification()
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    private func scheduleNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Time to Review"
        content.body = "Don't forget to review your flashcards today!"
        content.sound = UNNotificationSound.default
        
        var dateComponents = DateComponents()
        dateComponents.hour = selectedHour
        dateComponents.minute = selectedMinute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests() // Rimuove tutte le notifiche precedenti
        UNUserNotificationCenter.current().add(request)
    }

    private func removeNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

struct FeedbackSection: View {
    @Binding var isShowingMailView: Bool
    
    var body: some View {
        Section(header: Text("Feedback")) {
            Button(action: {
                isShowingMailView = true
            }) {
                Text("Send Feedback")
            }
        }
    }
}

struct AboutSection: View {
    let appVersion: String
    
    var body: some View {
        Section(header: Text("About")) {
            HStack {
                Text("Version")
                Spacer()
                Text(appVersion)
            }
        }
    }
}

struct IconSelectionView: View {
    var body: some View {
        VStack {
            Text("Select App Icon")
                .font(.headline)
            
            Button(action: {
                changeAppIcon(to: "Icon1")
            }) {
                Text("Icon 1")
            }
            
            Button(action: {
                changeAppIcon(to: "Icon2")
            }) {
                Text("Icon 2")
            }
            
            Button(action: {
                changeAppIcon(to: "Icon3")
            }) {
                Text("Icon 3")
            }
        }
        .padding()
    }
    
    private func changeAppIcon(to iconName: String?) {
        guard UIApplication.shared.supportsAlternateIcons else {
            print("Alternate icons are not supported on this device.")
            return
        }
        
        UIApplication.shared.setAlternateIconName(iconName) { error in
            if let error = error {
                print("Error changing icon: \(error.localizedDescription)")
            } else {
                print("Icon changed successfully.")
            }
        }
    }
}
