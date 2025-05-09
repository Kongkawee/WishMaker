import Foundation
import Combine

class UserAccount: ObservableObject {
    @Published var balance: Double = 0.0
    @Published var wishes: [Wish] = []

    func addFunds(amount: Double) {
        balance += amount
    }

    func createWish(title: String, target: Double, image: String) {
        let newWish = Wish(title: title, targetAmount: target, imageName: image)
        wishes.append(newWish)
    }

    func addMoneyToWish(_ wish: Wish, amount: Double) {
        guard let index = wishes.firstIndex(where: { $0.id == wish.id }),
              amount <= balance else { return }

        wishes[index].savedAmount += amount
        balance -= amount
    }
}
