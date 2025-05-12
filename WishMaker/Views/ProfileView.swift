import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var account: UserAccount
    @State private var showAddMoneyAlert = false
    @State private var moneyToAdd = ""
    @State private var isLoggedOut = false

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.pink, .orange]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                if let user = Auth.auth().currentUser {
                    // Profile Image
                    profileImage

                    // Email & Balance
                    Text(user.email ?? "No Email")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("Current Balance: ฿\(account.balance, specifier: "%.2f")")
                        .font(.title3)
                        .bold()
                        .foregroundColor(.white)

                    // Add Money Button
                    Button("Add Money") {
                        showAddMoneyAlert = true
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .alert("Add Money", isPresented: $showAddMoneyAlert, actions: {
                        TextField("Amount", text: $moneyToAdd)
                            .keyboardType(.decimalPad)
                        Button("Add") {
                            if let amount = Double(moneyToAdd), amount > 0 {
                                account.addFunds(amount: amount)
                            }
                            moneyToAdd = ""
                        }
                        Button("Cancel", role: .cancel) {
                            moneyToAdd = ""
                        }
                    }, message: {
                        Text("Enter the amount to add to your balance.")
                    })

                    // Transaction History Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Transaction History")
                            .font(.headline)
                            .foregroundColor(.white)

                        ScrollView {
                            VStack(spacing: 12) {
                                if account.moneyHistory.isEmpty {
                                    Text("No transactions yet.")
                                        .foregroundColor(.white.opacity(0.7))
                                } else {
                                    ForEach(account.moneyHistory.sorted(by: { $0.date > $1.date })) { transaction in
                                        VStack(alignment: .leading) {
                                            Text("\(transaction.amount >= 0 ? "+ ฿" : "- ฿")\(abs(transaction.amount), specifier: "%.2f")")
                                                .foregroundColor(transaction.amount >= 0 ? .green : .red)
                                            Text(transaction.date.formatted(date: .abbreviated, time: .shortened))
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding()
                                        .background(Color.white.opacity(0.95))
                                        .cornerRadius(10)
                                    }
                                }
                            }
                            .padding(.bottom)
                        }
                    }
                    .frame(maxHeight: .infinity)
                    .padding(.top)

                    // Sign Out Button
                    Button(action: {
                        do {
                            try Auth.auth().signOut()
                            isLoggedOut = true
                        } catch {
                            print("Error signing out: \(error.localizedDescription)")
                        }
                    }) {
                        Text("Sign Out")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    .padding(.bottom, 16)
                } else {
                    Text("No user logged in.")
                        .foregroundColor(.white)
                }
            }
            .padding()
        }
        .fullScreenCover(isPresented: $isLoggedOut) {
            LoginView()
                .environmentObject(account)
        }
    }

    var profileImage: some View {
        Group {
            if let urlString = account.profileImageURL,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 3))
                    case .failure:
                        fallbackProfileImage
                    @unknown default:
                        fallbackProfileImage
                    }
                }
            } else {
                fallbackProfileImage
            }
        }
    }

    var fallbackProfileImage: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .frame(width: 100, height: 100)
            .foregroundColor(.white)
            .overlay(Circle().stroke(Color.white, lineWidth: 3))
    }
}
