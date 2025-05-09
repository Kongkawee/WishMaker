import SwiftUI

struct SplashView: View {
    @State private var isActive = false

    var body: some View {
        if isActive {
            LoginView()
        } else {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [.pink, .orange]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack {
                    Spacer()
                    Image(systemName: "star.fill") // Replace with your logo if needed
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.white)
                        .padding()
                    Text("WISH MAKER")
                        .font(.title)
                        .foregroundColor(.white)
                        .bold()
                    Spacer()
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    isActive = true
                }
            }
        }
    }
}
