import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationPickerPage extends StatefulWidget {
  final LatLng initialLocation;

  const LocationPickerPage({super.key, required this.initialLocation});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  late LatLng selectedLocation;

  @override
  void initState() {
    super.initState();
    selectedLocation = widget.initialLocation;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Confirm Issue Location")),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: selectedLocation,
          zoom: 16,
        ),
        markers: {
          Marker(
            markerId: const MarkerId("issue"),
            position: selectedLocation,
            draggable: true,
            onDragEnd: (pos) {
              setState(() {
                selectedLocation = pos;
              });
            },
          ),
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.check),
        label: const Text("Confirm Location"),
        onPressed: () {
          Get.back(result: selectedLocation);
        },
      ),
    );
  }
}
