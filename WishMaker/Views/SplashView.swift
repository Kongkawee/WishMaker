import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @Namespace private var animation

    var body: some View {
        ZStack {
            if isActive {
                LoginView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
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
                        Image(systemName: "star.fill")
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
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.6), value: isActive)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                isActive = true
            }
        }
    }
}
