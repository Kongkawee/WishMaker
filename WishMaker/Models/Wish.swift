import Foundation

struct Wish: Identifiable, Codable {
    let id: UUID
    var title: String
    var category: String
    var description: String
    var price: Double
    var savedAmount: Double
    var finalDate: Date
    var imageURL: String
    var isExpired: Bool {
        return finalDate < Date() && savedAmount < price
    }

    init(title: String, category: String, description: String, price: Double, savedAmount: Double = 0.0, finalDate: Date, imageURL: String) {
        self.id = UUID()
        self.title = title
        self.category = category
        self.description = description
        self.price = price
        self.savedAmount = savedAmount
        self.finalDate = finalDate
        self.imageURL = imageURL
    }

    func toDict() -> [String: Any] {
        return [
            "id": id.uuidString,
            "title": title,
            "category": category,
            "description": description,
            "price": price,
            "savedAmount": savedAmount,
            "finalDate": finalDate.timeIntervalSince1970,
            "imageURL": imageURL
        ]
    }

    static func fromDict(_ dict: [String: Any]) -> Wish? {
        guard let idString = dict["id"] as? String,
              let id = UUID(uuidString: idString),
              let title = dict["title"] as? String,
              let category = dict["category"] as? String,
              let description = dict["description"] as? String,
              let price = dict["price"] as? Double,
              let savedAmount = dict["savedAmount"] as? Double,
              let timestamp = dict["finalDate"] as? TimeInterval,
              let imageURL = dict["imageURL"] as? String
        else { return nil }

        return Wish(
            title: title,
            category: category,
            description: description,
            price: price,
            savedAmount: savedAmount,
            finalDate: Date(timeIntervalSince1970: timestamp),
            imageURL: imageURL
        )
    }
}
