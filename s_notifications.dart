class NotificationManager {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Initializes Firebase, local notifications, and sets up handlers
  static Future<void> initializeNotifications() async {
    await _initializeFirebase();
    await _initializeLocalNotifications();
    _requestPermissions();
    _setupListeners();
    await saveFcmToken();
  }

  /// Initialize Firebase Messaging
  static Future<void> _initializeFirebase() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);
    _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true, // Disable default notifications
      badge: true,
      sound: true,
    );
  }

  /// Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings("ic_launcher");
    const iOSSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings =
        InitializationSettings(android: androidSettings, iOS: iOSSettings);

    await _flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTap,
    );
  }

  /// Request notification permissions
  static void _requestPermissions() {
    _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Handle notifications in the background
  static Future<void> _backgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    log("Background Message: ${message.data}");
    if (message.data['type'] == 'block') {
      log("User Blocked");
    }
  }

  /// Handle real-time message reception
  static void _setupListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage event) async {
      if (event.data.isNotEmpty) {
        _showNotification(event, payload: event.data.toString());
      } else if (event.notification != null) {
        _showNotification(event, payload: event.notification.toString());
      }
      if (event.data['type'] == 'block') {
        Utils.deleteAccount(Go.navigatorKey.currentContext!);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage event) {
      _handleNotificationTap(event.data.toString());
    });
  }

  /// Save Firebase Cloud Messaging (FCM) token
  static Future<void> saveFcmToken() async {
    final token = await _firebaseMessaging.getToken();
    log("Firebase FCM Token: $token");
    if (Platform.isIOS) {
      final apnsToken = await _firebaseMessaging.getAPNSToken();
      log("APNS Token: $apnsToken");
    }
  }

  /// Show local notification
  static Future<void> _showNotification(RemoteMessage message,
      {required String payload}) async {
    const androidDetails = AndroidNotificationDetails(
      "com.cloud_nine_user.app",
      "Cloud 9",
      channelDescription: "notificationBase",
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      icon: "ic_launcher",
    );

    const iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details =
        NotificationDetails(android: androidDetails, iOS: iOSDetails);

    String title = message.notification?.title ?? "No Title";
    String body = message.notification?.body ?? "No Body";

    await _flutterLocalNotificationsPlugin.show(
      200,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Handle notification tap (foreground or background)
  static void _handleNotificationTap(String payload) {
    log("Notification Tapped: $payload");

    // Parse the payload into a Map
    final data = _parsePayload(payload);

    // Perform actions based on the `type` key in the payload
    switch (data['type']) {
      case 'complaint_replay':
        int complaintId = int.parse(data['complaint_id']);
        // Navigate to complaint details screen
        Go.push(ComplaintDetailsView(complaintId: complaintId.toString()));
        break;

      case 'trainer_changed':
        int orderId = int.parse(data['order_id']);
        // Navigate to order details screen
        Go.push(OrderDetailsView(orderId: orderId.toString()));
        break;

      case 'end_order_by_package_duration':
        int orderId = int.parse(data['order_id']);
        // Navigate to order details screen
        Go.push(OrderDetailsView(orderId: orderId.toString()));
        break;

      case 'change_order_session_status':
        int orderId = int.parse(data['order_id']);
        // Navigate to order details screen
        Go.push(OrderDetailsView(orderId: orderId.toString()));
        break;

      case 'block':
        // Delete account or logout user
        Utils.deleteAccount(Go.navigatorKey.currentContext!);
        break;

      default:
        log('Unhandled notification type: ${data['type']}');
    }
  }

  /// Handle background notification tap
  static void _onNotificationTap(NotificationResponse response) {
    log("Foreground Notification Tapped: ${response.payload}");
    _handleNotificationTap(response.payload ?? "{}");
  }

  /// Handle background notification tap
  static void _onBackgroundNotificationTap(NotificationResponse response) {
    log("Background Notification Tapped: ${response.payload}");
    _handleNotificationTap(response.payload ?? "{}");
  }

  /// Parse payload into a Map<String, dynamic>
  static Map<String, dynamic> _parsePayload(String payload) {
    final Map<String, dynamic> data = {};
    payload
        .replaceAll("{", "")
        .replaceAll("}", "")
        .split(",")
        .forEach((element) {
      final keyValue = element.split(":");
      if (keyValue.length == 2) {
        data[keyValue[0].trim()] = keyValue[1].trim();
      }
    });
    return data;
  }
}
