// views/edit_store_location_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:unshelf_buyer/viewmodels/store_viewmodel.dart';

class StoreAddressView extends StatelessWidget {
  double latitude = 10.3157;
  double longitude = 123.8854;

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
      body: FlutterMap(
        options: MapOptions(
          initialCenter: latitude != null && longitude != null
              ? LatLng(
                  latitude!,
                  longitude!,
                )
              : LatLng(latitude, longitude), // Center the map over London
          initialZoom: 15,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // OSMF's Tile Server
            userAgentPackageName: 'com.example.app',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(latitude, longitude),
                rotate: true,
                child: const Icon(
                  color: Colors.lightGreen,
                  Icons.pin_drop_rounded,
                  size: 50,
                ),
              ),
            ],
          ),
          CurrentLocationLayer(),
        ],
      ),
    );
  }
}
