import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import PhotosUI

struct RegisterView: View {
    @Environment(\.presentationMode) var presentationMode

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var isRegistered = false

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var isUploading = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Create Account")
                    .font(.largeTitle)
                    .bold()

                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    if let data = imageData, let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.blue)
                    }
                }

                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textFieldStyle(.roundedBorder)

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)

                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(.roundedBorder)

                Button("Register") {
                    registerUser()
                }
                .disabled(isUploading)

                if isUploading {
                    ProgressView("Uploading image...")
                }

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Register")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert(isPresented: $isRegistered) {
                Alert(
                    title: Text("Success"),
                    message: Text("Account created successfully!"),
                    dismissButton: .default(Text("OK")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
            .task(id: selectedPhoto) {
                if let data = try? await selectedPhoto?.loadTransferable(type: Data.self) {
                    imageData = data
                }
            }
        }
    }

    func registerUser() {
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }

        isUploading = true

        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                self.errorMessage = "Registration failed: \(error.localizedDescription)"
                self.isUploading = false
                return
            }

            let defaultImageURL = "https://res.cloudinary.com/dlh4tn0wq/image/upload/v1715353974/default_profile.png"

            if let data = imageData {
                uploadToCloudinary(data: data) { imageURL in
                    saveProfile(imageURL ?? defaultImageURL)
                }
            } else {
                saveProfile(defaultImageURL)
            }
        }
    }

    func saveProfile(_ imageURL: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        db.collection("users").document(userId).setData([
            "email": email,
            "balance": 0.0,
            "wishes": [],
            "moneyHistory": [],
            "profileImageURL": imageURL
        ]) { err in
            isUploading = false
            if let err = err {
                errorMessage = "Saving profile failed: \(err.localizedDescription)"
            } else {
                isRegistered = true
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
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"profile.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Upload failed:", error)
                completion(nil)
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let url = json["secure_url"] as? String else {
                print("Invalid Cloudinary response")
                completion(nil)
                return
            }

            completion(url)
        }.resume()
    }
}
