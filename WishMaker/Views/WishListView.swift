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
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [.pink, .orange]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                VStack(spacing: 10) {
                    HStack {
                            Text("Wish Lists")
                                .font(.largeTitle)
                                .bold()
                                .foregroundColor(.white)

                            Spacer()

                            Button(showCompleted ? "Show Active" : "Show Completed") {
                                showCompleted.toggle()
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                    // Category Filter Bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            Button("All") {
                                selectedCategory = nil
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                            .background(selectedCategory == nil ? Color.white.opacity(0.9) : Color.white.opacity(0.3))
                            .cornerRadius(20)
                            .foregroundColor(.pink)
                            
                            ForEach(uniqueCategories(), id: \.self) { category in
                                Button(category) {
                                    selectedCategory = category
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 6)
                                .background(selectedCategory == category ? Color.white.opacity(0.9) : Color.white.opacity(0.3))
                                .cornerRadius(20)
                                .foregroundColor(.pink)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top)
                    }
                    
                    // Wish List Section
                    ScrollView {
                        VStack(spacing: 12) {
                            let wishesByCategory = account.wishes.filter { selectedCategory == nil || $0.category == selectedCategory }
                            let active = wishesByCategory.filter { !$0.isExpired && $0.savedAmount < $0.price }
                            let completed = wishesByCategory.filter { $0.savedAmount >= $0.price }
                            let expired = wishesByCategory.filter { $0.isExpired && $0.savedAmount < $0.price }
                            
                            if !showCompleted {
                                if active.isEmpty {
                                    Text("No active wishes 🎯")
                                        .foregroundColor(.white)
                                }
                                ForEach(active) { wish in
                                    wishCard(wish: wish)
                                }
                            } else {
                                if completed.isEmpty && expired.isEmpty {
                                    Text("No completed or expired wishes 😅")
                                        .foregroundColor(.white)
                                }
                                if !completed.isEmpty {
                                    Text("✅ Completed Wishes")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.top, 10)
                                        .padding(.horizontal)

                                    ForEach(completed) { wish in
                                        wishCard(wish: wish)
                                    }
                                }

                                if !expired.isEmpty {
                                    Text("❌ Expired Wishes")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.top, 10)
                                        .padding(.horizontal)

                                    ForEach(expired) { wish in
                                        wishCard(wish: wish)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 80) // For floating button spacing
                    }
                }
                
                // Floating "+" button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showAddWish = true
                        } label: {
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding()
                    }
                }
                    .background(Color.gray.opacity(0.3))
            }
            .fullScreenCover(isPresented: $showAddWish) {
                CreateWishView(account: account, dismiss: { showAddWish = false })
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
    func wishCard(wish: Wish) -> some View {
        let fundable = showCompleted ? wish.savedAmount : min(account.balance, wish.price)
        
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                AsyncImage(url: URL(string: wish.imageURL)) { phase in
                    if let image = try? phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipped()
                            .cornerRadius(10)
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .cornerRadius(10)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(wish.title)
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Text("Category: \(wish.category)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text(wish.description)
                        .font(.footnote)
                        .foregroundColor(.black)
                    
                    // Fundable bar
                    ProgressView(value: fundable, total: wish.price)
                        .accentColor(fundable >= wish.price ? .pink : .pink)
                    
                    Text("Fundable: ฿\(fundable, specifier: "%.2f") / ฿\(wish.price, specifier: "%.2f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
            
            if wish.isExpired {
                Text("Expired")
                    .font(.caption)
                    .foregroundColor(.red)
            } else {
                Text("Due: \(wish.finalDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .onTapGesture {
            let remaining = wish.price - wish.savedAmount
            if !showCompleted && account.balance >= remaining && !wish.isExpired {
                selectedWish = wish
            }
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
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [.pink, .orange]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Edit Due Date")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    DatePicker("New Final Date", selection: $newDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                    
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
                .background(Color.white.opacity(0.95))
                .cornerRadius(16)
                .shadow(radius: 10)
                .padding()
            }
        }
    }
    
    struct ConfirmFundSheet: View {
        var wish: Wish
        @ObservedObject var account: UserAccount
        var dismiss: () -> Void
        
        var body: some View {
            let amountToAdd = min(account.balance, wish.price - wish.savedAmount)
            
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [.pink, .orange]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
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
                        .font(.title3)
                        .fontWeight(.bold)
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
                        
                        Text("Cost: ฿\(wish.price, specifier: "%.2f")")
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
                .background(Color.white.opacity(0.95))
                .cornerRadius(16)
                .shadow(radius: 10)
                .padding()
            }
        }
    }
}
