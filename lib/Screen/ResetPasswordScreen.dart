import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constant/ThemeColor.dart';

class ResetPasswordScreen extends StatefulWidget {
  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  String email = "", errorMessage = "";
  bool showSpinner = false;

  @override
  Widget build(BuildContext context) {
    var textSize = MediaQuery.of(context).textScaleFactor;
    return Container(
      decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [themeColor, subThemeColor],
            stops: [0.7, 1.0],
          )
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: Container(),
          backgroundColor: Colors.transparent,
          elevation: 0.0,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            //mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Flexible(child:
              Text("NAME HERE",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: Colors.white),)),
              const SizedBox(
                height: 100,
              ),
              const Icon(Icons.lock_outlined, color: subThemeColor, size: 100,),
              Container(
                padding: const EdgeInsets.fromLTRB(25, 50, 25, 25),
                alignment: Alignment.center,
                child: const Text(
                  'Enter your email, we\'ll send you a link to change a new password',
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(
                height: 20.0,
              ),
              TextField(
                textAlign: TextAlign.start,
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) {
                  email = value;
                },
                decoration: const InputDecoration(
                  hintText: 'Email',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(
                      vertical: 10.0, horizontal: 20.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(19.0)),
                  ),
                  enabledBorder: OutlineInputBorder(
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
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Material(
                    elevation: 5.0,
                    color: buttonColor,
                    borderRadius: BorderRadius.circular(19.0),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: buttonColor,
                        borderRadius: BorderRadius.circular(19.0),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(19.0),
                        onTap: (){},
                        child: Container(
                          height: 50.0,
                          width: 200.0,
                          alignment: Alignment.center,
                          child: const Text("Forgot Password",
                            style: TextStyle(color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 18),),
                        ),
                      ),
                    )
                ),
              ),
              //showAlert(errorMessage),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Container(
                  alignment: Alignment.center,
                  child: GestureDetector(
                      child: const Text(
                        "Back to sign in",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.0,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                      }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
