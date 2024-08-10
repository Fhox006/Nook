import Foundation

class StreakManager: ObservableObject {
    @Published var currentStreak: Int = 0
    @Published var lastPlayedDate: Date?
    @Published var todayStatus: DayStatus = .none

    enum DayStatus {
        case none
        case maintained
        case completed
    }

    init() {
        loadStreak()
    }

    func loadStreak() {
        currentStreak = UserDefaults.standard.integer(forKey: "currentStreak")
        lastPlayedDate = UserDefaults.standard.object(forKey: "lastPlayedDate") as? Date
    }

    func saveStreak() {
        UserDefaults.standard.set(currentStreak, forKey: "currentStreak")
        UserDefaults.standard.set(lastPlayedDate, forKey: "lastPlayedDate")
    }

    func updateStreak(playedCards: Int, availableCards: Int) {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let lastPlayed = lastPlayedDate, Calendar.current.isDate(lastPlayed, inSameDayAs: today) {
            // Already updated today, just update the status
            updateTodayStatus(playedCards: playedCards, availableCards: availableCards)
            return
        }

        if playedCards >= 3 {
            currentStreak += 1
            todayStatus = .completed
        } else if availableCards < 3 {
            currentStreak += 1
            todayStatus = .maintained
        } else {
            currentStreak = 0
            todayStatus = .none
        }

        lastPlayedDate = today
        saveStreak()
    }

    func updateTodayStatus(playedCards: Int, availableCards: Int) {
        if playedCards >= 3 {
            todayStatus = .completed
        } else if availableCards < 3 {
            todayStatus = .maintained
        } else {
            todayStatus = .none
        }
    }
}
