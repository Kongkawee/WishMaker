import SwiftUI

struct CreateWishView: View {
    @ObservedObject var account: UserAccount
    @State private var title = ""
    @State private var target = ""
    @State private var imageName = "gift"

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        Form {
            Section(header: Text("Wish Details")) {
                TextField("Wish Title", text: $title)
                TextField("Target Amount", text: $target)
                    .keyboardType(.decimalPad)
            }

            Section(header: Text("Image Icon (system name)")) {
                TextField("Image Name (e.g., gift)", text: $imageName)
                Image(systemName: imageName)
                    .resizable()
                    .frame(width: 50, height: 50)
                    .padding(.top, 8)
            }

            Button("Add Wish") {
                if let targetAmount = Double(target), !title.isEmpty {
                    account.createWish(title: title, target: targetAmount, image: imageName)
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .navigationTitle("Create Wish")
    }
}

