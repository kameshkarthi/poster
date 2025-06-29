import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:poster/theme.dart';
import 'package:provider/provider.dart';
import 'package:rate_my_app/rate_my_app.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'Widgets.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingsState();
}
void _onThemeChanged(bool value, ThemeNotifier themeNotifier) async {
  themeNotifier.updateTheme(value ? darkTheme : lightTheme);
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('darkMode', value);
}

void _showSnackBar(String message,BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

void _toast(String message) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.CENTER,
    backgroundColor: Colors.black,
    textColor: Colors.white,
    fontSize: 16,
  );
}
class _SettingsState extends State<SettingScreen> {
  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDarkTheme = themeNotifier.theme == darkTheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(onPressed: (){
          Navigator.pop(context);
        }, icon: Icon(Icons.arrow_back_sharp,color: Theme.of(context).colorScheme.onSurface,)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text("Settings",
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 25.0
          ),),
      ),
      body: SafeArea(
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.color_lens, color: Theme.of(context).colorScheme.onSurface),
                title: Text(
                  'Dark Theme',
                  style: TextStyle(
                    fontSize: 17,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontFamily: 'SF-Pro-Text',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: isDarkTheme,
                    activeColor: Theme.of(context).colorScheme.onSurface,
                    inactiveThumbColor: Theme.of(context).colorScheme.onSurface,
                    inactiveTrackColor: Colors.grey,
                    onChanged: (value) {
                      _onThemeChanged(value, themeNotifier);
                    },
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.cached, color: Theme.of(context).colorScheme.onSurface),
                title: Text(
                  'Clear Cache',
                  style: TextStyle(
                    fontSize: 17,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontFamily: 'SF-Pro-Text',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () async {
                  try {
                    await DefaultCacheManager().emptyCache();
                    _toast('Cache cleared');
                  } catch (e) {
                    _toast('Failed to clear cache: $e');
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.star, color: Theme.of(context).colorScheme.onSurface),
                title: Text(
                  'Rate this app',
                  style: TextStyle(
                    fontSize: 17,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontFamily: 'SF-Pro-Text',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () async {
                  const url = 'https://play.google.com/store/apps/details?id=com.mecho.wallpaper';
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url));
                  } else {
                    _showSnackBar('Could not open store',context);
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.share, color: Theme.of(context).colorScheme.onSurface),
                title: Text(
                  'Share this app',
                  style: TextStyle(
                    fontSize: 17,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontFamily: 'SF-Pro-Text',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Share.share('Check out the Poster app: https://play.google.com/store/apps/details?id=com.mecho.wallpaper');
                },
              ),
              ListTile(
                leading: Icon(Icons.person, color: Theme.of(context).colorScheme.onSurface),
                title: Text(
                  'About',
                  style: TextStyle(
                    fontSize: 17,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontFamily: 'SF-Pro-Text',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => About()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
