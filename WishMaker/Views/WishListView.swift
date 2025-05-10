import SwiftUI

struct WishListView: View {
    @EnvironmentObject var account: UserAccount
    @State private var showAddWish = false
    @State private var selectedWish: Wish? = nil
    @State private var showCompleted = false
    @State private var selectedCategory: String? = nil

    var body: some View {
        NavigationView {
            VStack {
                // Category filter bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        Button("All") {
                            selectedCategory = nil
                        }
                        .padding(.horizontal)
                        .background(selectedCategory == nil ? Color.blue.opacity(0.2) : Color.clear)
                        .cornerRadius(8)

                        ForEach(uniqueCategories(), id: \.self) { category in
                            Button(category) {
                                selectedCategory = category
                            }
                            .padding(.horizontal)
                            .background(selectedCategory == category ? Color.blue.opacity(0.2) : Color.clear)
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                }

                List {
                    let wishesByCategory = account.wishes.filter { wish in
                        selectedCategory == nil || wish.category == selectedCategory
                    }

                    let activeWishes = wishesByCategory.filter { !$0.isExpired && $0.savedAmount < $0.price }
                    let completedWishes = wishesByCategory.filter { $0.savedAmount >= $0.price }
                    let expiredWishes = wishesByCategory.filter { $0.isExpired }

                    if !showCompleted {
                        Section(header: Text("Available Wishes")) {
                            ForEach(activeWishes) { wish in
                                let canFund = account.balance >= wish.price
                                let funding = min(account.balance, wish.price)
                                let disabled = !canFund || wish.isExpired || wish.savedAmount >= wish.price

                                wishRow(wish: wish, availableFunds: funding)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if !disabled {
                                            selectedWish = wish
                                        }
                                    }
                                    .allowsHitTesting(!disabled)
                            }
                        }
                    } else {
                        if !completedWishes.isEmpty {
                            Section(header: Text("Completed Wishes")) {
                                ForEach(completedWishes) { wish in
                                    wishRow(wish: wish, availableFunds: wish.price)
                                }
                            }
                        }

                        if !expiredWishes.isEmpty {
                            Section(header: Text("Expired Wishes")) {
                                ForEach(expiredWishes) { wish in
                                    wishRow(wish: wish, availableFunds: 0)
                                        .allowsHitTesting(false)
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Wish List")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(showCompleted ? "Show Active" : "Show Completed") {
                        showCompleted.toggle()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddWish = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddWish) {
                CreateWishView(account: account)
                    .environmentObject(account)
            }
            .sheet(item: $selectedWish) { wish in
                ConfirmFundSheet(wish: wish, account: account) {
                    selectedWish = nil
                }
            }
        }
    }

    func uniqueCategories() -> [String] {
        let relevantWishes = showCompleted
            ? account.wishes.filter { $0.savedAmount >= $0.price || $0.isExpired }
            : account.wishes.filter { !$0.isExpired && $0.savedAmount < $0.price }

        let categories = relevantWishes.map { $0.category }
        return Array(Set(categories)).sorted()
    }

    @ViewBuilder
    func wishRow(wish: Wish, availableFunds: Double) -> some View {
        HStack(alignment: .top, spacing: 10) {
            AsyncImage(url: URL(string: wish.imageURL)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 60, height: 60)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipped()
                        .cornerRadius(8)
                case .failure:
                    Image(systemName: "photo")
                        .resizable()
                        .frame(width: 60, height: 60)
                @unknown default:
                    EmptyView()
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(wish.title)
                    .font(.headline)

                Text("Category: \(wish.category)")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Text(wish.description)
                    .font(.subheadline)

                let shownAmount = min(availableFunds, wish.price)
                Text("Fundable: $\(shownAmount, specifier: "%.2f") / $\(wish.price, specifier: "%.2f")")
                    .font(.caption)

                ProgressView(value: shownAmount, total: wish.price)
                    .progressViewStyle(LinearProgressViewStyle(tint: shownAmount >= wish.price ? .green : .blue))

                if wish.isExpired {
                    Text("Expired")
                        .font(.caption)
                        .foregroundColor(.red)
                        .bold()
                } else {
                    Text("Due: \(wish.finalDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 5)
    }
}

struct ConfirmFundSheet: View {
    var wish: Wish
    @ObservedObject var account: UserAccount
    var dismiss: () -> Void

    var body: some View {
        let amountToAdd = min(account.balance, wish.price - wish.savedAmount)

        VStack(spacing: 20) {
            Text("Fulfill \"\(wish.title)\"?")
                .font(.headline)
                .multilineTextAlignment(.center)

            Text("This will deduct $\(amountToAdd, specifier: "%.2f") from your balance.")
                .font(.subheadline)

            HStack(spacing: 20) {
                Button("Cancel", role: .cancel) {
                    dismiss()
                }

                Button("Confirm") {
                    account.addMoneyToWish(wish, amount: amountToAdd)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}
