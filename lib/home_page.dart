import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Completer<GoogleMapController> _controller = Completer();
  CameraPosition? _currentCameraPosition;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(23.777176, 90.399452),
    zoom: 14,
  );

  final List<Marker> _markers = <Marker>[];

  Future<Position> _getUserCurrentLocation() async {
    await Geolocator.requestPermission()
        .then((value) {})
        .onError((error, stackTrace) {
      print(error.toString());
    });

    return await Geolocator.getCurrentPosition();
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  loadData() {
    _getUserCurrentLocation().then((value) async {
      _markers.add(Marker(
          markerId: const MarkerId('1'),
          position: LatLng(value.latitude, value.longitude),
          infoWindow: const InfoWindow(title: 'Current Location')));

      final GoogleMapController controller = await _controller.future;
      CameraPosition targetPosition = CameraPosition(
        target: LatLng(value.latitude, value.longitude),
        zoom: 16,
      );
      _smoothMoveCamera(controller, targetPosition);
      setState(() {});
    });
  }

  void _smoothMoveCamera(GoogleMapController controller, CameraPosition targetPosition) async {
    if (_currentCameraPosition == null) {
      _currentCameraPosition = targetPosition;
    }

    final CameraPosition startPosition = _currentCameraPosition!;

    final double latDiff = targetPosition.target.latitude - startPosition.target.latitude;
    final double lngDiff = targetPosition.target.longitude - startPosition.target.longitude;
    final double zoomDiff = targetPosition.zoom - startPosition.zoom;

    const int steps = 20;
    const Duration stepDuration = Duration(milliseconds: 200);
    final double stepLat = latDiff / steps;
    final double stepLng = lngDiff / steps;
    final double stepZoom = zoomDiff / steps;

    for (int i = 0; i < steps; i++) {
      CameraPosition intermediatePosition = CameraPosition(
        target: LatLng(
          startPosition.target.latitude + stepLat * i,
          startPosition.target.longitude + stepLng * i,
        ),
        zoom: startPosition.zoom + stepZoom * i,
      );
      controller.animateCamera(CameraUpdate.newCameraPosition(intermediatePosition));
      await Future.delayed(stepDuration);
    }

    // Final camera position to ensure it ends up exactly at the target
    controller.animateCamera(CameraUpdate.newCameraPosition(targetPosition));
    _currentCameraPosition = targetPosition;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text(
            'Google Map Example',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.blue),
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: 220,
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          child: Card(
            elevation: 6,
            shadowColor: Colors.blue,
            surfaceTintColor: Colors.white,
            color: Colors.white,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: GoogleMapSet(),
            ),
          ),
        ),
      ),
    );
  }

  Widget GoogleMapSet(){
    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: _kGooglePlex,
      markers: Set<Marker>.of(_markers),
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      myLocationEnabled: false,
      onCameraMove: (CameraPosition position) {
        _currentCameraPosition = position;
      },
      onMapCreated: (GoogleMapController controller) {
        _controller.complete(controller);
      },
    );
  }
}
