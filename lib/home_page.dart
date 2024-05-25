import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin{
  final Completer<GoogleMapController> _controller = Completer();
  late GoogleMapController _mapController;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(23.777176, 90.399452),
    zoom: 14,
  );

  final List<Marker> _markers = <Marker>[];

  Future<Position> _getUserCurrentLocation() async {
    await Geolocator.requestPermission().then((value) {}).onError((error, stackTrace) {
      print(error.toString());
    });

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
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
          infoWindow: InfoWindow(title: 'Current Location')));

      final GoogleMapController controller = await _controller.future;
      _mapController = controller;
      CameraPosition kGooglePlex = CameraPosition(
        target: LatLng(value.latitude, value.longitude),
        zoom: 17,
        bearing: 360.0,
        tilt: 45.0,
      );
      Future.delayed(Duration(seconds: 2));
      animateMapViewCenterToCoordinates(LatLng(value.latitude, value.longitude), kGooglePlex);

      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Google Map Example',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
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
              borderRadius: BorderRadius.circular(12),
              child: GoogleMapSet(),
            ),
          ),
        ),
      ),
    );
  }

  Widget GoogleMapSet() {
    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: _kGooglePlex,
      markers: Set<Marker>.of(_markers),
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      myLocationEnabled: false,
      onMapCreated: (GoogleMapController controller) {
        _controller.complete(controller);
      },
    );
  }

  void animateMapViewCenterToCoordinates(final LatLng coordinates, CameraPosition target) {
    final LatLng mapViewCenter = target.target;
    final Tween<double> _latTween = Tween<double>(begin: mapViewCenter.latitude, end: coordinates.latitude);
    final Tween<double> _lngTween = Tween<double>(begin: mapViewCenter.longitude, end: coordinates.longitude);

    final AnimationController controller = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    final Animation<double> animation = CurvedAnimation(
      parent: controller,
      curve: Curves.fastOutSlowIn,
    );

    controller.addListener(() {
      moveMapViewCenterToCoordinates(
        LatLng(_latTween.evaluate(animation), _lngTween.evaluate(animation)),
      );
    });

    animation.addStatusListener((final AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      } else if (status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });
    controller.forward();
  }

  void moveMapViewCenterToCoordinates(final LatLng coordinates) {
    _mapController.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(coordinates.latitude, coordinates.longitude),
      ),
    );
  }
}
