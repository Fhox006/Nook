import SwiftUI

struct StatsView: View {
    @EnvironmentObject var statsManager: StatsManager
    
    var body: some View {
        List {
            Section(header: Text("Answer Statistics")) {
                HStack {
                    Text("Correct Answers")
                    Spacer()
                    Text("\(statsManager.correctAnswers)")
                }
                HStack {
                    Text("Incorrect Answers")
                    Spacer()
                    Text("\(statsManager.incorrectAnswers)")
                }
            }
            
            Section(header: Text("Time Statistics")) {
                HStack {
                    Text("Average Answer Time")
                    Spacer()
                    Text(String(format: "%.2f seconds", statsManager.averageAnswerTime))
                }
            }
        }
        .navigationTitle("Statistics")
    }
}
