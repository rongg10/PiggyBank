import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'Screen/HomeScreen.dart';
import 'Screen/LoginScreen.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Event App Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(),
      builder: (context, snapshot) {
        // Check for errors
        if (snapshot.hasError) {
          return MaterialApp(
            title: 'Error',
            theme: ThemeData(
              primaryColor: Colors.lightBlueAccent,
            ),
            home: Container(
              child: Center(
                child: Text(
                  "Error",
                  style: TextStyle(fontSize: 45, color: Colors.black),
                ),
              ),
            ),
            debugShowCheckedModeBanner: false,
          );
        }
        // Once complete, show your application
        if (snapshot.connectionState == ConnectionState.done) {
          return FirebaseAuth.instance.currentUser != null
              ? MaterialApp(
            title: 'Ume Talk',
            theme: ThemeData(
              primaryColor: Colors.lightBlueAccent,
            ),
            home: HomeScreen(),
            debugShowCheckedModeBanner: false,
          )
              : MaterialApp(
            title: 'Ume Talk',
            theme: ThemeData(
              primaryColor: Colors.lightBlueAccent,
            ),
            home: LoginScreen(),
            debugShowCheckedModeBanner: false,
          );
        }

        // Otherwise, show something whilst waiting for initialization to complete
        return MaterialApp(
          title: 'Ume Talk',
          theme: ThemeData(
            primaryColor: Colors.black,
          ),
          home: Container(
            child: Text("No Internet!", style: TextStyle(fontSize: 20, color: Colors.greenAccent),),
          ),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }

}
