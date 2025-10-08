Hostel Mess Management App
A comprehensive Flutter application designed to streamline meal booking and management for hostel residents. This app provides a seamless interface for students to book their daily meals and for administrators to manage the entire mess system efficiently.

App Architecture
The application is built using a modern, scalable architecture centered around the Provider package for state management, loosely following the MVVM (Model-View-ViewModel) pattern. This separation of concerns ensures the codebase is clean, maintainable, and easy to test.

Model: Defines the data structures and business objects of the app (e.g., User, Notice, DailyMenu).

Location: lib/models/

View: Comprises the UI components of the application. The widgets listen for state changes from the providers and rebuild accordingly.

Location: lib/screens/ & lib/widgets/

ViewModel (Provider): Acts as the bridge between the Model and the View. Each provider (AuthProvider, BookingProvider, etc.) encapsulates the application's state and business logic, interacting with the ApiService to perform backend operations.

Location: lib/provider/

Service: The ApiService handles all communication with the backend REST API, abstracting away the HTTP request logic.

Location: lib/api/

Screenshots
SignIn Screen

Dashboard

<img src="https://github.com/user-attachments/assets/768dbe7b-61da-4d81-b7a3-627603a9bf77" width="250">

<img src="https://github.com/user-attachments/assets/c5a1d9bd-a27a-4b7c-9c39-84764e6c4f56" width="250">

Booking Screen

User Management Screen

<img src="https://github.com/user-attachments/assets/43049e63-9e5b-430b-b6be-5ac240cd879c" width="250">

<img src="https://github.com/user-attachments/assets/48cff7f0-163a-4933-9a50-cceae9dfe9de" width="250">

Key Features
For Students:
Secure Authentication: Robust login, registration, and password reset functionality.

Dashboard: A quick overview of today's booked meals and the latest notices.

Meal Booking: Easy-to-use interface to book, update, or cancel meals for upcoming dates.

Menu Viewing: Check the daily menu for lunch and dinner.

Booking History: A timeline view of all past meal bookings.

Notice Board: Stay updated with the latest announcements from the mess committee.

Profile Management: View personal details and toggle app theme (Light/Dark mode).

For Admins (Convenor & Mess Committee):
User Management: Search, view, and manage all registered users.

Role Assignment: Change user roles (e.g., promote to Mess Committee).

Mess Status Control: Activate or deactivate mess services for individual users.

Menu Management: Set and clear the daily menu for all users.

Notice Management: Post and delete notices on the notice board.

Daily Meal List: View a detailed breakdown of total bookings for any date, including item counts and a list of students who have booked.

Getting Started
To get a local copy up and running, follow these simple steps.

Prerequisites
Flutter SDK (version 3.x or higher)

A code editor like VS Code or Android Studio with the Flutter plugin.

An active internet connection to communicate with the backend API.

Installation
Clone the repo

git clone [https://github.com/your_username/hostel-mess-app.git](https://github.com/your_username/hostel-mess-app.git)

Navigate to the project directory

cd hostel-mess-app

Install Flutter packages

flutter pub get

Run the app

flutter run

Project Structure
The project is organized into logical directories to ensure clarity and scalability.

lib/
├── api/
│   └── api_service.dart           # Handles all HTTP requests to the backend
├── models/
│   └── user.dart                  # Data models (e.g., User, Notice)
├── provider/
│   ├── auth_provider.dart         # State management for authentication
│   ├── booking_provider.dart      # State for meal booking logic
│   ├── menu_provider.dart         # State for fetching daily menus
│   └── ...                        # Other providers for each feature
├── screens/
│   ├── admin/
│   │   ├── post_notice_screen.dart
│   │   └── set_menu_screen.dart
│   ├── dashboard_screen.dart      # Main dashboard UI
│   ├── booking_screen.dart        # Meal booking UI
│   ├── login_screen.dart          # Login UI
│   └── ...                        # Other app screens
├── widgets/
│   ├── custom_button.dart
│   └── custom_textfield.dart      # Reusable UI components
└── main.dart                      # App entry point and theme configuration
