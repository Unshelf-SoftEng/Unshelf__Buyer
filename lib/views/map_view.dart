import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:unshelf_buyer/views/home_view.dart';
import 'package:unshelf_buyer/views/profile_view.dart';
import 'package:unshelf_buyer/views/store_view.dart';

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with AutomaticKeepAliveClientMixin<MapPage> {
  @override
  bool get wantKeepAlive => true;

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  LatLng? _currentPosition;
  LatLng basePosition = const LatLng(10.30943566786076, 123.88635816441766);
  bool _isLoading = true;
  bool _locationError = false;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<Set<Marker>> _getMarkersWithinRadius(LatLng center, double radius) async {
    final Set<Marker> markers = {};

    try {
      // Fetch all documents
      final QuerySnapshot querySnapshot = await _firestore.collection('stores').get();

      final Marker marker = Marker(
        markerId: const MarkerId('your_marker'),
        position: center,
        infoWindow: const InfoWindow(title: 'You', snippet: 'Your current location'),
        onTap: () {},
      );
      markers.add(marker);

      for (final QueryDocumentSnapshot doc in querySnapshot.docs) {
        final latitude = (doc.data() as dynamic)['latitude'];
        final longitude = (doc.data() as dynamic)['longitude'];

        // Filter out invalid coordinates manually
        if (latitude == 0 || longitude == 0) {
          continue;
        }

        var distanceInMeters = await Geolocator.distanceBetween(
          latitude,
          longitude,
          center.latitude,
          center.longitude,
        );

        if (distanceInMeters <= 500) {
          final MarkerId markerId = MarkerId(doc.id);
          final Marker marker = Marker(
            markerId: markerId,
            position: LatLng(latitude, longitude),
            infoWindow: InfoWindow(title: (doc.data() as dynamic)['loc_start_address'], snippet: ''),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => StoreView(
                          storeId: doc.id,
                        )),
              );
            },
          );

          markers.add(marker);
        }
      }
    } catch (e) {
      print('Error fetching markers: $e');
    }
    return markers;
  }

  Future<void> _getLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = true;
          _isLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      LatLng location = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentPosition = location;
        _isLoading = false;
      });
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _locationError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_locationError) {
      return Scaffold(
        body: Center(
          child: Text(
            'Location permission denied or error getting location.',
            style: TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6E9E57),
        elevation: 0,
        toolbarHeight: 60,
        title: const Text(
          "Near Me",
          style: TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : FutureBuilder<Set<Marker>>(
              future: _getMarkersWithinRadius(_currentPosition!, 500),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text('Error loading map data.'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No sellers found within the radius.'));
                } else {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10.0),
                    child: SizedBox(
                      height: 600,
                      child: GoogleMap(
                        mapType: MapType.terrain,
                        initialCameraPosition: CameraPosition(
                          target: _currentPosition!,
                          zoom: 14.0,
                        ),
                        onMapCreated: (GoogleMapController controller) {
                          _controller.complete(controller);
                        },
                        markers: snapshot.data!,
                        circles: {
                          Circle(
                            circleId: const CircleId('1'),
                            center: _currentPosition!,
                            radius: 500,
                            strokeWidth: 2,
                            strokeColor: Colors.blue,
                            fillColor: Colors.blue.withOpacity(0.2),
                          )
                        },
                      ),
                    ),
                  );
                }
              },
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) => _onItemTapped(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Near Me',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeView()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MapPage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProfileView()),
        );
        break;
    }
  }
}
