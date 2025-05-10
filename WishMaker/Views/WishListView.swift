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
                        Section(header: Text("Active Wishes")) {
                            ForEach(activeWishes) { wish in
                                Button {
                                    selectedWish = wish
                                } label: {
                                    wishRow(wish)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .disabled(wish.isExpired || wish.savedAmount >= wish.price)
                            }
                            .onDelete { indexSet in
                                let wishesToDelete = indexSet.map { activeWishes[$0] }
                                for wish in wishesToDelete {
                                    if let index = account.wishes.firstIndex(where: { $0.id == wish.id }) {
                                        account.wishes.remove(at: index)
                                    }
                                }
                                account.saveToFirestore()
                            }
                        }
                    } else {
                        if !completedWishes.isEmpty {
                            Section(header: Text("Completed Wishes")) {
                                ForEach(completedWishes) { wish in
                                    wishRow(wish)
                                }
                            }
                        }

                        if !expiredWishes.isEmpty {
                            Section(header: Text("Expired Wishes")) {
                                ForEach(expiredWishes) { wish in
                                    wishRow(wish)
                                        .opacity(0.5)
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
                AddMoneySheet(wish: wish, account: account) {
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
    func wishRow(_ wish: Wish) -> some View {
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

                Text("Saved: $\(wish.savedAmount, specifier: "%.2f") / $\(wish.price, specifier: "%.2f")")
                    .font(.caption)

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

struct AddMoneySheet: View {
    var wish: Wish
    @ObservedObject var account: UserAccount
    var dismiss: () -> Void

    @State private var amountToAdd = ""

    var body: some View {
        let maxAddable = min(account.balance, wish.price - wish.savedAmount)

        VStack(spacing: 20) {
            Text("Add Money to \"\(wish.title)\"")
                .font(.headline)

            Text("Current Balance: $\(account.balance, specifier: "%.2f")")
                .font(.subheadline)

            Text("Remaining for this wish: $\(wish.price - wish.savedAmount, specifier: "%.2f")")
                .font(.subheadline)
                .foregroundColor(.gray)

            TextField("Enter amount", text: $amountToAdd)
                .keyboardType(.decimalPad)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)

            Button("Add Money") {
                if let amount = Double(amountToAdd), amount > 0 {
                    let actualAmount = min(amount, maxAddable)
                    account.addMoneyToWish(wish, amount: actualAmount)
                    dismiss()
                }
            }

            Button("Cancel", role: .cancel) {
                dismiss()
            }
        }
        .padding()
        .onChange(of: amountToAdd) { newValue in
            if let value = Double(newValue), value > maxAddable {
                amountToAdd = String(format: "%.2f", maxAddable)
            }
        }
    }
}
