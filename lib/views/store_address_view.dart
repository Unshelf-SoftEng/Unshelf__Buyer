// views/edit_store_location_view.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:unshelf_buyer/viewmodels/order_address_viewmodel.dart';

class StoreAddressView extends StatelessWidget {
  double latitude = 10.3157;
  double longitude = 123.8854;

  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6E9E57),
        elevation: 0,
        toolbarHeight: 60,
        title: const Text(
          'Store Location',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: latitude != null && longitude != null
              ? LatLng(
                  latitude!,
                  longitude!,
                )
              : const LatLng(10.3521, 103.8198),
          zoom: 15,
        ),
        onMapCreated: setMapController,
        onTap: (LatLng location) {
          latitude = location.latitude;
          longitude = location.longitude;
          debugPrint("LOCATION:  $latitude $longitude");
          // update location!
          // viewModel.updateLocation(location);
        },
        markers: {
          Marker(
            markerId: const MarkerId('chosen_location'),
            position: LatLng(
              latitude ?? 10.3092615,
              longitude ?? 123.8863528,
            ),
            draggable: true,
            onDragEnd: (LatLng newPosition) {
              latitude = newPosition.latitude;
              longitude = newPosition.longitude;
              debugPrint("POSITION:  $latitude $longitude");
              // viewModel.updateLocation(newPosition);
              // insert update location logic here
            },
          ),
        },
      ),
    );
  }

  setMapController(GoogleMapController controller) {
    _mapController = controller;
  }
}
