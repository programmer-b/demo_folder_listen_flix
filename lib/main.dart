import 'package:demo_folder_listen_flix/provider.dart';
import 'package:demo_folder_listen_flix/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) => MyProvider(),
        child: MaterialApp(
          title: 'Flutter Demo',
          theme: ThemeData(
              primaryColor: Colors.white,
              primarySwatch: Colors.red,
              brightness: Brightness.dark,
              scaffoldBackgroundColor: Colors.black,
              appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.black, elevation: 0.0),
              textTheme: const TextTheme(
                headline4: TextStyle(color: Colors.white),
              )),
          home: const SplashScreen(),
        ));
  }
}
