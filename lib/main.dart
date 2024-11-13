import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

// Background message handler
Future<void> _messageHandler(RemoteMessage message) async {
  await Firebase.initializeApp(); // Ensure Firebase is initialized
  print('Background message: ${message.notification?.body}');
}

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_messageHandler);

  // Run the app
  runApp(MessagingTutorial());
}

class MessagingTutorial extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Messaging',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Firebase Messaging'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String? title;

  MyHomePage({Key? key, this.title}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late FirebaseMessaging messaging;
  String? _fcmToken;

  @override
  void initState() {
    super.initState();

    messaging = FirebaseMessaging.instance;

    // Request notification permissions (Android 13+)
    _requestPermission();

    // Get the Firebase Messaging token
    _getToken();

    // Listen for incoming messages when the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage event) {
      print("Message received in foreground");
      print('Message data: ${event.data}');
      print('Notification title: ${event.notification?.title}');
      print('Notification body: ${event.notification?.body}');

      // Show a dialog with the message content
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(event.notification?.title ?? "Notification"),
            content: Text(event.notification?.body ?? "No message body"),
            actions: [
              TextButton(
                child: Text("Ok"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    });

    // Handle when the app is opened from a terminated state
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('App opened from terminated state via notification');
        // Handle the message and navigate accordingly
      }
    });

    // Listen for messages when the app is opened via notification (background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App opened from background via notification');
      // Handle the message and navigate accordingly
    });

    // Subscribe to a topic (if needed)
    messaging.subscribeToTopic("messaging");
  }

  // Request notification permissions (required for Android 13+)
  void _requestPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print('User declined or has not accepted permission');
    } else {
      print('User granted provisional permission');
    }
  }

  // Retrieve the FCM token
  void _getToken() async {
    String? token = await messaging.getToken();
    setState(() {
      _fcmToken = token;
    });
    print('FCM Token: $_fcmToken');
    // You can send the token to your server or use it for testing
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Firebase Messaging'),
      ),
      body: Center(
        child: _fcmToken == null
            ? CircularProgressIndicator()
            : SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Your FCM Token:\n\n$_fcmToken',
                  textAlign: TextAlign.center,
                ),
              ),
      ),
    );
  }
}