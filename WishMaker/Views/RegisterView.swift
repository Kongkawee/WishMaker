import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import PhotosUI
    
struct RegisterView: View {
    var dismiss: () -> Void
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var isRegistered = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var isUploading = false

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.pink, .orange]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                Text("Create Account")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    if let data = imageData, let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 4))
                    } else {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }

                VStack(spacing: 16) {
                    textFieldWithIcon("Email", systemImage: "envelope", text: $email)
                    secureFieldWithIcon("Password", systemImage: "lock", text: $password)
                    secureFieldWithIcon("Confirm Password", systemImage: "lock.rotation", text: $confirmPassword)

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }

                    if isUploading {
                        ProgressView("Uploading...")
                    }

                    Button("Register") {
                        registerUser()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)

                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.9))
                }
                .padding()
                .background(Color.white.opacity(0.2))
                .cornerRadius(20)
                .padding(.horizontal, 30)

                Spacer()
            }
            .task(id: selectedPhoto) {
                if let data = try? await selectedPhoto?.loadTransferable(type: Data.self) {
                    imageData = data
                }
            }
        }
    }

    // Helper Views
    func textFieldWithIcon(_ placeholder: String, systemImage: String, text: Binding<String>) -> some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(.gray)
            TextField(placeholder, text: text)
                .textFieldStyle(PlainTextFieldStyle())
                .autocapitalization(.none)
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(12)
    }

    func secureFieldWithIcon(_ placeholder: String, systemImage: String, text: Binding<String>) -> some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(.gray)
            SecureField(placeholder, text: text)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(12)
    }

    // Registration Logic
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
                dismiss()
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
                completion(nil)
                return
            }

            completion(url)
        }.resume()
    }
}
