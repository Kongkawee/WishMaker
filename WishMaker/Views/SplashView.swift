import SwiftUI
import FirebaseAuth

struct SplashView: View {
    @State private var isActive = false
    @EnvironmentObject var account: UserAccount

    var body: some View {
        ZStack {
            if isActive {
                if Auth.auth().currentUser != nil {
                    MainTabView() // Already logged in
                        .environmentObject(account)
                        .onAppear {
                            account.loadFromFirestore()
                        }
                } else {
                    LoginView()
                        .environmentObject(account)
                }
            } else {
                splashScreen
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                isActive = true
            }
        }
    }

    var splashScreen: some View {
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
    }
}
