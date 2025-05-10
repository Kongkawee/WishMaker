import SwiftUI

struct WishListView: View {
    @EnvironmentObject var account: UserAccount
    @State private var showAddWish = false
    @State private var selectedWish: Wish? = nil
    @State private var showCompleted = false
    @State private var selectedCategory: String? = nil
    @State private var wishToDelete: Wish? = nil
    @State private var wishToEditDate: Wish? = nil

    var body: some View {
        NavigationView {
            VStack {
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
                    let expiredWishes = wishesByCategory.filter { $0.isExpired && $0.savedAmount < $0.price }

                    if !showCompleted {
                        Section(header: Text("Available Wishes")) {
                            ForEach(activeWishes) { wish in
                                let canFund = account.balance >= wish.price
                                let funding = min(account.balance, wish.price)
                                let disabled = !canFund || wish.savedAmount >= wish.price

                                wishRow(wish: wish, availableFunds: funding) {
                                    if !disabled {
                                        selectedWish = wish
                                    }
                                }
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
            .sheet(isPresented: $showAddWish, onDismiss: {
                account.loadFromFirestore()
            }) {
                CreateWishView(account: account)
                    .environmentObject(account)
            }
            .sheet(item: $selectedWish) { wish in
                ConfirmFundSheet(wish: wish, account: account) {
                    selectedWish = nil
                }
            }
            .alert(item: $wishToDelete) { wish in
                Alert(
                    title: Text("Delete Wish"),
                    message: Text("Are you sure you want to delete \"\(wish.title)\"?"),
                    primaryButton: .destructive(Text("Delete")) {
                        if let index = account.wishes.firstIndex(where: { $0.id == wish.id }) {
                            account.wishes.remove(at: index)
                            account.saveToFirestore()
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            .sheet(item: $wishToEditDate) { wish in
                EditDateSheet(wish: wish, account: account) {
                    wishToEditDate = nil
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
    func wishRow(wish: Wish, availableFunds: Double, onTap: @escaping () -> Void = {}) -> some View {
        HStack(alignment: .top, spacing: 10) {
            HStack(spacing: 10) {
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
                    Text("Fundable: ฿\(shownAmount, specifier: "%.2f") / ฿\(wish.price, specifier: "%.2f")")
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
            .onTapGesture {
                onTap()
            }

            Spacer()

            VStack(spacing: 5) {
                if wish.savedAmount < wish.price {
                    Button {
                        wishToEditDate = wish
                    } label: {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    wishToDelete = wish
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 5)
    }
}

struct EditDateSheet: View {
    var wish: Wish
    @ObservedObject var account: UserAccount
    @State private var newDate: Date
    var dismiss: () -> Void

    init(wish: Wish, account: UserAccount, dismiss: @escaping () -> Void) {
        self.wish = wish
        self._newDate = State(initialValue: wish.finalDate)
        self.account = account
        self.dismiss = dismiss
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Due Date")
                .font(.headline)

            DatePicker("New Final Date", selection: $newDate, displayedComponents: .date)

            HStack {
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                Spacer()
                Button("Save") {
                    if let index = account.wishes.firstIndex(where: { $0.id == wish.id }) {
                        account.wishes[index].finalDate = newDate
                        account.saveToFirestore()
                        account.loadFromFirestore()
                    }
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(maxWidth: 400)
    }
}

struct ConfirmFundSheet: View {
    var wish: Wish
    @ObservedObject var account: UserAccount
    var dismiss: () -> Void

    var body: some View {
        let amountToAdd = min(account.balance, wish.price - wish.savedAmount)

        VStack(spacing: 20) {
            AsyncImage(url: URL(string: wish.imageURL)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 100, height: 100)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipped()
                        .cornerRadius(12)
                case .failure:
                    Image(systemName: "photo")
                        .resizable()
                        .frame(width: 100, height: 100)
                @unknown default:
                    EmptyView()
                }
            }

            Text("Fulfill \"\(wish.title)\"?")
                .font(.headline)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 8) {
                Text("Category: \(wish.category)")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Text(wish.description)
                    .font(.body)

                Text("Due: \(wish.finalDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("Price: ฿\(wish.savedAmount, specifier: "%.2f") / ฿\(wish.price, specifier: "%.2f")")
                    .font(.caption)

                Text("This will deduct ฿\(amountToAdd, specifier: "%.2f") from your balance.")
                    .font(.subheadline)
                    .bold()
                    .padding(.top, 10)
            }

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
        .frame(maxWidth: 400)
    }
}

