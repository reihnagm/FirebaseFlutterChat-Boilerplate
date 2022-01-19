import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:rxdart/rxdart.dart';

import 'package:chatv28/utils/utils.dart';

class NotificationService {
  static final notifications = FlutterLocalNotificationsPlugin();
  static final onNotifications = BehaviorSubject<String>();

  static Future notificationDetails({required Map<String, dynamic> payload}) async {
    String largeIconPath = await Utils.downloadFile(payload["avatar"], 'largeIcon');
    // const List<String> lines = <String>[
    //   'Alex Faarborg Check this out',
    //   'Jeff Chang Launch Party'
    // ];
    AndroidNotificationDetails androidNotificationDetailsWithoutImage = AndroidNotificationDetails(
      'chat',
      'chat_channel',
      channelDescription: 'chat_channel',
      importance: Importance.max, 
      priority: Priority.high,
      channelShowBadge: true,
      enableVibration: true,
      enableLights: true,
      // styleInformation: const InboxStyleInformation(
      //   lines,
      //   contentTitle: '2 messages',
      //   summaryText: 'janedoe@example.com'
      // ),
      largeIcon: FilePathAndroidBitmap(largeIconPath),
    );
    AndroidNotificationDetails androidNotificationDetailsWithImage = AndroidNotificationDetails(
      'chat',
      'chat_channel',
      channelDescription: 'chat_channel',
      importance: Importance.max, 
      priority: Priority.high,
      channelShowBadge: true,
      enableVibration: true,
      enableLights: true,
      styleInformation: payload["type"] == "image" 
      ? BigPictureStyleInformation(
          FilePathAndroidBitmap(
            await Utils.downloadFile(payload["body"], 'bigPicture')
          ),
        ) 
      : null,
      largeIcon: FilePathAndroidBitmap(largeIconPath),
    );
    return NotificationDetails(
      android: payload["type"] == "image" 
      ? androidNotificationDetailsWithImage 
      : androidNotificationDetailsWithoutImage,
      iOS: const IOSNotificationDetails(
        presentBadge: true,
        presentSound: true,
        presentAlert: true,
      ),
    );
  } 

  static Future init({bool initScheduled = true}) async {
    InitializationSettings settings =  const InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_notification'),
      iOS: IOSInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        defaultPresentAlert: true,
        defaultPresentBadge: true,
        defaultPresentSound: true,
      )
    );

    // * When app is closed 
    final details = await notifications.getNotificationAppLaunchDetails();
    if(details != null && details.didNotificationLaunchApp) {
      onNotifications.add(details.payload ?? "");
    }

    await notifications.initialize(
      settings,
      onSelectNotification: (payload) async {
        onNotifications.add(payload!);
      }
    );

    if(initScheduled) {
      tz.initializeTimeZones();
      final locationName = await FlutterNativeTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(locationName));
    }
  }

  static Future showNotification({
    int id = 0,
    String? title, 
    String? body,
    Map<String, dynamic>? payload,
  }) async {
    notifications.show(
      id, 
      title, 
      body, 
      await notificationDetails(payload: payload!),
      payload: payload["screen"],
    );
  }

  static void showScheduleNotification({
    int id = 0,
    String? title, 
    String? body,
    Map<String, dynamic>? payload,
  }) async {
    notifications.zonedSchedule(
      id, 
      title, 
      body,
      tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)), 
      await notificationDetails(payload: payload!),
      payload: payload["screen"],
      androidAllowWhileIdle: true, 
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      // matchDateTimeComponents: DateTimeComponents.time
    );
  }

  static tz.TZDateTime scheduleDaily(Time time) {
    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
      time.second  
    );
    return scheduledDate.isBefore(now) 
    ? scheduledDate.add(const Duration(days: 1)) 
    : scheduledDate;
  }

  static tz.TZDateTime scheduleWeekly(Time time, { required List<int> days }) {
    tz.TZDateTime scheduleDate = scheduleDaily(time); 
    while (!days.contains(scheduleDate.weekday)) {
      scheduleDate = scheduleDate.add(const Duration(days: 1));
    }
    return scheduleDate;
  }

}