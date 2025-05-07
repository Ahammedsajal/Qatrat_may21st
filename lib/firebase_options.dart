import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // WEB
  // ─────────────────────────────────────────────────────────────────────────────
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDxsDoI-paaicCbxq3MaNA13HhX1J3Y5uI',
    authDomain: 'customer-app-cad10.firebaseapp.com',
    projectId: 'customer-app-cad10',
    storageBucket: 'customer-app-cad10.firebasestorage.app',
    messagingSenderId: '388298698922',
    appId: '1:388298698922:web:a9056c127fddb7bab0a0d3',
    measurementId: 'G-Q51Z65FQ5W',
  );

  // ─────────────────────────────────────────────────────────────────────────────
  // ANDROID
  // ─────────────────────────────────────────────────────────────────────────────
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAkrc_R44PxJ9yFitNMWbp_IdTUiqYBpRs',
    appId: '1:388298698922:android:a71fd2c6b73fe285b0a0d3',
    messagingSenderId: '388298698922',
    projectId: 'customer-app-cad10',
    storageBucket: 'customer-app-cad10.firebasestorage.app',
  );

  // ─────────────────────────────────────────────────────────────────────────────
  // **UPDATED** iOS – matches GoogleService-Info.plist exactly
  // ─────────────────────────────────────────────────────────────────────────────
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBZzPF-TUQHk4lUxNOLRMZxfHctui28w_Q',
    appId: '1:388298698922:ios:d3bf8338ed31a9e3b0a0d3',
    messagingSenderId: '388298698922',
    projectId: 'customer-app-cad10',
    storageBucket: 'customer-app-cad10.firebasestorage.app',
    iosClientId:
        '388298698922-gftnl5f973cm8jufpkaqgu0p3dkamvno.apps.googleusercontent.com',
    iosBundleId: 'com.customersingle.customer',
  );

  // ─────────────────────────────────────────────────────────────────────────────
  // WINDOWS
  // ─────────────────────────────────────────────────────────────────────────────
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDxsDoI-paaicCbxq3MaNA13HhX1J3Y5uI',
    appId: '1:388298698922:web:e1a5130c796585d7b0a0d3',
    messagingSenderId: '388298698922',
    projectId: 'customer-app-cad10',
    authDomain: 'customer-app-cad10.firebaseapp.com',
    storageBucket: 'customer-app-cad10.firebasestorage.app',
    measurementId: 'G-7HFNRQ041V',
  );
}
