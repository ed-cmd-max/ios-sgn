# SGN Tickets iOS

The Swift sources mirror the Android/Kotlin layout under `Sources/MiProyecto`: `data/model`, `data/remote`, `ui/components`, `ui/navigation`, `ui/screens`, `ui/theme`, and `util`.

The migrated flows include sign-in/session restoration, tickets with role-aware filters and paging, creation forms, ticket detail/actions, chat with voice recording and signed attachment links, news, profile editing/photo upload, audit, solicitant administration, and local notifications.

## Platform notes

The UI targets iOS 17 or later. `project.yml` defines the iOS app and unit-test targets for XcodeGen. On a Mac with Xcode and Homebrew, generate and open the app project with:

```sh
brew install xcodegen
xcodegen generate
open SGNTickets.xcodeproj
```

Then choose an iPhone Simulator in Xcode and press **Run**. The `iOS Simulator Tests` GitHub Actions workflow generates the project, launches the login screen in a hosted simulator, and uploads a screenshot artifact after a push or pull request. Download `ios-simulator-screenshots` from the workflow run's **Artifacts** section to view the interface on Windows.

## Build from Windows with xtool

xtool can build this Swift package for iOS from Windows through WSL. Install [WSL](https://learn.microsoft.com/windows/wsl/install), then follow xtool's [Windows/WSL setup](https://xtool.sh/documentation/xtool/installation-linux) to install Swift 6.4, xtool, and the iOS SDK from Apple's Xcode download. From the WSL terminal in this project directory, run:

```sh
xtool setup
xtool dev build
```

`xtool dev build` compiles the app but does not show its interface. To install and interact with it, xtool requires an iPhone connected to the computer through USB/WSL. Without a device, use the GitHub Actions simulator screenshot above to view the login screen.

Firebase push delivery still requires adding the Firebase Messaging package and the iOS app's `GoogleService-Info.plist`; APNs tokens must not be sent to the server's FCM-token endpoint.
