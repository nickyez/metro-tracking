import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  BitmapDescriptor? driver;
  Position? position;
  Completer<GoogleMapController> _controller = Completer();
  GoogleMapController? mapController;
  Marker? driverMarker, destinationMarker;
  LatLng? driverPosition, destinationPosition;
  final CameraPosition _camera = CameraPosition(
      target: LatLng(-7.9443456, 112.6193162), zoom: 19.151926040649414);

  LatLng _lastMapPosition = _center;

  static const LatLng _center = const LatLng(45.521563, -122.677433);

  @override
  void initState() {
    super.initState();
    setMarkerIcon().then((value) {
      setState(() {});
    });
    setup().then((value) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        mapType: MapType.normal,
        zoomControlsEnabled: false,
        initialCameraPosition: _camera,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        markers: {
          driverMarker ?? Marker(markerId: MarkerId("bruh")),
          destinationMarker ?? Marker(markerId: MarkerId("bruh"))
        },
        onCameraMove: _onCameraMove,
      ),
    );
  }

  void _onCameraMove(CameraPosition position) {
    _lastMapPosition = position.target;
  }

  Future<bool> setup() async {
    position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    print("mylocation:  ${position!.latitude}, ${position!.longitude}");
    driverPosition = LatLng(position!.latitude, position!.longitude);
    destinationPosition = LatLng(-7.9443456, 112.6193162);
    driverMarker = Marker(
        markerId: MarkerId("driver"),
        position: LatLng(position!.latitude, position!.longitude),
        icon: driver!);
    destinationMarker = const Marker(
        markerId: MarkerId("destination"),
        position: LatLng(-7.9443456, 112.6193162));
    return true;
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _controller.complete(controller);

    LatLngBounds bound = LatLngBounds(
        southwest: destinationPosition!, northeast: driverPosition!);

    CameraUpdate u2 = CameraUpdate.newLatLngBounds(bound, 50);
    mapController!.animateCamera(u2).then((void v) {
      check(u2, mapController!);
    });
  }

  void check(CameraUpdate u, GoogleMapController c) async {
    c.animateCamera(u);
    mapController!.animateCamera(u);
    LatLngBounds l1 = await c.getVisibleRegion();
    LatLngBounds l2 = await c.getVisibleRegion();
    print(l1.toString());
    print(l2.toString());
    if (l1.southwest.latitude == -90 || l2.southwest.latitude == -90)
      check(u, c);
  }

  Future<bool> setMarkerIcon() async {
    try{
      driver = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 2.5),
        'assets/img/ic_truck.bmp');
      return true;
    }catch (e){
      print(e);
      return false;
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }
}