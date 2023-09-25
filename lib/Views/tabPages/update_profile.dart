import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rideshare_driver/Constants/styles/colors.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../main.dart';

class UpdateProfile extends StatefulWidget {
  const UpdateProfile({super.key, required this.userKey});

  final String userKey;

  @override
  State<UpdateProfile> createState() => _UpdateProfileState();
}

class _UpdateProfileState extends State<UpdateProfile> {
  String imageUrl = "";
  File? _userImage;
  final _storage = FirebaseStorage.instance;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final carMakeController = TextEditingController();
  final carModelController = TextEditingController();
  final carColorController = TextEditingController();
  final carPlateController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  void getUserData() async {
    DataSnapshot userUpdateRef = await driversRef.child(widget.userKey).get();
    Map userData = userUpdateRef.value as Map;
    nameController.text = userData['name'];
    phoneController.text = userData['phone'];
    carMakeController.text = userData['car_make'];
    carModelController.text = userData['car_model'];
    carColorController.text = userData['car_color'];
    carPlateController.text = userData['car_plateNo'];
    String imagePath = userData['driver_image'];
    if (imagePath != null && imagePath.isNotEmpty) {
      File imageFile = File(imagePath);
      setState(() {
        _userImage = imageFile;
      });
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorsConst.white,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.close),
          color: ColorsConst.black,
        ),
        title: const Text(
          "Update your profile",
          style: TextStyle(color: ColorsConst.black),
        ),
        elevation: 0,
      ),
      body: textFields(context),
    );
  }

  Widget textFields(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.only(left: 18.0, right: 18.0, top: 10.0),
          child: Column(
            children: [
              FutureBuilder<String>(
                future: showImage(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(snapshot.data!),
                    );
                  } else if (snapshot.hasError) {
                    // Handle the error case
                    return CircleAvatar(
                      radius: 50,
                      backgroundImage: const NetworkImage(
                        'https://miro.medium.com/v2/resize:fit:720/1*_ARzR7F_fff_KI14yMKBzw.png',
                      ),
                    );
                  } else {
                    // Display a progress indicator while loading
                    return CircleAvatar(
                      radius: 50,
                      child: CircularProgressIndicator(),
                    );
                  }
                },
              ),
              TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Add User Image')),
              const SizedBox(
                height: 20,
              ),
              TextFormField(
                controller: nameController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(color: ColorsConst.grey),
                decoration: InputDecoration(
                  labelText: "Name",
                  hintText: "Name",
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
                validator: (value) {
                  if (value!.length < 3) {
                    return "Name must be at least 3 characters.";
                  } else if (!RegExp(r'^[a-zA-Z ]*$').hasMatch(value)) {
                    return "Name cannot contain any numbers.";
                  }
                  return null;
                },
              ),
              const SizedBox(
                height: 15.0,
              ),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(color: ColorsConst.grey),
                decoration: InputDecoration(
                  labelText: "Phone",
                  hintText: "Phone",
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
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Phone number required.";
                  } else if (!RegExp(r'^\d{11}$').hasMatch(value)) {
                    return "Phone number must be exactly 11 digits.";
                  }
                  return null;
                },
              ),
              const SizedBox(
                height: 20,
              ),
              TextFormField(
                controller: carColorController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(color: ColorsConst.grey),
                decoration: InputDecoration(
                    labelText: "Car color",
                    hintText: "Car color",
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
                    )),
              ),
              const SizedBox(
                height: 20,
              ),
              TextFormField(
                controller: carMakeController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(color: ColorsConst.grey),
                decoration: InputDecoration(
                    labelText: "Car make",
                    hintText: "Car make",
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
                    )),
              ),
              const SizedBox(
                height: 20,
              ),
              TextFormField(
                controller: carModelController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                style: const TextStyle(color: ColorsConst.grey),
                decoration: InputDecoration(
                    labelText: "Car model",
                    hintText: "Car model",
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
                    )),
              ),
              const SizedBox(
                height: 20,
              ),
              TextFormField(
                controller: carPlateController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                style: const TextStyle(color: ColorsConst.grey),
                decoration: InputDecoration(
                    labelText: "Plate number",
                    hintText: "Plate number",
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
                    )),
              ),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50)),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    // Check if the new phone number already exists
                    bool mobileNumberExists =
                        await checkMobileNumberExists(phoneController.text);

                    if (mobileNumberExists) {
                      Fluttertoast.showToast(
                          msg: "Phone number already exists.");
                    } else {
                      Map<String, String> users = {
                        'name': nameController.text,
                        'phone': phoneController.text,
                        'car_color': carColorController.text,
                        'car_make': carMakeController.text,
                        'car_model': carModelController.text,
                        'car_plateNo': carPlateController.text,
                      };

                      try {
                        driversRef
                            .child(widget.userKey)
                            .update(users)
                            .then((value) => {
                                  Fluttertoast.showToast(
                                      msg: "Driver information updated"),
                                  Navigator.pop(context)
                                });
                      } catch (exp) {
                        Fluttertoast.showToast(msg: "Error updating $exp");
                      }
                    }
                  }
                },
                child: const Text("Update my profile"),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    DataSnapshot userUpdateRef = await driversRef.child(widget.userKey).get();
    Map userData = userUpdateRef.value as Map;
    final pickedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _userImage = File(pickedImage.path);
      });

      final User? firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser != null) {
        final imageUploadTask = await _storage
            .ref('driverImages/${firebaseUser.uid}.jpg')
            .putFile(_userImage!);
        final userImageUrl = await imageUploadTask.ref.getDownloadURL();

        Map<String, dynamic> userMap = {
          "driver_image": (_userImage == null)
              ? 'https://miro.medium.com/v2/resize:fit:720/1*_ARzR7F_fff_KI14yMKBzw.png'
              : userImageUrl,
        };

        DatabaseReference driverRef = FirebaseDatabase.instance.ref("drivers");
        driverRef.child(firebaseUser.uid).update(userMap);
      }

      setState(() {
        imageUrl = userData['driver_image'];
      });
    }
  }

  Future<String> showImage() async {
    DataSnapshot userUpdateRef = await driversRef.child(widget.userKey).get();
    Map userData = userUpdateRef.value as Map;
    String? imageUrl = userData['driver_image'];

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return imageUrl;
    } else {
      return 'https://miro.medium.com/v2/resize:fit:720/1*_ARzR7F_fff_KI14yMKBzw.png';
    }
  }
}
