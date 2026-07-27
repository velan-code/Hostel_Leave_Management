# 🏰 Sec Hostel - Leave & Complaint Management System

A modern, full-stack Flutter application for managing hostel leave requests, digital gate passes, student complaint tracking, and multi-tier administrative approval workflows.

---

## 🌟 Key Features

### 🎓 **Student Portal**
- **Leave Request Filing**: Submit Home Visit, Outing, Special, and Medical leave requests with real-time status tracking.
- **Digital Gate Pass**: Generates active digital gate passes upon final Warden approval.
- **Autofilled Resident Details**: Pre-fills student credentials (Name, Roll No, ERP No) automatically when launching forms.
- **Slide-Out Complaint Board**: Access live complaint resolution status, category tags, Warden remarks, and individual/bulk clearance.

### 🛡️ **Warden Dashboard**
- **Leave Management**: Review, sign, approve, or decline incoming student leave requests.
- **Student Complaints Review Panel**: Filter student complaints by category (`Food`, `Water Facility`, `Room`, `Abnormal Smell`, `Other`), update resolution status (`Pending`, `In Progress`, `Resolved`), and provide warden remarks.
- **Targeted Complaints Routing**: Directly receives complaints filed by residents assigned to that specific Warden.
- **Dual Clearance Logic**: Clearing complaints on the Warden dashboard hides them locally without deleting them for the student until both parties clear them.

### 👔 **HOD & Class Coordinator (CC) Portals**
- **Multi-Tier Approval Hierarchy**:
  1. **Class Coordinator (CC)**: First-level approval & student verification.
  2. **HOD**: Department head review & sign-off.
  3. **Hostel Warden**: Final approval & gate pass activation.
- **Interactive Action Feed**: Single-tap sign-off and decline dialogs with reason feedback.

### 🔔 **Real-Time Push & System Notifications**
- **Firebase Cloud Messaging (FCM)**: Delivers instant push notifications to targeted devices for submission, approvals, declines, and complaints.
- **Role-Based Isolation**: Guarantees that notifications intended for Wardens or CCs never leak to Student screens.
- **Humanized Vocabulary**: Features clear, user-interactable notification titles (`🚀 Leave Request Submitted`, `🎉 LEAVE FULLY APPROVED!`, `🚨 Priority Notice: New Student Complaint`).

### 🎵 **Interactive Sound Feedback Engine**
- **`SoundService`**: Provides synthesized PCM WAV audio feedback and tactile haptics:
  - 🎵 `playTap()`: Light click sound on button/card taps.
  - ✨ `playSuccess()`: Ascending C-Major chime for submissions & approvals.
  - ⚠️ `playDecline()`: Distinct alert tone for request declines.
  - 🔔 `playNotification()`: Crisp bell chime when opening notifications or side panels.

---

## 🎨 Design System & Aesthetic
- **Color Palette**: Rich Deep Navy (`#060B26` / `#0F2440`) paired with Warm Gold accents (`#E2A748`).
- **Typography**: Google Fonts (`Outfit` & `DM Sans`).
- **Icons**: Unified app launcher icon and custom vector logo graphics (`gemini-svg.svg`).

---

## 🛠️ Tech Stack & Dependencies

- **Frontend**: Flutter / Dart
- **State Management**: Flutter Riverpod
- **Backend & Database**: Firebase Core, Cloud Firestore, Firebase Auth
- **Push Notifications**: Firebase Messaging (FCM), Flutter Local Notifications
- **Sound & Haptics**: AudioPlayers, SystemSound, HapticFeedback
- **Routing**: GoRouter
- **Responsive Layout**: Sizer

---

## 📱 Getting Started & Build Instructions

### **Prerequisites**
- Flutter SDK (3.9.0 or higher)
- Android SDK (API 21+) / Java 17

### **Installation**
```bash
# Clone the repository
git clone https://github.com/<your-username>/Hostel_Leave_Management.git

# Navigate to project folder
cd Hostel_Leave_Management

# Fetch Flutter dependencies
flutter pub get
```

### **Build Runnable Release APK**
```bash
flutter build apk --release
```
The compiled APK will be located at:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 📄 License
This project is proprietary and intended for Sec Hostel Leave & Complaint Management.
