import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../Widget/showAlert.dart';
import '../constant/ThemeColor.dart';
import 'HomeScreen.dart';
import 'ResetPasswordScreen.dart';
import 'SignUpScreen.dart';


class LoginScreen extends StatefulWidget {
  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  GoogleSignIn _googleSignIn = GoogleSignIn();
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  late SharedPreferences preferences;
  late User currentUser;
  bool isLoggedIn = false;
  bool showSpin = false;
  String email = "", password = "", errorMessage = "";
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
  }

  Future googleControlSignIn() async {
    preferences = await SharedPreferences.getInstance();

    GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    GoogleSignInAuthentication googleSignInAuthentication =
    await googleUser!.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleSignInAuthentication.idToken,
      accessToken: googleSignInAuthentication.accessToken,
    );
    User? user = (await firebaseAuth.signInWithCredential(credential)).user;

    checkLoginInStatus(user);
  }

  String generateNonce([int length = 32]) {
    final charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Returns the sha256 hash of [input] in hex notation.
  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future appleControlSignIn() async {
    try {
      final rawNonce = generateNonce();
      final nonce = sha256ofString(rawNonce);
      print("rawNonce: $rawNonce");
      print("nonce: $nonce");
      preferences = await SharedPreferences.getInstance();
      var result = await SignInWithApple.getAppleIDCredential(scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ], nonce: nonce);

      final appleCredential = OAuthProvider("apple.com").credential(
          accessToken: result.identityToken,
          rawNonce: rawNonce,
          idToken: result.identityToken);

      final authResult =
      await firebaseAuth.signInWithCredential(appleCredential);
      User? user = authResult.user;

      checkLoginInStatus(user);
    } on Error catch (e) {
      Fluttertoast.showToast(
          toastLength: Toast.LENGTH_LONG,
          msg: "Apple sign in request IOS 14+");
    }
  }

  //Check if user verify account and catch other errors
  Future normalControlSignIn() async {
    preferences = await SharedPreferences.getInstance();
    setState(() {
      showSpin = true;
    });
    try {
      User? user = (await firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password))
          .user;
      if (user != null && user.emailVerified) {
        checkLoginInStatus(user);
        setState(() {
          showSpin = false;
          emailFocusNode.unfocus();
          passwordFocusNode.unfocus();
        });
      } else {
        user!.sendEmailVerification();
        Fluttertoast.showToast(msg: "Check your email to verify account");
        setState(() {
          showSpin = false;
        });
      }
    } on FirebaseAuthException catch (error) {
      print(error);
      switch (error.code) {
        case "invalid-email":
          errorMessage = "Email is badly formatted.";
          break;
        case "wrong-password":
          errorMessage = "Password is incorrect.";
          break;
        case "user-not-found":
          errorMessage = "User with this email doesn't exist.";
          break;
        case "user-disabled":
          errorMessage = "Your account has been disabled.";
          break;
        case "too-many-requests":
          errorMessage = "Too many requests. Try again later.";
          break;
        default:
          errorMessage = "An undefined Error happened.";
      }
      setState(() {
        showSpin = false;
      });
    }
  }

  Future checkLoginInStatus(User? user) async {
    setState(() {
      showSpin = true;
    });

    /*
    ///Check if user has verify account
    if (user != null && !user.emailVerified) {
      Fluttertoast.showToast(msg: "Check your email to verify account");
      await user.sendEmailVerification();
    }
     */

    ///Check if Login Success
    if (user != null) {
      final QuerySnapshot resultQuery = await FirebaseFirestore.instance
          .collection("user")
          .where("id", isEqualTo: user.uid)
          .get();
      final List<DocumentSnapshot> documentSnapshots = resultQuery.docs;

      ///New User write data to Firebase
      if (documentSnapshots.length == 0) {
        String convert =
        user.displayName.toString().toLowerCase().replaceAll(' ', '');
        var arraySearchID = List.filled(convert.length, "");
        if (user.displayName != null) {
          for (int i = 0; i < convert.length; i++) {
            arraySearchID[i] =
                convert.substring(0, i + 1).toString().toLowerCase();
          }
        } else {
          String newUnknownUserName = "user" + user.uid.substring(0, 9);
          arraySearchID = new List.filled(newUnknownUserName.length, "");
          for (int i = 0; i < newUnknownUserName.length; i++) {
            arraySearchID[i] =
                newUnknownUserName.substring(0, i + 1).toString().toLowerCase();
          }
        }
        FirebaseFirestore.instance.collection("user").doc(user.uid).set({
          "name": (user.displayName != null || user.displayName == "null")
              ? user.displayName
              : "User " + user.uid.substring(0, 9),
          "photoUrl": user.photoURL != null
              ? user.photoURL
              : "https://dlmocha.com/app/Ume-Talk/userDefaultAvatar.jpeg",
          "id": user.uid,
          "createdAt": DateTime.now().toString(),
          "searchList": false,
          "token": "No-data",
        });
        //Write data to Local
        currentUser = user;
        //currentUser.displayName == null ? displayName = "" : displayName = currentUser.displayName.toString();
        await preferences.setString("id", currentUser.uid);
        await preferences.setString("name", currentUser.displayName.toString());
        await preferences.setString(
            "photoUrl", currentUser.photoURL.toString());
        Fluttertoast.showToast(msg: "Loading");
        Future.delayed(Duration(seconds: 3), () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return HomeScreen();
          }));
        });
      } else {
        ///Check if already SignedUp User
        //Write data to Local
        currentUser = user;
        // await preferences.setString("id", documentSnapshots[0]["id"]);
        // await preferences.setString(
        //     "name",
        //     documentSnapshots[0]["name"] != null
        //         ? documentSnapshots[0]["name"]
        //         : "Unknown User");
        // await preferences.setString(
        //     "photoUrl",
        //     documentSnapshots[0]["photoUrl"] != null
        //         ? documentSnapshots[0]["photoUrl"]
        //         : "https://dlmocha.com/app/Ume-Talk/userDefaultAvatar.jpeg");
        Fluttertoast.showToast(msg: "Loading");
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return HomeScreen();
        }));
      }
      setState(() {
        showSpin = false;
      });
    } else {
      ///SignIn fail
      Fluttertoast.showToast(
          toastLength: Toast.LENGTH_LONG,
          msg: "Fail to sign in. Please try again.");
      setState(() {
        showSpin = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [themeColor, subThemeColor],
                      stops: [0.7, 1.0],
                    )
                ),
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const SizedBox(
                      height: 150.0,
                    ),
                    const Flexible(child:
                    Text("NAME HERE",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: Colors.white),)),
                    const SizedBox(
                      height: 100.0,
                    ),
                    TextField(
                      textAlign: TextAlign.start,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (value) {
                        email = value;
                      },
                      focusNode: emailFocusNode,
                      decoration: const InputDecoration(
                        hintText: "Email",
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:  EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 20.0),
                        border:  OutlineInputBorder(
                          borderRadius:  BorderRadius.all(Radius.circular(19.0)),
                        ),
                        enabledBorder:  OutlineInputBorder(
                          borderSide:
                          BorderSide(color: Colors.black45, width: 1.0),
                          borderRadius: BorderRadius.all(Radius.circular(19.0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                          BorderSide(color: Colors.black, width: 2.0),
                          borderRadius: BorderRadius.all(Radius.circular(19.0)),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10.0,
                    ),
                    TextField(
                      textAlign: TextAlign.start,
                      obscureText: true,
                      onChanged: (value) {
                        password = value;
                      },
                      focusNode: passwordFocusNode,
                      decoration: const InputDecoration(
                        hintText: "Password",
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 20.0),
                        border: OutlineInputBorder(
                          borderRadius:  BorderRadius.all(Radius.circular(32.0)),
                        ),
                        enabledBorder:  OutlineInputBorder(
                          borderSide:
                          BorderSide(color: Colors.black45, width: 1.0),
                          borderRadius:  BorderRadius.all(Radius.circular(19.0)),
                        ),
                        focusedBorder:  OutlineInputBorder(
                          borderSide:
                          BorderSide(color: Colors.black, width: 2.0),
                          borderRadius:  BorderRadius.all(Radius.circular(19.0)),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10.0,
                    ),
                    Center(child: showAlert(errorMessage)),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Material(
                        borderRadius: const BorderRadius.all(Radius.circular(19.0)),
                        elevation: 5.0,
                        child: Ink(
                          decoration: BoxDecoration(
                            color: buttonColor,
                            borderRadius: BorderRadius.circular(19.0),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(19.0),
                            onTap: normalControlSignIn,
                            child: Container(
                              width: 200.0,
                              height: 40.0,
                              alignment: Alignment.center,
                              child: const Text(
                                'Log In',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Material(
                        borderRadius: const BorderRadius.all(Radius.circular(19.0)),
                        elevation: 5.0,
                        child: Ink(
                          decoration: BoxDecoration(
                            color: buttonColor,
                            borderRadius: BorderRadius.circular(19.0),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(19.0),
                            onTap: appleControlSignIn,
                            child: Container(
                              width: 200.0,
                              height: 40.0,
                              alignment: Alignment.center,
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Container(
                                      width: 30.0,
                                      height: 30.0,
                                      decoration: const BoxDecoration(
                                          borderRadius: BorderRadius.all(Radius.circular(5.0)),
                                          image: DecorationImage(
                                              image: AssetImage('images/apple.png'))),
                                    ),
                                    const SizedBox(width: 20,),
                                    const Text(
                                      'Continue with Apple',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18.0,
                                      ),
                                    ),
                                  ]),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Material(
                        borderRadius: const BorderRadius.all(Radius.circular(19.0)),
                        elevation: 5.0,
                        child: Ink(
                          decoration: BoxDecoration(
                            color: buttonColor,
                            borderRadius: BorderRadius.circular(19.0),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(19.0),
                            onTap: googleControlSignIn,
                            child: Container(
                              width: 200.0,
                              height: 40.0,
                              alignment: Alignment.center,
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Container(
                                      width: 30.0,
                                      height: 30.0,
                                      decoration: const BoxDecoration(
                                          borderRadius: BorderRadius.all(Radius.circular(5.0)),
                                          image: DecorationImage(
                                              image: AssetImage('images/google.png'))),
                                    ),
                                    const SizedBox(width: 20,),
                                    const Text(
                                      'Continue with Google',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18.0,
                                      ),
                                    ),
                                  ]),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20.0,
                    ),
                    Container(
                      alignment: Alignment.center,
                      child: GestureDetector(
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15.0,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context){
                              return ResetPasswordScreen();
                            }));
                          }),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
                left: 0,
                right: 0,
                bottom: 100,
                child: Container(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text("Don't have account? ", style: TextStyle(fontSize: 15, color: Colors.white),),
                      const SizedBox(
                        width: 5,
                      ),
                      Container(
                        alignment: Alignment.topLeft,
                        child: GestureDetector(
                            child: const Text(
                              "Sign Up",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17.0,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context){
                                return SignUpScreen();
                              }));
                            }),
                      ),
                    ],),
                ))
          ]),
    );
  }

}
