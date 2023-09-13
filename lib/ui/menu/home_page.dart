import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../helpers/AppConstant.dart';
import '../../helpers/CurrencyFormat.dart';
import '../../helpers/HexColor.dart';
import '../../internet_services/ApiClient.dart';
import '../../models/DriverModel.dart';

class HomePage extends StatefulWidget {
  String accesstoken;

  HomePage({super.key, required this.accesstoken});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  LatLng? _currentPosition;
  var collection = FirebaseFirestore.instance;
  LatLng basePosition = const LatLng(-3.2087078074640756, 104.64408488084912);
  late Future _getCurrentLocationFuture;

  late List<Map<String, dynamic>> orders;
  bool isLoaded = false;

  late FollowOnLocationUpdate _followOnLocationUpdate;
  late StreamController<double?> _followCurrentLocationStreamController;

  List<LatLng> routePoints = [
    const LatLng(-3.2087078074640756, 104.64408488084912)
  ];

  bool isVisible = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocationFuture = getLocation();
    _followOnLocationUpdate = FollowOnLocationUpdate.always;
    _followCurrentLocationStreamController = StreamController<double?>();
  }

  Future<PermissionStatus> checkPermission() async {
    final status = await Permission.location.request();

    return status;
  }

  getLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        forceAndroidLocationManager: true,
        timeLimit: const Duration(seconds: 15));

    LatLng location = LatLng(position.latitude, position.longitude);
    _currentPosition = location;

    return true;
  }

  final ApiClient _apiClient = ApiClient();

  Future<DriverModel> getUserData() async {
    dynamic userRes = await _apiClient.getUserProfileData(widget.accesstoken);
    return DriverModel.fromJson(userRes as Map);
  }

  Future fetchRoute(currentPosition, destinationPosition) async {
    dynamic userRes =
        await _apiClient.drawRoute(currentPosition, destinationPosition);

    routePoints = [];
    var router =
        jsonDecode(userRes.body)['routes'][0]['geometry']['coordinates'];
    for (int i = 0; i < router.length; i++) {
      var reep = router[i].toString();
      reep = reep.replaceAll("[", "");
      reep = reep.replaceAll("]", "");

      var lat1 = reep.split(',');
      var lon1 = reep.split(',');
      routePoints.add(LatLng(double.parse(lat1[1]), double.parse(lon1[0])));
    }

    return routePoints;
  }

  Future<void> updateStatus(String token, String isActive) async {
    //get response from ApiClient
    await _apiClient.updateUserStatusData(
      token,
      isActive,
    );
  }

  Future<void> updateBalance(String token, double balance) async {
    //get response from ApiClient
    await _apiClient.updateUserBalance(
      token,
      balance,
    );
  }

  @override
  void dispose() {
    _followCurrentLocationStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: FutureBuilder(
            future: getUserData(),
            builder:
                (BuildContext context, AsyncSnapshot<DriverModel> snapshot) {
              if (snapshot.hasError) {
                return Card(
                    elevation: 6,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15))),
                    color: Colors.white,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      child: Text(
                        "Error ${snapshot.error}",
                        style: const TextStyle(
                            color: Colors.amber, fontWeight: FontWeight.bold),
                      ),
                    ));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }

              late double balanceDriver;
              if (snapshot.hasData) {
                balanceDriver = double.parse(snapshot.data!.balance_rider);
              }

              return (Text(CurrencyFormat.convertToIdr(balanceDriver),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)));
            },
          ),
          backgroundColor: HexColor("#ef9904"),
        ),
        body: FutureBuilder(future: checkPermission(), builder: (context,snapshot){

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(snapshot.data.toString())));
          return FutureBuilder(
            future: _getCurrentLocationFuture,
            builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
              return Stack(
                fit: StackFit.loose,
                children: [
                  FlutterMap(
                    options: MapOptions(
                        maxZoom: 19,
                        minZoom: 5,
                        zoom: 16,
                        center: _currentPosition,
                        onPositionChanged:
                            (MapPosition position, bool hasGesture) {
                          if (hasGesture &&
                              _followOnLocationUpdate !=
                                  FollowOnLocationUpdate.never) {
                            setState(() {
                              _followOnLocationUpdate =
                                  FollowOnLocationUpdate.never;
                            });
                          }
                        }),
                    nonRotatedChildren: [
                      Positioned(
                        right: 20,
                        top: 20,
                        child: FloatingActionButton(
                            backgroundColor: Colors.white,
                            onPressed: () {
                              // Follow the location marker on the map when location updated until user interact with the map.
                              setState(
                                    () => _followOnLocationUpdate =
                                    FollowOnLocationUpdate.always,
                              );
                              // Follow the location marker on the map and zoom the map to level 18.
                              _followCurrentLocationStreamController.add(18);
                            },
                            child: Icon(
                              Icons.my_location,
                              color: HexColor("#ef9904"),
                            )),
                      ),
                    ],
                    children: [
                      TileLayer(
                        urlTemplate:
                        "https://api.mapbox.com/styles/v1/kinton/clfnisen4000001rrhl74psie/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1Ijoia2ludG9uIiwiYSI6ImNsMmNzb3ptMTAyODczbHA3c2UyMGlpaHkifQ.Y3y9ZhRTEf5pBN1fjlRrrg",
                        additionalOptions: const {
                          'mapStyleId': AppConstants.mapboxStyleId,
                          'accessToken': AppConstants.mapboxAccessToken,
                        },
                      ),
                      CurrentLocationLayer(
                        followCurrentLocationStream: _followCurrentLocationStreamController.stream,
                        followOnLocationUpdate: _followOnLocationUpdate,
                        turnOnHeadingUpdate: TurnOnHeadingUpdate.never,
                        style:  LocationMarkerStyle(
                          marker: const DefaultLocationMarker(
                            color: Colors.white,
                            child: Icon(
                              Icons.navigation,
                              color: Colors.blue,
                            ),
                          ),
                          markerSize: const Size.square(40),
                          markerDirection: MarkerDirection.heading,
                          accuracyCircleColor: Colors.blue.withOpacity(0.1),
                          showAccuracyCircle: true,
                        ),
                        moveAnimationDuration: Duration.zero,
                      )
                    ],
                  )
                ],
              );
            },
          );
        }));
  }
}
