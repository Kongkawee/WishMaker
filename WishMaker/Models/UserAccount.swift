import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

class UserAccount: ObservableObject {
    @Published var balance: Double = 0.0
    @Published var wishes: [Wish] = []

    private var db = Firestore.firestore()

    func addFunds(amount: Double) {
        balance += amount
        saveToFirestore()
    }

    func createWish(title: String, target: Double, image: String) {
        let newWish = Wish(title: title, targetAmount: target, imageName: image)
        wishes.append(newWish)
        saveToFirestore()
    }

    func addMoneyToWish(_ wish: Wish, amount: Double) {
        guard let index = wishes.firstIndex(where: { $0.id == wish.id }),
              amount <= balance else { return }

        wishes[index].savedAmount += amount
        balance -= amount
        saveToFirestore()
    }

    func saveToFirestore() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let data: [String: Any] = [
            "balance": balance,
            "wishes": wishes.map { $0.toDict() }
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
            }
        }
    }
}
