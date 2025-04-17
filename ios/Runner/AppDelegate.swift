import UIKit
import Flutter
import FirebaseCore
import GoogleSignIn
import flutter_downloader

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Firebase initialization
      FirebaseApp.configure()


    // Register plugins
    GeneratedPluginRegistrant.register(with: self)

    // Register FlutterDownloader plugin background isolate
    FlutterDownloaderPlugin.setPluginRegistrantCallback(registerPlugins)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle Google Sign-In URL redirect
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    return GIDSignIn.sharedInstance.handle(url)
  }
}

// MARK: - Plugin registration for background isolate
private func registerPlugins(registry: FlutterPluginRegistry) {
  GeneratedPluginRegistrant.register(with: registry)
}
