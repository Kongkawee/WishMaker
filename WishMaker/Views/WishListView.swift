import SwiftUI

struct WishListView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Your Wishes will appear here")
                    .font(.title3)
                    .padding()

                Spacer()
            }
            .navigationTitle("Wish Lists")
        }
    }
}
