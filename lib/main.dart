import 'dart:async';
import 'dart:io';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get_navigation/get_navigation.dart';

import 'package:location/location.dart' as l;
import 'package:permission_handler/permission_handler.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
  const HomeScreen({super.key});

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
  List<Marker> allMarkers = [];
  int numOfMarkers = 0;
  LatLng mapCenter = const LatLng(50.45466, 30.5238); // Kyiv center
  double mapZoom = 9.5;
  MapController map = MapController();
  String trackFile = '';

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
          icon: const Icon(Icons.menu, color: Colors.white, size: 28),
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
      body: Stack(
        children: [
          FlutterMap(
            mapController: map,
            options: MapOptions(
              initialCenter: mapCenter,
              initialZoom: mapZoom,
            ),
            children: [
              TileLayer(
                // Display map tiles from any source
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // OSMF's Tile Server
                userAgentPackageName: 'com.petrenkodesign',
              ),
              MarkerLayer(markers: allMarkers.take(numOfMarkers).toList()),
            ],
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            backgroundColor: const Color.fromRGBO(82, 170, 94, 1.0),
            tooltip: 'Layer change',
            onPressed: () {},
            child: const Icon(Icons.layers, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            backgroundColor: const Color.fromRGBO(82, 170, 94, 1.0),
            tooltip: 'Pointed',
            onPressed: _zoomMap,
            child: const Icon(Icons.my_location, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 10),
          trackingEnabled
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
                  child: const Icon(Icons.navigation,
                      color: Colors.white, size: 28),
                ),
        ],
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
      log("GPS is enabled");
    } else {
      bool isGpsActive = await location.requestService();
      if (!isGpsActive) {
        setState(() {
          gpsEnabled = false;
        });
        log("User did not turn on GPS");
      } else {
        log("Gave GPS permission to the user and opened it");
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

  void checkStatus() async {
    bool permissionGranted = await isPermissionGranted();
    bool gpsEnabled = await isGpsEnabled();
    setState(() {
      permissionGranted = permissionGranted;
      gpsEnabled = gpsEnabled;
    });
  }

  void addLocation(l.LocationData data) async {
    setState(() {
      locations.insert(0, data);
      mapCenter = LatLng(data.latitude!, data.longitude!);
      allMarkers.add(
        Marker(
          point: mapCenter,
          height: 12,
          width: 12,
          child: const Icon(Icons.hiking,
              color: Color.fromARGB(255, 240, 101, 8), size: 12),
        ),
      );
      numOfMarkers++;
    });
    // save location in file
    final utcTime = DateTime.now().toUtc();
    writeGPX(
        '<wpt lat="${data.latitude.toString()}" lon="${data.longitude.toString()}"><ele>10.0</ele><time>${utcTime.toLocal()}</time><name>${utcTime.toLocal()}.</name><desc>Десь тут гриби</desc></wpt>');
  }

  void clearLocation() {
    setState(() {
      locations.clear();
      allMarkers.clear();
    });
  }

  void startTracking() async {
    setState(() {
      trackingEnabled = true;
    });
    trackFile = getFileName();
    if (!(await isPermissionGranted())) {
      requestLocationPermission();
      return;
    }
    if (!(await isGpsEnabled())) {
      requestEnableGps();
      return;
    }
    if (!(await requestStoragePermissions())) {
      return;
    }
    writeGPX(gpxHeader());
    subscription = location.onLocationChanged.listen((event) {
      addLocation(event);
    });
  }

  void stopTracking() async {
    subscription.cancel();
    setState(() {
      trackingEnabled = false;
    });
    clearLocation();
    await writeGPX('</gpx>');
    trackFile = '';
  }

  void _zoomMap() {
    mapZoom = 18.0;
    map.move(mapCenter, mapZoom);
  }

  String getFileName() {
    final now = DateTime.now();
    return 'track_${DateFormat("y-mm-dd-HH-mm-ss").format(now)}';
  }

  String gpxHeader() {
    final localdate = DateTime.now().toUtc().toLocal();
    var res = '<?xml version="1.0" encoding="UTF-8"?> \n';
    res += '<gpx version="1.1" creator="Mooshroom Hunter"> \n';
    res += '<metadata> \n';
    res += '<name>$trackFile</name> \n';
    res += '<time>$localdate</time> \n';
    res += '</metadata> \n';
    return res;
  }

  Future<String> get _localPath async {
    // final directory = await getApplicationDocumentsDirectory(); // for IOS
    final directory = Directory("/storage/emulated/0/Download/Tracks");
    if (!directory.existsSync()) {
      await directory.create();
    }
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$trackFile.gpx');
  }

  Future<void> writeGPX(String rec) async {
    try {
      if (Platform.isAndroid) {
        final file = await _localFile;
        final res = await file.writeAsString('$rec\n',
            mode: FileMode.append, flush: true);
        log('File saved in: ${res.path}');
      } else {
        // IOS
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  static Future<bool> requestStoragePermissions() async {
    var status = await Permission.storage.status;
    log("Storage permission satus: $status");
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    return status == PermissionStatus.granted;
  }
}
