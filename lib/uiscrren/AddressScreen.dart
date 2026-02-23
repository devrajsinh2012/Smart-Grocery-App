import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:project5/uiscrren/PaymentMethodScreen.dart';

class AddressScreen extends StatefulWidget {
  @override
  _AddressScreenState createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  String? currentAddress;
  final TextEditingController houseNoController = TextEditingController();
  final TextEditingController streetController = TextEditingController();
  final TextEditingController landmarkController = TextEditingController();
  final TextEditingController CityVillageController = TextEditingController();
  final TextEditingController StateController = TextEditingController();
  final TextEditingController CountryController = TextEditingController();
  final TextEditingController PincodeController = TextEditingController();

  bool isLoading = false;
  bool isManualEntry = false;
  String addressType = "Home";
  bool setDefault = false;
  bool isManualEntryLoading = false;
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  String? latestSavedAddress;
  bool isFetchingSavedAddress = false;

  User? currentUser;

  double? currentLatitude;
  double? currentLongitude;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    _fetchLatestSavedAddress();
  }

  Future<void> getCurrentLocation() async {
    loc.Location location = loc.Location();

    try {
      setState(() {
        isLoading = true;
        isManualEntry = false;
      });

      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Location services are disabled.")),
          );
          return;
        }
      }

      loc.PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == loc.PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != loc.PermissionStatus.granted) {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Location permission denied.")),
          );
          return;
        }
      }

      final userLocation = await location.getLocation();

      List<Placemark> placemarks = await placemarkFromCoordinates(
        userLocation.latitude!,
        userLocation.longitude!,
      );

      Placemark place = placemarks.first;

      setState(() {
        currentAddress = [
          if (place.subLocality != null && place.subLocality!.isNotEmpty) place.subLocality,
          if (place.locality != null && place.locality!.isNotEmpty) place.locality,
          if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) place.administrativeArea,
          if (place.postalCode != null && place.postalCode!.isNotEmpty) place.postalCode,
        ].join(', ');
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> _fetchLatestSavedAddress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      isFetchingSavedAddress = true;
    });

    try {
      final doc = await FirebaseFirestore.instance.collection('UserDetail').doc(user.uid).get();
      if (doc.exists && doc.data()!.containsKey('address')) {
        setState(() {
          latestSavedAddress = doc.data()!['address'];
        });
      } else {
        setState(() {
          latestSavedAddress = "No address found";
        });
      }
    } catch (e) {
      print("❌ Error fetching address: $e");
      setState(() {
        latestSavedAddress = "Error fetching address";
      });
    } finally {
      setState(() {
        isFetchingSavedAddress = false;
      });
    }
  }



  //for saving the User Detail for the current user
  Future<void> saveAddress() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Fetching user details from Firebase Authentication
      String name = currentUser.displayName ?? 'Guest';
      String mobile = 'N/A';
      String email = currentUser.email ?? '';

      if (currentUser.displayName != null) {
        final parts = currentUser.displayName!.split('|');
        if (parts.length == 2) {
          name = parts[0];
          mobile = parts[1];
        }
      }

      // Combine manually entered address fields
      String manualAddress = [
        if (houseNoController.text.isNotEmpty) houseNoController.text,
        if (streetController.text.isNotEmpty) streetController.text,
        if (landmarkController.text.isNotEmpty) landmarkController.text,
      ].join(', ');

      // Combine manual address with fetched location address
      String fullAddress = [
        manualAddress,
        currentAddress ?? ''  // Ensure `currentAddress` is not null
      ].where((part) => part.isNotEmpty).join(', ');

      // Log the full address for debugging
      print('Full Address to be saved: $fullAddress');

      // Create the address map
      Map<String, dynamic> addressData = {
        'name': name,
        'mobile': mobile,
        'email': email,
        'address': fullAddress,
        'addressType': addressType,
        'timestamp': Timestamp.now(),
      };

      final docId = currentUser.uid;

      // Save the address to Firestore
      await FirebaseFirestore.instance
          .collection('UserDetail')
          .doc(docId)
          .set(addressData, SetOptions(merge: true)); // Ensure merge to avoid overwriting

      // Clear the text fields after saving the address
      houseNoController.clear();
      streetController.clear();
      landmarkController.clear();
      setState(() {}); // Refresh the UI

    } catch (e) {}
  }




  //for saving the User Detail for the manually Address
  Future<void> saveAddressToFirestore() async {

    if (currentUser == null) return;

    try {
      final docId = currentUser!.uid; // Using userId as document ID for simplicity

      // Fetching user details from Firebase Authentication
      String name = currentUser!.displayName ?? 'Guest';
      String mobile = 'N/A';
      String email = currentUser!.email ?? '';

      if (currentUser!.displayName != null) {
        final parts = currentUser!.displayName!.split('|');
        if (parts.length == 2) {
          name = parts[0];
          mobile = parts[1];
        }
      }

      // Combining all address fields into a single 'address' string
      String fullAddress = '${houseNoController.text}, ${streetController.text}, ${landmarkController.text}, '
                            '${CityVillageController.text}, ${StateController.text}, ${CountryController.text}, '
                            'Pincode: ${PincodeController.text}';

      // Creating the address map
      Map<String, dynamic> addressData = {
        'name': name,
        'mobile': mobile,
        'email': email,
        'address': fullAddress, // Full address as a single string
        'addressType': addressType,
        'timestamp': Timestamp.now(),
      };

      // Saving to Firestore
      await FirebaseFirestore.instance.collection('UserDetail').doc(docId).set(addressData);

      // ✅ Clear the text fields and reset variables after saving
      houseNoController.clear();
      streetController.clear();
      landmarkController.clear();
      CityVillageController.clear();
      StateController.clear();
      CountryController.clear();
      PincodeController.clear();

      setState(() {}); // Refresh the UI to reflect cleared fields
    } catch (e) {
    }
  }

  Widget buildAddressTypeButton(String type) {
    return ChoiceChip(
      label: Text(type),
      selected: addressType == type,
      selectedColor: Colors.grey[300],
      backgroundColor: Colors.white,
      onSelected: (val) {
        if (val) setState(() => addressType = type);
      },
      labelStyle: TextStyle(
        color: addressType == type ? Colors.black : Colors.black87,
      ),
      shape: StadiumBorder(
        side: BorderSide(color: Colors.grey.shade400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String name = 'Guest';
    String mobile = 'N/A';
    final email = currentUser?.email ?? "";

    if (currentUser != null && currentUser!.displayName != null) {
      final parts = currentUser!.displayName!.split('|');
      if (parts.length == 2) {
        name = parts[0];
        mobile = parts[1];
      }
    }


    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text("Select Delivery Address"),
            backgroundColor: Colors.green,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Location Button
                SizedBox(
                  width: 350,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        isLoading = true;
                        isManualEntry = false; // Ensure manual form is hidden
                      });
                      getCurrentLocation();
                    },
                    icon: Icon(Icons.my_location, color: Colors.black),
                    label: Text(
                      "Use Current Location",
                      style: TextStyle(color: Colors.black.withOpacity(0.6)),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey.shade400, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),

                // Manual Entry Button
                SizedBox(
                  width: 350,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        isManualEntryLoading = true;
                        isManualEntry = false; // Hide manual entry initially
                        currentAddress = null; // Hide current location details
                      });

                      Future.delayed(Duration(seconds: 2), () {
                        setState(() {
                          isManualEntryLoading = false;
                          isManualEntry = true; // Show manual entry form after blur effect
                        });
                      });
                    },
                    icon: Icon(Icons.edit_location_alt, color: Colors.black),
                    label: Text(
                      "Enter Address Manually",
                      style: TextStyle(color: Colors.black.withOpacity(0.6)),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey.shade400, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                if (latestSavedAddress != null && latestSavedAddress != "No address found")
                  SizedBox(
                    width: 350,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                          ),
                          builder: (context) => FractionallySizedBox(
                            heightFactor: 0.75,
                            child: PaymentMethodScreen(),
                          ),
                        );
                      },
                      icon: Icon(Icons.home, color: Colors.black),
                      label: Text(
                        latestSavedAddress!,
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.6),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.grey.shade400, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: 20),

                // Current Location Display
                if (currentAddress != null) ...[
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.black),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Current Location", style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(currentAddress ?? ''),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: getCurrentLocation,
                          child: Text(
                            "Change",
                            style: TextStyle(color: Colors.black.withOpacity(0.6)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                Form(
                    key: _formKey1,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                if (currentAddress != null) ...[
                  SizedBox(height: 20),
                  TextFormField(
                    controller: houseNoController,
                    decoration: InputDecoration(
                      labelText: "* Apartment / House No.",
                      labelStyle: TextStyle(color: Colors.black),
                      errorStyle: TextStyle(color: Colors.red), // Error message color
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your Apartment/House No.';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 5),
                  TextFormField(
                    controller: streetController,
                    decoration: InputDecoration(
                      labelText: "Apartment Name / Street Details",
                      labelStyle: TextStyle(color: Colors.black),
                      errorStyle: TextStyle(color: Colors.red),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(width: 1),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your Street Details.';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 5),
                  TextFormField(
                    controller: landmarkController,
                    decoration: InputDecoration(
                      labelText: "Landmark",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black,width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person),
                            SizedBox(width: 8),
                            Text("Name: $name", style: TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.phone),
                            SizedBox(width: 8),
                            Text("Mobile: $mobile", style: TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.email),
                            SizedBox(width: 8),
                            Text("Email: $email", style: TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  Text("Address Type"),
                  Wrap(
                    spacing: 12,
                    children: [
                      buildAddressTypeButton("Home"),
                      buildAddressTypeButton("Office"),
                      buildAddressTypeButton("Other"),
                    ],
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey1.currentState!.validate()) {
                          saveAddress();
                          Fluttertoast.showToast(
                            msg: "Address saved successfully!",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            backgroundColor: Colors.green,
                            textColor: Colors.white,
                            fontSize: 16.0,
                          );
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                            ),
                            builder: (context) => FractionallySizedBox(
                              heightFactor: 0.75,
                              child: PaymentMethodScreen(),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      child: Text("Save Address", style: TextStyle(color: Colors.black)),
                      ),
                    ),
                  ],],
                  ),),

                Form(
                  key: _formKey2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isManualEntry) ...[
                        TextFormField(
                          controller: houseNoController,
                          decoration: InputDecoration(
                            labelText: "Apartment / House No.",
                            labelStyle: TextStyle(color: Colors.black),
                            errorStyle: TextStyle(color: Colors.red),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your Apartment / House No.';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          controller: streetController,
                          decoration: InputDecoration(
                            labelText: "Apartment Name / Street Details",
                            labelStyle: TextStyle(color: Colors.black),
                            errorStyle: TextStyle(color: Colors.red),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter Street Details.';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          controller: landmarkController,
                          decoration: InputDecoration(
                            labelText: "Landmark",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          controller: CityVillageController,
                          decoration: InputDecoration(
                            labelText: "City/Village",
                            labelStyle: TextStyle(color: Colors.black),
                            errorStyle: TextStyle(color: Colors.red),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your City/Village.';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          controller: StateController,
                          decoration: InputDecoration(
                            labelText: "State",
                            labelStyle: TextStyle(color: Colors.black),
                            errorStyle: TextStyle(color: Colors.red),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your State.';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          controller: CountryController,
                          decoration: InputDecoration(
                            labelText: "Country",
                            labelStyle: TextStyle(color: Colors.black),
                            errorStyle: TextStyle(color: Colors.red),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your Country.';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          controller: PincodeController,
                          decoration: InputDecoration(
                            labelText: "Pincode",
                            labelStyle: TextStyle(color: Colors.black),
                            errorStyle: TextStyle(color: Colors.red),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your Pincode.';
                            }
                            if (value.length != 6) {
                              return 'Pincode should be 6 digits.';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.person),
                                  SizedBox(width: 8),
                                  Text("Name: $name", style: TextStyle(fontWeight: FontWeight.w500)),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.phone),
                                  SizedBox(width: 8),
                                  Text("Mobile: $mobile", style: TextStyle(fontWeight: FontWeight.w500)),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.email),
                                  SizedBox(width: 8),
                                  Text("Email: $email", style: TextStyle(fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 12),
                        Text("Address Type"),
                        Wrap(
                          spacing: 12,
                          children: [
                            buildAddressTypeButton("Home"),
                            buildAddressTypeButton("Office"),
                            buildAddressTypeButton("Other"),
                          ],
                        ),
                        SizedBox(height: 20),
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              if (_formKey2.currentState!.validate()) {
                                saveAddressToFirestore();
                                Fluttertoast.showToast(
                                  msg: "Address saved successfully!",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  backgroundColor: Colors.green,
                                  textColor: Colors.white,
                                  fontSize: 16.0,
                                );
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.white,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                                  ),
                                  builder: (context) => FractionallySizedBox(
                                    heightFactor: 0.75,
                                    child: PaymentMethodScreen(),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: BorderSide(color: Colors.black, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            child: Text("Save Address", style: TextStyle(color: Colors.black)),
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              ],
            ),
          ),
        ),

        // Loader for current location
        if (isLoading)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                color: Colors.black.withOpacity(0.2),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SpinKitThreeBounce(
                        color: Colors.white,
                        size: 30.0,
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Fetching Current Location",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Loading Blur Effect for manually Address
        if (isManualEntryLoading)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                color: Colors.black.withOpacity(0.2), // Dark overlay
                child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SpinKitThreeBounce(color: Colors.white, size: 30.0),
                        Text("Loading...",style: TextStyle(color: Colors.white,fontSize: 16, fontWeight: FontWeight.bold))
                      ],
                    ),
                  )
                ),
              ),
            ),
      ],
    );
  }
}
