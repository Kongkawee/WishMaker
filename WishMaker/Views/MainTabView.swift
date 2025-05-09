import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            WishListView()
                .tabItem {
                    Label("Wish List", systemImage: "list.bullet")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
        }
    }
}
