import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'HomePage.dart';

class LocationPermissionScreen extends StatefulWidget {
  @override
  _LocationPermissionScreenState createState() => _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  loc.Location location = loc.Location();

  @override
  void initState() {
    super.initState();
    _handleLocationPermission();
  }

  Future<void> _handleLocationPermission() async {
    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) return;
    }

    final locationData = await location.getLocation();
    if (locationData != null) {
      await _getAddressFromCoordinates(locationData.latitude!, locationData.longitude!);
    }
  }

  Future<void> _getAddressFromCoordinates(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        List<String> parts = [];
        if ((place.subLocality ?? '').trim().isNotEmpty) parts.add(place.subLocality!);
        if ((place.locality ?? '').trim().isNotEmpty) parts.add(place.locality!);
        if ((place.administrativeArea ?? '').trim().isNotEmpty) parts.add(place.administrativeArea!);

        String address = parts.join(', ');

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("user_location", address);
        await prefs.setBool("locationFetchedOnce", true);

        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage()));
      }
    } catch (e) {
      print("Error getting address: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade100,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center vertically
          children: [
            SpinKitThreeBounce(
              color: Colors.white,
              size: 30,// Make it visible against the green background
            ),
            SizedBox(height: 16), // Add some spacing
            Text(
              "Loading...",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

}

