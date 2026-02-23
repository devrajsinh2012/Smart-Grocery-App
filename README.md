<h1 align="center">🛒 Smart Grocery App</h1>

<p align="center">
  A cross-platform mobile application for seamless online grocery shopping, built with <strong>Flutter</strong> and <strong>Firebase</strong>.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white"/>
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white"/>
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black"/>
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?style=for-the-badge"/>
</p>

---

## 📖 About

The **Smart Grocery App** is a full-featured mobile application designed to make grocery shopping simpler and more convenient. Instead of visiting stores physically, users can browse products by category, manage their cart, and place orders directly through the app.

The app supports two types of users:
- **Customers** – Browse, search, order, and track groceries.
- **Admin/Developer** – Add, update, and remove product listings in real time.

Real-time data sync via **Firebase Firestore** ensures product availability is always up to date, preventing overbooking.

---

## ✨ Features

### Customer
- 🔐 **Sign Up / Sign In** with Firebase Authentication
- 🏠 **Home Dashboard** with category browsing and featured carousels
- 🔍 **Search** for products by name
- 🛍️ **Product Detail** view with variants, images, and pricing
- 🛒 **Shopping Cart** with quantity management
- 📍 **Location & Address Management** (GPS + manual entry)
- 💳 **Payment Method Screen**
- 📦 **Order History** tracking
- ⭐ **Feedback / Review** submission
- 👤 **Profile Management**
- 🔑 **Reset Password**

### Admin
- ➕ **Add Products** with images and categories
- ✏️ **Update Products** — edit name, price, stock, variants
- ❌ **Remove Products** from the store
- 📊 **Admin Dashboard** to manage the store

---

## 🛠️ Tech Stack

| Technology | Purpose |
|---|---|
| Flutter | UI framework (cross-platform) |
| Dart | Programming language |
| Firebase Auth | User authentication |
| Cloud Firestore | Real-time NoSQL database |
| Firebase Storage | Product image storage |
| Riverpod | State management |
| Geolocator / Geocoding | Location services |
| Carousel Slider | Home page banners |
| Shared Preferences | Local data persistence |

---

## ⚙️ Prerequisites

Before running this project, make sure you have the following installed:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `^3.6.0`
- [Dart SDK](https://dart.dev/get-dart) `^3.6.0`
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/)
- A [Firebase](https://firebase.google.com/) project with **Authentication**, **Cloud Firestore**, and **Storage** enabled

---

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/devrajsinh2012/Smart-Grocery-App.git
cd Smart-Grocery-App
```

### 2. Set Up Firebase

1. Go to [Firebase Console](https://console.firebase.google.com/) and create a new project.
2. Add an **Android** and/or **iOS** app to your Firebase project.
3. Download `google-services.json` (Android) and place it in `android/app/`.
4. Download `GoogleService-Info.plist` (iOS) and place it in `ios/Runner/`.
5. Enable **Email/Password** authentication in Firebase Console.
6. Create a **Firestore Database** and set up your security rules.
7. Enable **Firebase Storage**.

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Run the App

```bash
flutter run
```

> **Tip:** Use `flutter run -d chrome` to run on web, or connect a physical Android/iOS device.

---

## 📁 Project Structure

```
lib/
├── main.dart                  # App entry point
├── service/
│   ├── cart_provider.dart     # Riverpod cart state management
│   ├── firestore_service.dart # Firestore read/write helpers
│   ├── product_model.dart     # Product data model
│   ├── CategoryButton.dart    # Reusable category button widget
│   └── Variant.dart           # Product variant model
└── uiscrren/
    ├── HomePage.dart          # Main customer home screen
    ├── sign_in.dart           # Login screen
    ├── sign_up.dart           # Registration screen
    ├── ProductDetailScreen.dart
    ├── CartScreen.dart
    ├── BuyScreen.dart
    ├── AddressScreen.dart
    ├── PaymentMethodScreen.dart
    ├── OrderHistory.dart
    ├── SearchScreen.dart
    ├── CategoriesScreen.dart
    ├── ProfileScreen.dart
    ├── Feedbackscreen.dart
    ├── resetpassword.dart
    ├── AdminScreen.dart       # Admin dashboard
    ├── AddProduct.dart
    ├── UpdateProduct.dart
    └── RemoveProduct.dart
```

---

## 📸 App Screenshots

<p align="center">
  <img src="https://github.com/user-attachments/assets/a6350109-0a7d-40a9-8c8d-a1df3e03dbd9" height="400"/> &nbsp;&nbsp;
  <img src="https://github.com/user-attachments/assets/459a35a6-3cc3-4439-930c-d61c9a3603e7" height="400"/> &nbsp;&nbsp;
  <img src="https://github.com/user-attachments/assets/c63eee66-5f2b-45d2-8997-94f6d7ae4d76" height="400"/> &nbsp;&nbsp;
  <img src="https://github.com/user-attachments/assets/dacc45f0-2c6c-41d0-ad50-e3fb44b62d45" height="400"/> &nbsp;&nbsp;
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/a01d489c-1c54-4374-915e-bd1b41a70720" height="400"/> &nbsp;&nbsp;
  <img src="https://github.com/user-attachments/assets/2274d958-a2e4-4a9e-8060-9b4d665750a6" height="400"/> &nbsp;&nbsp;
  <img src="https://github.com/user-attachments/assets/e8bfce4b-6c04-429a-8500-cede26bf3232" height="400"/> &nbsp;&nbsp;
  <img src="https://github.com/user-attachments/assets/ab409350-1769-4b17-ac75-70c24612aa80" height="400"/> &nbsp;&nbsp;
</p>

---

## 📚 References

1. [Flutter Official Documentation](https://docs.flutter.dev)
2. [Google Firebase Documentation](https://firebase.google.com/docs)
3. [Flutter Riverpod (State Management)](https://riverpod.dev)
4. [Pub.dev – Flutter Packages](https://pub.dev/)
5. [Geolocator Package](https://pub.dev/packages/geolocator)

---

## 👨‍💻 Developed By

**Devrajsinh Gohil**
**Dhruv Malli**

Under the Guidance of **Prof.Pranav Tank**

---

<p align="center">Made with ❤️ using Flutter & Firebase</p>
