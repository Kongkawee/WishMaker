import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    var body: some View {
        VStack(spacing: 20) {
            if let user = Auth.auth().currentUser {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)

                Text(user.email ?? "No Email")
                    .font(.headline)

                Button("Add Money") {
                    // TODO: navigate to AddMoneyView
                }

                Button("Sign Out") {
                    try? Auth.auth().signOut()
                    // You may want to trigger logout logic here
                }
            } else {
                Text("No user logged in.")
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Profile")
    }
}
