import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var account: UserAccount
    @State private var showAddMoneyAlert = false
    @State private var moneyToAdd = ""
    @State private var isLoggedOut = false

    var body: some View {
        VStack(spacing: 20) {
            if let user = Auth.auth().currentUser {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)

                Text(user.email ?? "No Email")
                    .font(.headline)

                Text("Current Balance: $\(account.balance, specifier: "%.2f")")
                    .font(.title3)
                    .padding()

                Button("Add Money") {
                    showAddMoneyAlert = true
                }
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
                Text("Transaction History")
                    .font(.headline)
                    .padding(.top)

                List(account.moneyHistory.sorted(by: { $0.date > $1.date })) { transaction in
                    VStack(alignment: .leading) {
                        Text("\(transaction.amount >= 0 ? "+ $" : "- $")\(abs(transaction.amount), specifier: "%.2f")")
                            .foregroundColor(transaction.amount >= 0 ? .green : .red)
                        Text(transaction.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .frame(height: 200) // Or scrollable height as needed
                Button("Sign Out") {
                    do {
                        try Auth.auth().signOut()
                        isLoggedOut = true
                    } catch {
                        print("Error signing out: \(error.localizedDescription)")
                    }
                }
            } else {
                Text("No user logged in.")
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Profile")
        .fullScreenCover(isPresented: $isLoggedOut) {
            LoginView()
                .environmentObject(account)
        }
    }
}
