import SwiftUI

struct LoadingView: View {
    @State private var opacity: Double = 0.0
    
    var body: some View {
        VStack {
            Text("Nook")
                .font(.title)
        }
        .onAppear(perform: animateAndSetDate)
    }
    
    private func animateAndSetDate() {
        withAnimation(.easeIn(duration: 1.0)) {
            opacity = 1.0
        }
        
        setCurrentDate()
    }
    
    private func setCurrentDate() {
        let today = Date()
        UserDefaults.standard.set(today, forKey: "currentDate")
    }
}
