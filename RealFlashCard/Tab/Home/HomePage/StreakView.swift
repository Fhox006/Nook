import Foundation

class StreakManager: ObservableObject {
    @Published private(set) var currentStreak: Int = 0
    @Published private(set) var lastPlayedDate: Date?
    @Published private(set) var todayStatus: DayStatus = .none
    
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        loadStreak() 
    }

    enum DayStatus {
        case none, maintained, completed
    }

    private func loadStreak() {
        currentStreak = userDefaults.integer(forKey: "currentStreak")
        lastPlayedDate = userDefaults.object(forKey: "lastPlayedDate") as? Date
    }

    private func saveStreak() {
        userDefaults.set(currentStreak, forKey: "currentStreak")
        userDefaults.set(lastPlayedDate, forKey: "lastPlayedDate")
    }

    func updateStreak(playedCards: Int, availableCards: Int) {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let lastPlayed = lastPlayedDate, Calendar.current.isDate(lastPlayed, inSameDayAs: today) {
            updateTodayStatus(playedCards: playedCards, availableCards: availableCards)
            return
        }

        updateStreakAndStatus(playedCards: playedCards, availableCards: availableCards)
        lastPlayedDate = today
        saveStreak()
    }

    private func updateStreakAndStatus(playedCards: Int, availableCards: Int) {
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
    }

    private func updateTodayStatus(playedCards: Int, availableCards: Int) {
        todayStatus = playedCards >= 3 ? .completed :
                      availableCards < 3 ? .maintained : .none
    }
}
