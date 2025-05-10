import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

class UserAccount: ObservableObject {
    @Published var balance: Double = 0.0
    @Published var wishes: [Wish] = []
    @Published var moneyHistory: [MoneyTransaction] = []

    private var db = Firestore.firestore()
    
    var completedWishes: [Wish] {
        wishes.filter { $0.savedAmount >= $0.price }
    }

    var activeWishes: [Wish] {
        wishes.filter { $0.savedAmount < $0.price }
    }

    func addFunds(amount: Double) {
        balance += amount
        moneyHistory.append(MoneyTransaction(amount: amount, date: Date()))
        saveToFirestore()
    }


    func createWish(title: String, category: String, description: String, price: Double, finalDate: Date, imageURL: String) {
        let newWish = Wish(
            title: title,
            category: category,
            description: description,
            price: price,
            savedAmount: 0.0,
            finalDate: finalDate,
            imageURL: imageURL
        )
        wishes.append(newWish)
        saveToFirestore()
    }

    func addMoneyToWish(_ wish: Wish, amount: Double) {
        guard let index = wishes.firstIndex(where: { $0.id == wish.id }),
              amount <= balance else { return }

        wishes[index].savedAmount += amount
        balance -= amount

        // ✅ Log a transaction
        let transaction = MoneyTransaction(amount: -amount, date: Date(), wishTitle: wish.title)
        moneyHistory.append(transaction)

        saveToFirestore()
    }

    func saveToFirestore() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let data: [String: Any] = [
            "balance": balance,
            "wishes": wishes.map { $0.toDict() },
            "moneyHistory": moneyHistory.map { $0.toDict() }
        ]

        db.collection("users").document(userId).setData(data, merge: true)
    }

    func loadFromFirestore() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(userId).getDocument { snapshot, error in
            if let data = snapshot?.data() {
                self.balance = data["balance"] as? Double ?? 0.0
                if let wishesData = data["wishes"] as? [[String: Any]] {
                    self.wishes = wishesData.compactMap { Wish.fromDict($0) }
                }
                if let historyData = data["moneyHistory"] as? [[String: Any]] {
                    self.moneyHistory = historyData.compactMap { MoneyTransaction.fromDict($0) }
                }
            }
        }
    }
}
