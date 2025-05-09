import Foundation

struct Wish: Identifiable, Codable {
    let id = UUID()
    var title: String
    var targetAmount: Double
    var savedAmount: Double = 0.0
    var imageName: String

    func toDict() -> [String: Any] {
        return [
            "id": id.uuidString,
            "title": title,
            "targetAmount": targetAmount,
            "savedAmount": savedAmount,
            "imageName": imageName
        ]
    }

    static func fromDict(_ dict: [String: Any]) -> Wish? {
        guard let title = dict["title"] as? String,
              let target = dict["targetAmount"] as? Double,
              let saved = dict["savedAmount"] as? Double,
              let image = dict["imageName"] as? String else { return nil }

        return Wish(title: title, targetAmount: target, savedAmount: saved, imageName: image)
    }
}
