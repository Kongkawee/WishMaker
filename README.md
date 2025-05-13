# WishMaker

**Saving and Monitoring Application – Keep You Motivated**

WishMaker is an iOS application developed with SwiftUI that empowers users to set, track, and achieve their financial goals. By combining intuitive design with motivational features, WishMaker helps users stay focused on their aspirations.

## 🚀 Features

- **User Authentication**: Secure sign-up and login using Firebase Authentication.
- **Wish Management**: Create, edit, and delete wishes with details like title, category, description, target amount, deadline, and image.
- **Progress Tracking**: Monitor savings progress for each wish, with visual indicators of completion status.
- **Financial Transactions**: Add funds to your account balance and allocate savings to specific wishes.
- **Transaction History**: View a detailed history of all financial transactions, including deposits and allocations to wishes.
- **Notifications**:
  - **Daily Motivation**: Receive daily reminders to stay on track with your savings goals.
  - **Due Date Alerts**: Get notified as wish deadlines approach to ensure timely completion.

## 🛠️ Technologies Used

- **SwiftUI**: For building a responsive and modern user interface.
- **Firebase**:
  - **Authentication**: Manage user sign-up and login processes.
  - **Firestore**: Store and retrieve user data, wishes, and transaction history.
- **Cloudinary**: Handle image uploads for user profiles and wishes.
- **UserNotifications**: Schedule and manage local notifications for user engagement.

## 🧑‍💻 Getting Started

### Prerequisites

- **Xcode**: Ensure you have the latest version of Xcode installed.

### Installation

1. **Clone the Repository**:

   ```bash
   git clone https://github.com/Kongkawee/WishMaker.git

2. **Navigate to the Project Directory:**:
   ```bash
   cd WishMaker
   
3. **Configure Firebase**:
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Authentication and Firestore Database.
   - Download the GoogleService-Info.plist file and add it to the root directory of your Xcode project.
    
4. **Configure Cloudinary**:
   - Sign up at [Cloudinary](https://cloudinary.com/console).
   - Obtain your cloud name and upload preset.
   - Update the Cloudinary configuration in the project accordingly.

5. **Build and Run**:
   - Select a simulator or connected device and run the project.
  
