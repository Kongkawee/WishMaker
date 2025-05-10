import Foundation

struct MoneyTransaction: Identifiable, Codable {
    var id = UUID()
    var amount: Double
    var date: Date
    var wishTitle: String?

    func toDict() -> [String: Any] {
        return [
            "id": id.uuidString,
            "amount": amount,
            "date": date.timeIntervalSince1970
        ]
    }

    static func fromDict(_ dict: [String: Any]) -> MoneyTransaction? {
        guard let amount = dict["amount"] as? Double,
              let timestamp = dict["date"] as? TimeInterval else { return nil }
        return MoneyTransaction(amount: amount, date: Date(timeIntervalSince1970: timestamp))
    }
}
