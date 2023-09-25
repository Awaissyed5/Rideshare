import 'package:firebase_database/firebase_database.dart';
import 'package:rideshare/authentication/forgot_password.dart';
import 'package:rideshare/authentication/signup_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:fluttertoast/fluttertoast.dart';

import '../Constants/styles/colors.dart';
import '../global/global.dart';
import '../mainScreens/main_screen.dart';
import '../widgets/progress_dialog.dart';

// ignore: must_be_immutable
class LoginScreen extends StatefulWidget {
  static const String idScreen = "login";

  LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailTextEditingController = TextEditingController();

  TextEditingController passwordTextEditingController = TextEditingController();
  bool isPasswordVisible = false;

  validateForm(BuildContext context) async {
    if (!emailTextEditingController.text.contains("@")) {
      Fluttertoast.showToast(msg: "email is not valid.");
    } else if (passwordTextEditingController.text.isEmpty) {
      Fluttertoast.showToast(msg: "password is empty.");
    } else {
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext c) {
            return ProgressDialog(
              message: "Logging in, Please wait...",
            );
          });

      try {
        final String email = emailTextEditingController.text.trim();
        final String password = passwordTextEditingController.text.trim();

        final ref = FirebaseDatabase.instance.ref('users');
        final snapshot = await ref.orderByChild('email').equalTo(email).get();

        if (!snapshot.exists) {
          // Email does not exist in the database
          Fluttertoast.showToast(msg: 'Email not found.');
          Navigator.pop(context);

          return;
        }

        final User? firebaseUser = (await fAuth
                .signInWithEmailAndPassword(
          email: email,
          password: password,
        )
                // ignore: body_might_complete_normally_catch_error
                .catchError((msg) {
          Navigator.pop(context);
          Fluttertoast.showToast(msg: 'Error: $msg');
        }))
            .user;

        if (firebaseUser != null) {
          currentFirebaseUser = firebaseUser;
          Fluttertoast.showToast(msg: 'Login successful!');
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => const MainScreen()),
          );
        } else {
          Navigator.pop(context);
          Fluttertoast.showToast(msg: 'Login not successful!');
        }
      } catch (error) {
        Navigator.pop(context);
        Fluttertoast.showToast(msg: 'Error: $error');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'network-request-failed') {
          return Fluttertoast.showToast(msg: 'No Internet Connection');
        } else if (e.code == "wrong-password") {
          return Fluttertoast.showToast(msg: 'Please Enter correct password');
        } else if (e.code == 'user-not-found') {
          return Fluttertoast.showToast(msg: 'Email not found');
        } else if (e.code == 'too-many-requests') {
          return Fluttertoast.showToast(
              msg: 'Too many attempts please try later');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: ColorsConst.white,
        body: SingleChildScrollView(
            child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(
                height: 24,
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Image.asset("images/splashScreen.jpg"),
              ),
              const SizedBox(
                height: 10,
              ),
              const Text("Welcome Back!",
                  style: TextStyle(
                      fontSize: 24,
                      color: ColorsConst.black,
                      fontWeight: FontWeight.bold)),
              const SizedBox(
                height: 20,
              ),
              TextField(
                controller: emailTextEditingController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                style: const TextStyle(color: ColorsConst.grey),
                decoration: InputDecoration(
                  labelText: "Email",
                  hintText: "Email",
                  enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: ColorsConst.grey),
                      borderRadius: BorderRadius.circular(10.0)),
                  focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: ColorsConst.grey)),
                  hintStyle: const TextStyle(
                    color: ColorsConst.grey,
                    fontSize: 10,
                  ),
                  labelStyle: const TextStyle(
                    color: ColorsConst.grey,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              TextField(
                controller: passwordTextEditingController,
                obscureText: !isPasswordVisible,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: ColorsConst.grey),
                decoration: InputDecoration(
                  labelText: "Password",
                  hintText: "Password",
                  enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: ColorsConst.grey),
                      borderRadius: BorderRadius.circular(10.0)),
                  focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: ColorsConst.grey)),
                  hintStyle: const TextStyle(
                    color: ColorsConst.grey,
                    fontSize: 10,
                  ),
                  labelStyle: const TextStyle(
                    color: ColorsConst.grey,
                    fontSize: 16,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.black,
                    ),
                    onPressed: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              SizedBox(
                height: 50,
                width: 300,
                child: ElevatedButton(
                    onPressed: () {
                      validateForm(context);
                      //Navigator.push(context, MaterialPageRoute(builder: (c)=> CarInfoScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsConst.greenAccent,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                          //to set border radius to button
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      "Login",
                      style: TextStyle(
                        color: ColorsConst.white,
                        fontSize: 18,
                      ),
                    )),
              ),
              const SizedBox(
                height: 10,
              ),
              GestureDetector(
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                      decoration: TextDecoration.underline,
                      color: ColorsConst.blue,
                      fontSize: 16.0),
                ),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const ForgotPassword())),
              ),
              const SizedBox(height: 12.0),
              RichText(
                  text: TextSpan(children: <TextSpan>[
                const TextSpan(
                    text: "Don't have an account? ",
                    style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w300,
                        fontFamily: 'Poppins',
                        color: ColorsConst.black)),
                TextSpan(
                    text: "Sign Up",
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (c) => const SignUpScreen())),
                    style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                        color: Colors.lightBlue)),
              ])),
            ],
          ),
        )));
  }
}
