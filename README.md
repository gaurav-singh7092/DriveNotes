# DriveNotes

A Flutter application that allows users to create, view, edit and delete notes that are stored and synced with Google Drive.

## Features

- 🔐 **Google OAuth 2.0 Authentication** - Secure sign-in with Google account
- 📝 **Note Management** - Create, view, edit, and delete text notes
- ☁️ **Google Drive Integration** - All notes are stored as text files in a "DriveNotes" folder on your Drive
- 🌓 **Dark/Light Theme** - Toggle between light and dark themes
- 📱 **Responsive UI** - Modern Material 3 design that works across different screen sizes

## Screenshots

(Screenshots would go here in a real README)

## Setup Instructions

### Prerequisites

- Flutter (2.0.0 or higher)
- A Google Cloud Platform account

### Google API Setup

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project (or select an existing one)
3. Enable the Google Drive API:
   - Navigate to "APIs & Services" > "Library"
   - Search for "Google Drive API" and enable it
4. Create OAuth 2.0 credentials:
   - Navigate to "APIs & Services" > "Credentials"
   - Click "Create Credentials" > "OAuth client ID"
   - Select "Android" as the Application type
   - Enter your app details and SHA-1 signing certificate
   - For additional platforms, create separate OAuth client IDs as needed

### Configure the App

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/drive_notes.git
   cd drive_notes
   ```

2. Update the OAuth credentials:
   - Open `/lib/features/auth/services/auth_service.dart`
   - Replace the values for `_clientId` with your own credentials

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run code generation for JSON serialization:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

5. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── core/                   # Core functionality
│   └── theme/              # App theme configuration
├── data/                   # Data layer
│   └── models/             # Data models
├── features/               # Feature modules
│   ├── auth/               # Authentication feature
│   │   ├── providers/      # Auth state management
│   │   └── services/       # Auth services
│   └── notes/              # Notes feature
│       ├── providers/      # Notes state management
│       └── services/       # Notes services (Drive integration)
├── presentation/           # UI layer
│   ├── routes/             # Navigation/routing
│   └── screens/            # App screens
└── utils/                  # Utility functions and helpers
```

## Libraries Used

- **flutter_riverpod**: State management
- **dio**: HTTP client for API requests
- **flutter_secure_storage**: Secure storage for OAuth tokens
- **googleapis** and **googleapis_auth**: Google API integration
- **go_router**: Navigation and routing
- **json_serializable**: JSON serialization/deserialization

## Known Limitations

- The app requires an internet connection for most operations
- Offline support is limited
- Only plain text notes are supported (no formatting or media)
- Note search functionality is not implemented

## Future Enhancements

- [ ] Offline mode with background sync
- [ ] Rich text formatting support
- [ ] Note categories/tags
- [ ] Search functionality
- [ ] Note sharing
- [ ] Biometric authentication

## License

This project is licensed under the MIT License - see the LICENSE file for details.
