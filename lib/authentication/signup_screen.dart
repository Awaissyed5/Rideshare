import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rideshare/authentication/verify_email.dart';
import '../Constants/styles/colors.dart';
import '../global/global.dart';
import '../splashScreen/splash_screen.dart';
import '../widgets/progress_dialog.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  TextEditingController nameTextEditingController = TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController phoneTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();
  TextEditingController confirmPasswordTextEditingController =
      TextEditingController();

  String imageUrl = "";
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  File? _userImage;
  final _storage = FirebaseStorage.instance;

  Future<void> _pickImage() async {
    final pickedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _userImage = File(pickedImage.path);
      });
    }
  }

  validateForm() {
    if (nameTextEditingController.text.length < 3) {
      Fluttertoast.showToast(msg: "Name must be at least 3 characters.");
    } else if (!RegExp(r'^[a-zA-Z ]+$')
        .hasMatch(nameTextEditingController.text)) {
      Fluttertoast.showToast(msg: "Name cannot contain any numbers.");
    } else if (!emailTextEditingController.text.contains("@")) {
      Fluttertoast.showToast(msg: "Email not valid.");
    } else if (phoneTextEditingController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Phone number required.");
    } else if (phoneTextEditingController.text.length != 11 ||
        !RegExp(r'^\d{11}$').hasMatch(phoneTextEditingController.text)) {
      Fluttertoast.showToast(msg: "Phone number must have exactly 11 digits.");
    } else if (passwordTextEditingController.text.length < 8) {
      Fluttertoast.showToast(msg: "Password must be at least 8 characters.");
    } else if (passwordTextEditingController.text !=
        confirmPasswordTextEditingController.text) {
      Fluttertoast.showToast(msg: "Password must be at least 8 characters.");
    } else {
      saveDriverInfo();
    }
  }

  saveDriverInfo() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext c) {
        return ProgressDialog(
          message: "Processing, Please wait...",
        );
      },
    );

    if (_userImage == null) {
      Navigator.pop(context);
      Fluttertoast.showToast(msg: "Please Upload Profile Pic!!");
      return;
    }

    try {
      // Check if mobile number already exists
      bool mobileNumberExists = await checkMobileNumberExists(
        phoneTextEditingController.text.trim(),
      );

      if (mobileNumberExists) {
        Navigator.pop(context);
        Fluttertoast.showToast(msg: "Mobile number already exists.");
        return;
      }

      final User? firebaseUser = (await fAuth.createUserWithEmailAndPassword(
        email: emailTextEditingController.text.trim(),
        password: passwordTextEditingController.text.trim(),
      ))
          .user;

      if (firebaseUser != null) {
        final imageUploadTask = await _storage
            .ref('userImages/${firebaseUser.uid}.jpg')
            .putFile(_userImage!);
        final userImageUrl = await imageUploadTask.ref.getDownloadURL();

        Map userMap = {
          "id": firebaseUser.uid,
          "name": nameTextEditingController.text.trim(),
          "email": emailTextEditingController.text.trim(),
          "phone": phoneTextEditingController.text.trim(),
          "userImage": (_userImage == null)
              ? 'https://miro.medium.com/v2/resize:fit:720/1*_ARzR7F_fff_KI14yMKBzw.png'
              : userImageUrl,
        };

        DatabaseReference driverRef = FirebaseDatabase.instance.ref("users");
        driverRef.child(firebaseUser.uid).set(userMap);

        currentFirebaseUser = firebaseUser;
        Fluttertoast.showToast(msg: "Account has been created!");
        Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => const VerifyEmailPage()),
        );
      } else {
        Navigator.pop(context);
        Fluttertoast.showToast(msg: "Account has not been created!");
      }
    } catch (error) {
      Navigator.pop(context);
      Fluttertoast.showToast(msg: "Error: $error");
    }
  }

  Future<bool> checkMobileNumberExists(String mobileNumber) async {
    DatabaseReference usersRef = FirebaseDatabase.instance.ref("users");
    DatabaseReference driversRef = FirebaseDatabase.instance.ref("drivers");

    // Check if the mobile number exists in the "users" database
    DatabaseEvent usersEvent =
        await usersRef.orderByChild("phone").equalTo(mobileNumber).once();
    DataSnapshot usersSnapshot = usersEvent.snapshot;
    Map<dynamic, dynamic>? usersMap =
        usersSnapshot.value as Map<dynamic, dynamic>?;

    // Check if the mobile number exists in the "drivers" database
    DatabaseEvent driversEvent =
        await driversRef.orderByChild("phone").equalTo(mobileNumber).once();
    DataSnapshot driversSnapshot = driversEvent.snapshot;
    Map<dynamic, dynamic>? driversMap =
        driversSnapshot.value as Map<dynamic, dynamic>?;

    // Return true if the mobile number exists in either the "users" or "drivers" database
    return usersMap != null || driversMap != null;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          backgroundColor: ColorsConst.white,
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const SizedBox(
                    height: 10,
                  ),
                  const Text(
                    "Register",
                    style: TextStyle(
                      fontSize: 24,
                      color: ColorsConst.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: showImage(),
                    /*_driverImage != null ? FileImage(_driverImage!) : null*/
                  ),
                  TextButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Add User Image')),
                  const SizedBox(
                    height: 20,
                  ),
                  TextField(
                    controller: nameTextEditingController,
                    style: const TextStyle(color: ColorsConst.grey),
                    decoration: InputDecoration(
                      labelText: "Full Name",
                      hintText: "Full Name",
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
                    controller: emailTextEditingController,
                    keyboardType: TextInputType.emailAddress,
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
                    controller: phoneTextEditingController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: ColorsConst.grey),
                    maxLength: 11,
                    decoration: InputDecoration(
                      labelText: "Phone Number",
                      hintText: "Phone Number",
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
                    keyboardType: TextInputType.text,
                    obscureText: _obscurePassword,
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
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextField(
                    controller: confirmPasswordTextEditingController,
                    keyboardType: TextInputType.text,
                    obscureText: _obscureConfirmPassword,
                    style: const TextStyle(color: ColorsConst.grey),
                    decoration: InputDecoration(
                      labelText: "Confirm Password",
                      hintText: "Confirm Password",
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
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  SizedBox(
                    height: 50,
                    width: 300,
                    child: ElevatedButton(
                        onPressed: () {
                          validateForm();

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
                          "Create Account",
                          style: TextStyle(
                            color: ColorsConst.white,
                            fontSize: 18,
                          ),
                        )),
                  ),
                  SizedBox(height: 18),
                  RichText(
                      text: TextSpan(children: <TextSpan>[
                    const TextSpan(
                        text: "Already have an account? ",
                        style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w300,
                            fontFamily: 'Poppins',
                            color: ColorsConst.black)),
                    TextSpan(
                        text: "Sign In",
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => Navigator.push(context,
                              MaterialPageRoute(builder: (c) => LoginScreen())),
                        style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                            color: Colors.lightBlue)),
                  ])),
                ],
              ),
            ),
          )),
    );
  }

  showImage() {
    if (_userImage != null) {
      return FileImage(_userImage!);
    } else {
      return const NetworkImage(
          'https://miro.medium.com/v2/resize:fit:720/1*_ARzR7F_fff_KI14yMKBzw.png');
    }
  }
}
