import SwiftUI

class StatsManager: ObservableObject {
    @Published var correctAnswers: Int {
        didSet {
            UserDefaults.standard.set(correctAnswers, forKey: "correctAnswers")
        }
    }
    @Published var incorrectAnswers: Int {
        didSet {
            UserDefaults.standard.set(incorrectAnswers, forKey: "incorrectAnswers")
        }
    }
    @Published var totalAnswerTime: Double {
        didSet {
            UserDefaults.standard.set(totalAnswerTime, forKey: "totalAnswerTime")
        }
    }
    @Published var totalAnswers: Int {
        didSet {
            UserDefaults.standard.set(totalAnswers, forKey: "totalAnswers")
        }
    }
    
    init() {
        self.correctAnswers = UserDefaults.standard.integer(forKey: "correctAnswers")
        self.incorrectAnswers = UserDefaults.standard.integer(forKey: "incorrectAnswers")
        self.totalAnswerTime = UserDefaults.standard.double(forKey: "totalAnswerTime")
        self.totalAnswers = UserDefaults.standard.integer(forKey: "totalAnswers")
    }
    
    func addCorrectAnswer(time: Double) {
        correctAnswers += 1
        totalAnswerTime += time
        totalAnswers += 1
    }
    
    func addIncorrectAnswer(time: Double) {
        incorrectAnswers += 1
        totalAnswerTime += time
        totalAnswers += 1
    }
    
    var averageAnswerTime: Double {
        return totalAnswers > 0 ? totalAnswerTime / Double(totalAnswers) : 0
    }
}
