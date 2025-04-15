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

 static const FirebaseOptions web = FirebaseOptions(
  apiKey: "AIzaSyDxsDoI-paaicCbxq3MaNA13HhX1J3Y5uI",
  authDomain: "customer-app-cad10.firebaseapp.com",
  projectId: "customer-app-cad10",
  storageBucket: "customer-app-cad10.firebasestorage.app",
  messagingSenderId: "388298698922",
  appId: "1:388298698922:web:a9056c127fddb7bab0a0d3",
  measurementId: "G-Q51Z65FQ5W"
);

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAkrc_R44PxJ9yFitNMWbp_IdTUiqYBpRs',
    appId: '1:388298698922:android:a71fd2c6b73fe285b0a0d3',
    messagingSenderId: '388298698922',
    projectId: 'customer-app-cad10',
    storageBucket: 'customer-app-cad10.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAL5fpg6ptmwGRWlGTC9kI6_dqxuKqChZc',
    appId: '1:388298698922:ios:f192c13b1a0e203bb0a0d3',
    messagingSenderId: '388298698922',
    projectId: 'customer-app-cad10',
    storageBucket: 'customer-app-cad10.appspot.com',
    iosClientId: '388298698922-6nrkjtfh0u9b3dgqvep9k70q1ncennak.apps.googleusercontent.com', // Optional
    iosBundleId: 'com.wrteam.customer', // Replace with your iOS bundle ID
  );

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