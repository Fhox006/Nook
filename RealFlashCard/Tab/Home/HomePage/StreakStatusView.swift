import SwiftUI

struct StreakStatusView: View {
    let streak: Int
    
    var body: some View {
        HStack {
            Text("Current Streak: \(streak)")
                .font(.subheadline)
            
            Spacer()
            
            HStack {
                ForEach(0..<7) { index in
                    Circle()
                        .frame(width: 20, height: 20)
                        .foregroundColor(index < streak % 7 ? .blue : .gray)
                }
            }
        }
    }
}
