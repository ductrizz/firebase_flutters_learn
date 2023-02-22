import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../page/notification_page.dart';

///Push Notification contain:
///[B1] Create class Push Notification
///[B2] Create Function initial to install firebase and setting notification
///[B3] Setting push notification foreground for android Platform
///[B4] Create function handle when receive notification from Firebase.
///[B5] Navigate to any page when tap Notification.

///[B4.3] Call when open App again
@pragma('vm:entry-point')
Future<void> onBackgroundMessage(RemoteMessage message) async {
  //Background have to higher order function ??? (Cause???)
  print('Type Message :: onBackgroundMessage Open ${jsonEncode(message.data)}');
}

///[B1.0] Create a SingleTon Pattern for Push notification
class PushNotification {
  PushNotification._();
  //[B5.1] declare Argument BuildContext
  static BuildContext? _context;

  //[B5.2] create Setter for BuildContext and use it at first page to context != null
  static void setContext(BuildContext context) =>
      PushNotification._context = context;

  ///[B1.1] instance factory
  factory PushNotification() => _instance;

  static final PushNotification _instance = PushNotification._();

  ///[B2.0] Instance FirebaseMessage and Create Function.
  ///[B2.1] create new Firebase Message
  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  ///[B3.1] Create new AndroidNotificationChannel for android Platform
  ///in app can more than a channel, for each channel will push for diffrent Notification
  ///it will show up in setting app in part Other of Notification setting
  final AndroidNotificationChannel channel = const AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  ///[B3.2]Create new FlutterLocalNotificationsPlugin to call Service Notification
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  ///[B2.2]Create initial Function
  Future initial() async {
    ///[B2.3] Request Permission for app
    NotificationSettings settings = await firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: true,
      sound: true,
    );
    await FirebaseMessaging.instance.getInitialMessage();
    //Setting Foreground For IOS
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true, // Required to display a heads up notification
      badge: true,
      sound: true,
    );

    ///[B3.0] Use package [flutter_local_notifications] to create channel to display Notification
    ///in when open App for Android (Foreground).
    _instancePlatformAndroid();
    getToken();

    FirebaseMessaging.onMessage.listen(_onMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
    FirebaseMessaging.onBackgroundMessage(onBackgroundMessage);
  }

  Future _instancePlatformAndroid() async {
    if (Platform.isAndroid) {
      ///[B3.4] Create a new AndroidNotificationChannel instance
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      ///[B3.5] Initial FlutterLocalNotification
      await flutterLocalNotificationsPlugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('mipmap/ic_launcher'),
        ),
      );
    }
  }

  ///[B4.0] Create Function Listen Message
  ///[B4.1] Foreground messages Function:
  Future<void> _onMessage(RemoteMessage message) async {
    //[B3.5] Create To Foreground for Android PlatForm
    RemoteNotification? notification = message.notification;

    AndroidNotification? android = message.notification?.android;

    print('Type Message :: onMessage Open');
    print('Message data: ${message.data}');

    ///[B3.0] Configuration for Android
    ///[3.2] Create the channel on the device

    if (notification != null && Platform.isAndroid) {
      await flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: android?.smallIcon ?? '',
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  ///[B4.2] Call when open App again
  void _onMessageOpenedApp(RemoteMessage message) async {
    //[B5.3] Call Function navigate when openApp
    navigate(message, _context);
    print('Type Message :: onMessageOpenedApp Open');
    print("onMessageOpenedApp: ${message.messageId}");
  }

  ///[Get Token]
  Future<String> getToken() async {
    var tokenFCM = await firebaseMessaging.getToken();
    log('tokenFCM :: $tokenFCM');
    return Future.value(tokenFCM);
  }

  //[B5.0] Create Function navigator
  void navigate(RemoteMessage message, BuildContext? context) {
    Navigator.push(
      context!,
      MaterialPageRoute(
        builder: (BuildContext context) => const NotificationPage(),
      ),
    );
  }
}
