import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/car_detail_screen.dart';
import 'screens/add_car_screen.dart'; // Bu satırı ekle
import 'models/car.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/notifications_screen.dart';

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _saveNotificationToFirestore({
  required String userId,
  required String title,
  required String message,
  Map<String, dynamic>? data,
  String? type,
}) async {
  try {
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'data': data,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  } catch (_) {
    // Swallow errors to avoid crashing background isolate
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized in the background isolate
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Ignore if already initialized
  }

  // Try to resolve userId from auth or payload
  String? userId = FirebaseAuth.instance.currentUser?.uid;
  userId ??= message.data['userId'];

  if (userId != null) {
    String? title = message.notification?.title;
    String? body = message.notification?.body;
    title ??= message.data['title'] ?? message.data['notification_title'];
    body ??=
        message.data['body'] ??
        message.data['message'] ??
        message.data['notification_body'];

    if ((title != null && title.isNotEmpty) ||
        (body != null && body.isNotEmpty)) {
      await _saveNotificationToFirestore(
        userId: userId,
        title: title ?? 'Bildirim',
        message: body ?? '',
        data: message.data.isNotEmpty ? message.data : null,
        type: message.data['type'],
      );
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await _setupLocalNotifications();
  await _initPushNotifications();
  runApp(const CarRentalApp());
}

class CarRentalApp extends StatelessWidget {
  const CarRentalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Car Rental',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      navigatorKey: navigatorKey,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('tr', 'TR'), Locale('en', 'US')],
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            // Kullanıcı giriş yaptıysa HomeScreen'e yönlendir
            final user = snapshot.data;
            return HomeScreen(cars: [], user: user);
          }
          // Aksi halde Login ekranı
          return LoginScreen();
        },
      ),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case CarDetailScreen.routeName:
            final car = settings.arguments as Car;
            return MaterialPageRoute(builder: (_) => CarDetailScreen(car: car));
          case '/add-car': // Bu case'i ekle
            return MaterialPageRoute(builder: (_) => const AddCarScreen());
          default:
            return null;
        }
      },
    );
  }
}

Future<void> _setupLocalNotifications() async {
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
  );
  await _localNotifications.initialize(initSettings);

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Used for important notifications',
    importance: Importance.high,
  );

  final androidPlugin =
      _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
  await androidPlugin?.createNotificationChannel(channel);
}

Future<void> _initPushNotifications() async {
  final messaging = FirebaseMessaging.instance;
  // Request permissions (Android 13+ needs POST_NOTIFICATIONS runtime)
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  // iOS: show notifications when app is in foreground
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // Get device FCM token
  final token = await messaging.getToken();
  if (token != null) {
    // Useful for testing via Firebase Console "Send test message"
    // or server-side delivery to this device
    // ignore: avoid_print
    print('FCM token: $token');
  }
  await messaging.subscribeToTopic('test');
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null && token != null) {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .set({
          'fcmToken': token,
          'fcmUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  // Foreground message handler -> show local notification (supports data-only)
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    String? title = notification?.title;
    String? body = notification?.body;

    if (title == null || title.isEmpty) {
      title = message.data['title'] ?? message.data['notification_title'];
    }
    if (body == null || body.isEmpty) {
      body =
          message.data['body'] ??
          message.data['message'] ??
          message.data['notification_body'];
    }

    if (title != null || body != null) {
      _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title ?? 'Bildirim',
        body ?? '',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'Used for important notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: message.data.isNotEmpty ? message.data.toString() : null,
      );
    }

    // Persist notification for the signed-in user so it appears in the list
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && (title != null || body != null)) {
      _saveNotificationToFirestore(
        userId: currentUser.uid,
        title: title ?? 'Bildirim',
        message: body ?? '',
        data: message.data.isNotEmpty ? message.data : null,
        type: message.data['type'],
      );
    }
  });

  // Notification opened from background
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  });

  // Notification caused app to open from terminated
  final initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
      );
    });
  }

  // Keep token updated
  messaging.onTokenRefresh.listen((newToken) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .set({
            'fcmToken': newToken,
            'fcmUpdatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    }
  });

  // Listen Firestore for new notifications for current user and show local popup
  final currentUserForListener = FirebaseAuth.instance.currentUser;
  if (currentUserForListener != null) {
    FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: currentUserForListener.uid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.docChanges.isEmpty) return;
          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data();
              if (data == null) continue;
              final title = (data['title'] ?? 'Bildirim').toString();
              final message = (data['message'] ?? '').toString();
              _localNotifications.show(
                DateTime.now().millisecondsSinceEpoch ~/ 1000,
                title,
                message,
                const NotificationDetails(
                  android: AndroidNotificationDetails(
                    'high_importance_channel',
                    'High Importance Notifications',
                    channelDescription: 'Used for important notifications',
                    importance: Importance.high,
                    priority: Priority.high,
                  ),
                ),
              );
            }
          }
        });
  }
}
