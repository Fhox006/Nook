import SwiftUI
import MessageUI

struct SettingsView: View {
    @State private var isShowingMailView = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    
    let appVersion = "Alpha 1.0.0"
    
    var body: some View {
            Form {
                Section(header: Text("Notifications")) {
                    Toggle("Daily Reminder", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { newValue in
                            if newValue {
                                requestNotificationPermission()
                            }
                        }
                }
                
                Section(header: Text("Feedback")) {
                    Button(action: {
                        isShowingMailView = true
                    }) {
                        Text("Send Feedback")
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $isShowingMailView) {
            MailView(isShowing: $isShowingMailView)
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
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: 20, minute: 0), repeats: true)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
}

struct MailView: UIViewControllerRepresentable {
    @Binding var isShowing: Bool
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients(["fedefhox@gmail.com"])
        vc.setSubject("Nook App Feedback")
        return vc
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(isShowing: $isShowing)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        @Binding var isShowing: Bool
        
        init(isShowing: Binding<Bool>) {
            _isShowing = isShowing
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            isShowing = false
        }
    }
}

