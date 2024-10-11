import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get_navigation/get_navigation.dart';

import 'package:location/location.dart' as l;
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const GetMaterialApp(
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool gpsEnabled = false;
  bool permissionGranted = false;
  l.Location location = l.Location();
  late StreamSubscription subscription;
  bool trackingEnabled = false;

  List<l.LocationData> locations = [];

  @override
  void initState() {
    super.initState();
    checkStatus();
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mushroom Hunter",
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color.fromRGBO(82, 170, 94, 1.0),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white, size: 28),
            tooltip: 'Setting Icon',
            onPressed: () => showDialog<String>(
              context: context,
              builder: (BuildContext context) => AlertDialog(
                title: const Text('Налаштування'),
                content:
                    const Text('Налаштування знаходиться в статусі розробки'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.pop(context, 'OK'),
                    child: const Text('OK'),
                  ),
                ],
              ),
            ),
          ), //IconButton
        ], //<Widget>[]
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white, size: 28),
          tooltip: 'Menu Icon',
          onPressed: () => showDialog<String>(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: const Text('Меню'),
              content: const Text('Меню знаходиться в статусі розробки'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context, 'OK'),
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        ),
        elevation: 50.0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
                child: ListView.builder(
              itemCount: locations.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                      "${locations[index].latitude} ${locations[index].longitude}"),
                );
              },
            ))
          ],
        ),
      ),
      floatingActionButton: trackingEnabled
          ? FloatingActionButton(
              backgroundColor: const Color.fromRGBO(82, 170, 94, 1.0),
              tooltip: 'Stop Tracking',
              onPressed: () {
                stopTracking();
              },
              child: const Icon(Icons.navigation_outlined,
                  color: Colors.white, size: 28),
            )
          : FloatingActionButton(
              backgroundColor: const Color.fromRGBO(82, 170, 94, 1.0),
              tooltip: 'Start Tracking',
              onPressed: () {
                startTracking();
              },
              child:
                  const Icon(Icons.navigation, color: Colors.white, size: 28),
            ),
    );
  }

  ListTile buildListTile(
    String title,
    Widget? trailing,
  ) {
    return ListTile(
      dense: true,
      title: Text(title),
      trailing: trailing,
    );
  }

  void requestEnableGps() async {
    if (gpsEnabled) {
      log("Already open");
    } else {
      bool isGpsActive = await location.requestService();
      if (!isGpsActive) {
        setState(() {
          gpsEnabled = false;
        });
        log("User did not turn on GPS");
      } else {
        log("gave permission to the user and opened it");
        setState(() {
          gpsEnabled = true;
          if (trackingEnabled) startTracking();
        });
      }
    }
  }

  void requestLocationPermission() async {
    PermissionStatus permissionStatus =
        await Permission.locationWhenInUse.request();
    if (permissionStatus == PermissionStatus.granted) {
      setState(() {
        permissionGranted = true;
        if (trackingEnabled) startTracking();
      });
    } else {
      setState(() {
        permissionGranted = false;
      });
    }
  }

  Future<bool> isPermissionGranted() async {
    return await Permission.locationWhenInUse.isGranted;
  }

  Future<bool> isGpsEnabled() async {
    return await Permission.location.serviceStatus.isEnabled;
  }

  checkStatus() async {
    bool permissionGranted = await isPermissionGranted();
    bool gpsEnabled = await isGpsEnabled();
    setState(() {
      permissionGranted = permissionGranted;
      gpsEnabled = gpsEnabled;
    });
  }

  addLocation(l.LocationData data) {
    setState(() {
      locations.insert(0, data);
    });
  }

  clearLocation() {
    setState(() {
      locations.clear();
    });
  }

  void startTracking() async {
    setState(() {
      trackingEnabled = true;
    });
    if (!(await isPermissionGranted())) {
      requestLocationPermission();
      return;
    }
    if (!(await isGpsEnabled())) {
      requestEnableGps();
      return;
    }
    subscription = location.onLocationChanged.listen((event) {
      addLocation(event);
    });
  }

  void stopTracking() {
    subscription.cancel();
    setState(() {
      trackingEnabled = false;
    });
    clearLocation();
  }
}
