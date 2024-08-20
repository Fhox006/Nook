import SwiftUI

struct LoadingView: View {
    @State private var opacity: Double = 0.0
    @Binding var isLoading: Bool
    
    var body: some View {
        VStack {
            Text("Nook")
                .font(.title)
                .opacity(opacity)
        }
        .onAppear {
            animateAndSetDate()
        }
    }
    
    private func animateAndSetDate() {
        withAnimation(.easeIn(duration: 1.0)) {
            opacity = 1.0
        }
        setCurrentDate()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
        }
    }
}
