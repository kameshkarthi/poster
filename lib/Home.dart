import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:poster/settings.dart';
import 'package:provider/provider.dart';
import 'package:rate_my_app/rate_my_app.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'Catogery.dart';
import 'Favorites.dart';
import 'Hot.dart';
import 'New.dart';
import 'Random.dart';
import 'theme.dart';
import 'Widgets.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background message: ${message.messageId}');
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [Permission.storage, Permission.camera].request();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeNotifier(ThemeData.dark()),
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, _) {
          return MaterialApp(
            theme: themeNotifier.theme,
            debugShowCheckedModeBanner: false,
            title: 'Poster',
            home: const ConnectivityDemo(),
          );
        },
      ),
    );
  }
}

class ConnectivityDemo extends StatefulWidget {
  const ConnectivityDemo({super.key});

  @override
  State<ConnectivityDemo> createState() => _ConnectivityDemoState();
}

class _ConnectivityDemoState extends State<ConnectivityDemo> {
  List<ConnectivityResult>? _connectivityResult;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      if (mounted) {
        setState(() {
          _connectivityResult = result;
        });
      }
    });
    _checkConnectivity();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() {
        _connectivityResult = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_connectivityResult == ConnectivityResult.none) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/Noting Found Here.png',
                fit: BoxFit.contain,
                height: 200,
              ),
              const SizedBox(height: 20),
              const Text(
                'Ooops...!!',
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.white,
                  fontFamily: 'SF-Pro-Text',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Check your internet connection.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontFamily: 'SF-Pro-Text',
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const HomePage();
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  late TabController _tabController;
  DocumentSnapshot? _banner;
  AppUpdateInfo? _updateInfo;
  late RateMyApp _rateMyApp;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _rateMyApp = RateMyApp(
      preferencesPrefix: 'rateMyApp_',
      minDays: 7,
      minLaunches: 10,
      remindDays: 7,
      remindLaunches: 10,
      googlePlayIdentifier: 'com.mecho.wallpaper',
    );
    _initialize();
  }

  Future<void> _initialize() async {
    // Initialize Firebase Messaging
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen((message) {
      print('Foreground message: ${message.messageId}');
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('Message opened app: ${message.messageId}');
    });

    // Trigger in-app messaging
    FirebaseInAppMessaging.instance.triggerEvent('app_open');

    // Check for app updates
    _checkForUpdate();

    // Initialize rate dialog
    await _rateMyApp.init();
    if (mounted && _rateMyApp.shouldOpenDialog) {
      _rateMyApp.showRateDialog(
        context,
        title: 'Rate Poster',
        message: 'If you like the Poster app, please take a moment to review it.\nIt will help us a lot!',
        rateButton: 'RATE',
        noButton: 'NEVER SHOW AGAIN',
        laterButton: 'MAYBE LATER',
        listener: (button) {
          switch (button) {
            case RateMyAppDialogButton.rate:
              _rateMyApp.launchStore();
              _rateMyApp.callEvent(RateMyAppEventType.rateButtonPressed);
              Navigator.pop(context);
              break;
            case RateMyAppDialogButton.later:
              _rateMyApp.callEvent(RateMyAppEventType.laterButtonPressed);
              Navigator.pop(context);
              break;
            case RateMyAppDialogButton.no:
              _rateMyApp.callEvent(RateMyAppEventType.noButtonPressed);
              Navigator.pop(context);
              break;
          }
          return true;
        },
        dialogStyle: const DialogStyle(
          titleAlign: TextAlign.center,
          messageAlign: TextAlign.center,
          messagePadding: EdgeInsets.only(bottom: 20),
        ),
      );
    }

    // Fetch banner
    final snapshot = await FirebaseFirestore.instance.collection('Banner').limit(1).get();
    if (snapshot.docs.isNotEmpty && mounted) {
      setState(() {
        _banner = snapshot.docs.first;
      });
    }
  }

  Future<void> _checkForUpdate() async {
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      if (mounted) {
        setState(() {
          _updateInfo = updateInfo;
        });
        if (_updateInfo?.updateAvailability == UpdateAvailability.updateAvailable) {
          await InAppUpdate.startFlexibleUpdate();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('App update downloaded. Complete the update?'),
                action: SnackBarAction(
                  label: 'Install',
                  onPressed: () async {
                    await InAppUpdate.completeFlexibleUpdate();
                  },
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Update check failed: $e');
      }
    }
  }


  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }


  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDarkTheme = themeNotifier.theme == darkTheme;
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 15.0),
              child: IconButton(onPressed: (){
                Navigator.push(context, MaterialPageRoute(builder: (context){
                  return SettingScreen();
                }));
              }, icon: Icon(Icons.settings_outlined)),
            )
          ],
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: Text("   Poster",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 25.0
          ),),
          elevation: 0.0,
          bottom: TabBar(
            controller: _tabController,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Latest'),
              Tab(text: 'Hot'),
              Tab(text: 'Trending'),
              Tab(text: 'Collections'),
              Tab(text: 'Favorites'),
            ],
            indicatorSize: TabBarIndicatorSize.tab,
            isScrollable: true,
            indicatorColor: Theme.of(context).shadowColor,
            labelStyle: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDarkTheme ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: Theme.of(context).colorScheme.surface,
          ),
          child: Padding(
            padding: const EdgeInsets.only(
              top: 15.0
            ),
            child: TabBarView(
              controller: _tabController,
              children: [
                New(),
                Hot(),
                Random(),
                Category(),
                FavoritesPage(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}