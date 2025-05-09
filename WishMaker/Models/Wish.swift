import Foundation

struct Wish: Identifiable, Codable {
    let id = UUID()
    var title: String
    var targetAmount: Double
    var savedAmount: Double = 0.0
    var imageName: String
}
