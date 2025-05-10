import SwiftUI
import PhotosUI
import FirebaseStorage
import FirebaseAuth

struct CreateWishView: View {
    @ObservedObject var account: UserAccount
    @Environment(\.presentationMode) var presentationMode

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
        NavigationView {
            Form {
                Section(header: Text("Wish Info")) {
                    TextField("Title", text: $title)
                    TextField("Category", text: $category)
                    TextField("Description", text: $description)
                    TextField("Price", text: $price)
                        .keyboardType(.decimalPad)
                    DatePicker("Final Date", selection: $finalDate, displayedComponents: .date)
                }

                Section(header: Text("Wish Image")) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("Select a Photo", systemImage: "photo")
                    }
                    if let data = imageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                    }
                }

                if isUploading {
                    ProgressView("Uploading...")
                } else {
                    Button("Add Wish") {
                        guard let priceValue = Double(price), !title.isEmpty, !category.isEmpty, !description.isEmpty else {
                            errorMessage = "Please fill out all required fields."
                            return
                        }
                        guard let data = imageData else {
                            errorMessage = "Please select an image."
                            return
                        }
                        print("🧾 Current user ID:", Auth.auth().currentUser?.uid ?? "nil")
                        uploadToCloudinary(data: data) { url in
                            if let imageURL = url {
                                account.createWish(
                                    title: title,
                                    category: category,
                                    description: description,
                                    price: priceValue,
                                    finalDate: finalDate,
                                    imageURL: imageURL
                                )
                                presentationMode.wrappedValue.dismiss()
                            } else {
                                errorMessage = "Image upload failed. Please try again."
                            }
                        }
                    }
                    .disabled(imageData == nil || isUploading)
                }

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Create Wish")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .task(id: selectedPhoto) {
                do {
                    if let data = try await selectedPhoto?.loadTransferable(type: Data.self) {
                        imageData = data
                        print("✅ Image loaded successfully, size: \(data.count) bytes")
                    }
                } catch {
                    errorMessage = "Image load error: \(error.localizedDescription)"
                }
            }
        }
    }

    func uploadToCloudinary(data: Data, completion: @escaping (String?) -> Void) {
        isUploading = true
        let cloudName = "dlh4tn0wq"
        let uploadPreset = "wishmaker_unsigned"  // see step 4

        let url = URL(string: "https://api.cloudinary.com/v1_1/\(cloudName)/image/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add upload_preset
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"upload_preset\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(uploadPreset)\r\n".data(using: .utf8)!)

        // Add image file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"wish.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            isUploading = false
            if let error = error {
                print("❌ Cloudinary upload failed:", error.localizedDescription)
                completion(nil)
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let url = json["secure_url"] as? String else {
                print("❌ Invalid Cloudinary response")
                completion(nil)
                return
            }

            print("✅ Uploaded to Cloudinary:", url)
            completion(url)
        }.resume()
    }

}
