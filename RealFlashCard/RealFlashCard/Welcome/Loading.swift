import SwiftUI

struct LoadingView: View {
    var body: some View {
        return Text("Nook")
            .font(.largeTitle)
            .fontWeight(.bold)
            .onAppear {
                let today = Date()
                UserDefaults.standard.set(today, forKey: "currentDate")
            }
    }
}
