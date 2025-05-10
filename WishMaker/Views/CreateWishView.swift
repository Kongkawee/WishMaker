import SwiftUI
import PhotosUI
import FirebaseStorage
import FirebaseAuth

struct CreateWishView: View {
    @ObservedObject var account: UserAccount
    var dismiss: () -> Void

    @State private var title = ""
    @State private var category = ""
    @State private var description = ""
    @State private var price = ""
    @State private var finalDate = Date()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var isUploading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                gradient: Gradient(colors: [.pink, .orange]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack {
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Create a Wish")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.white)
                            .padding(.top)

                        VStack(spacing: 16) {
                            textField("Title", text: $title, icon: "pencil")
                            textField("Category", text: $category, icon: "tag")
                            textField("Description", text: $description, icon: "quote.bubble")
                            textField("Price", text: $price, icon: "dollarsign.circle")
                                .keyboardType(.decimalPad)

                            DatePicker("Final Date", selection: $finalDate, displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .padding(.horizontal)

                            VStack {
                                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                    Label("Select a Photo", systemImage: "photo")
                                        .foregroundColor(.blue)
                                }

                                if let data = imageData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 150)
                                        .cornerRadius(12)
                                        .shadow(radius: 5)
                                }
                            }

                            if isUploading {
                                ProgressView("Uploading...")
                            }

                            Button("Add Wish") {
                                addWish()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .disabled(isUploading || imageData == nil)

                            if let error = errorMessage {
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.95))
                        .cornerRadius(20)
                        .padding()
                    }
                }

                // Fixed Cancel Button at Bottom
                Button(action: dismiss) {
                    Text("Cancel")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding([.horizontal, .bottom])
                }
            }
            .task(id: selectedPhoto) {
                do {
                    if let data = try await selectedPhoto?.loadTransferable(type: Data.self) {
                        imageData = data
                    }
                } catch {
                    errorMessage = "Image load error: \(error.localizedDescription)"
                }
            }
        }
    }

    func textField(_ placeholder: String, text: Binding<String>, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
            TextField(placeholder, text: text)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }

    func addWish() {
        guard let priceValue = Double(price),
              !title.isEmpty,
              !category.isEmpty,
              !description.isEmpty else {
            errorMessage = "Please fill out all required fields."
            return
        }

        guard let data = imageData else {
            errorMessage = "Please select an image."
            return
        }

        isUploading = true
        uploadToCloudinary(data: data) { url in
            isUploading = false
            if let imageURL = url {
                account.createWish(
                    title: title,
                    category: category,
                    description: description,
                    price: priceValue,
                    finalDate: finalDate,
                    imageURL: imageURL
                )
                dismiss()
            } else {
                errorMessage = "Image upload failed. Please try again."
            }
        }
    }

    func uploadToCloudinary(data: Data, completion: @escaping (String?) -> Void) {
        let cloudName = "dlh4tn0wq"
        let uploadPreset = "wishmaker_unsigned"

        let url = URL(string: "https://api.cloudinary.com/v1_1/\(cloudName)/image/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"upload_preset\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(uploadPreset)\r\n".data(using: .utf8)!)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"wish.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Upload failed:", error.localizedDescription)
                completion(nil)
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let url = json["secure_url"] as? String else {
                completion(nil)
                return
            }

            completion(url)
        }.resume()
    }
}
