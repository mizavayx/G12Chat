import 'package:chat_app/frontend/splash_screen/splash.dart';
import 'package:chat_app/global_uses/constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

int? initScreen;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //sets device orientation to portrait mode only
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  
 //change status bar color and birghtness
 SystemChrome.setSystemUIOverlayStyle(
   const SystemUiOverlayStyle(
     statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    )
  );

  //Initializes a new [FirebaseApp] instance
 await Firebase.initializeApp();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  initScreen = prefs.getInt("initScreen");
  await prefs.setInt("initScreen", 1);

  runApp(MaterialApp(
    title: 'Chat_app',
    debugShowCheckedModeBanner: false,
    themeMode: ThemeMode.light,
    theme: ThemeData(
      fontFamily: kDefaultFont,
      primarySwatch: primarySwatch,
    ),
    initialRoute: '/',
    routes: {
      '/': (context) => const SplashScreen(),
    },
  ));
}
