import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:running_app/utils/running_data_calculator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth_service.dart';

class RunScreen extends StatefulWidget {
  @override
  _RunScreenState createState() => _RunScreenState();
}

class _RunScreenState extends State<RunScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  List<LatLng> _path = [];
  Polyline _polyline = Polyline(
      polylineId: PolylineId('route'),
      points: [],
      color: Colors.blue,
      width: 5);
  Completer<GoogleMapController> _controller = Completer();
  Location _location = Location();
  LatLng? _currentLatLng;
  bool _isTracking = false;
  double _distance = 0.0;
  int _time = 0;
  double _calories = 0.0;
  double _averageSpeed = 0.0;
  Map<String, dynamic>? _userData;
  Timer? _timer;

  @override
  void initState() {
    print("Run screen rerendered");
    super.initState();
    requestPermission();
    _getUserData();
  }

  Future<void> _getUserData() async {
    _userData = await context.read<AuthService>().getUserData();
  }

  void requestPermission() async {
    await Permission.location.request();
    getCurrentLocation();
  }

  void getCurrentLocation() async {
    LocationData locationData = await _location.getLocation();
    setState(() {
      _currentLatLng = LatLng(locationData.latitude!, locationData.longitude!);
    });
    _location.onLocationChanged.listen((LocationData currentLocation) {
      if (_isTracking) {
        _updateLocation(currentLocation);
      }
    });
  }

  void _updateLocation(LocationData currentLocation) {
    LatLng oldLatLng = _currentLatLng!;
    LatLng newLatLng =
        LatLng(currentLocation.latitude!, currentLocation.longitude!);

    // Update distance, calories, etc. here
    double newDistance =
        RunningDataCalculator.calculateDistance(oldLatLng, newLatLng);

    // Set a threshold to filter out small movements (e.g., 5 meters)
    double distanceThreshold = 5.0;

    // Only update the distance if the change in position is greater than the threshold
    if (newDistance >= distanceThreshold) {
      setState(() {
        _currentLatLng = newLatLng;
        _distance += newDistance;
        _path.add(_currentLatLng!); // Add the new LatLng point to the path
        _polyline = Polyline(
          // Update the polyline with the new path
          polylineId: PolylineId('route'),
          points: _path,
          color: Colors.blue,
          width: 5,
        );
      });

      _averageSpeed =
          RunningDataCalculator.calculateAverageSpeed(_distance, max(_time, 1));

      if (_userData != null && _userData!['weight'] != null) {
        int userWeight = _userData!['weight'];
        _calories = RunningDataCalculator.calculateCaloriesBurned(
            _distance, userWeight, _averageSpeed);
      }
    }
  }

  void _startTracking() {
    setState(() {
      _isTracking = true;
      _startDate = DateTime.now(); // Store the start time
    });
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _time += 1;
      });
      // Update calories, distance, and average speed calculations
    });
  }

  Future<String?> _getJWTToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  String _formatDateTime(DateTime dateTime) {
    return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  void _stopTracking() async {
    if (_timer != null) {
      _timer!.cancel();
    }
    _resetPolyline();
    setState(() {
      _isTracking = false;
      _endDate = DateTime.now(); // Store the end time
    });

    // Format the start and end dates as strings
    String startDateStr = _formatDateTime(_startDate!);
    String endDateStr = _formatDateTime(_endDate!);

    try {
      String? jwtToken = await _getJWTToken();
      if (jwtToken == null) {
        throw Exception('JWT token not found');
      }
      print(jwtToken);
      final response = await http.post(
        Uri.parse(
            'https://zml72q2u2h.execute-api.eu-north-1.amazonaws.com/saverunningdata'),
        body: json.encode({
          'time': _time,
          'averageSpeed': _averageSpeed,
          'distance': _distance,
          'calories': _calories,
          'start_date': startDateStr,
          'end_date': endDateStr,
        }),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      _resetData();
      if (response.statusCode != 200) {
        throw Exception('Session has ended well done!');
      }
    } catch (error) {
      _showErrorSnackBar(error.toString());
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _resetData() {
    setState(() {
      _distance = 0.0;
      _calories = 0.0;
      _averageSpeed = 0.0;
      _time = 0;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }

  void _resetPolyline() {
    setState(() {
      _polyline = Polyline(
          polylineId: PolylineId('route'),
          points: [],
          color: Colors.blue,
          width: 5);
      _path.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Run Screen')),
      body: _currentLatLng == null
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _currentLatLng!,
                    zoom: 15.0,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  polylines: {
                    _polyline, // Add the polyline to the polylines set
                  },
                ),
                Positioned(
                  left: 20,
                  bottom: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Distance: ${_distance.toStringAsFixed(2)} m'),
                      Text('Calories: ${_calories.toStringAsFixed(2)} kcal'),
                      Text(
                          'Average speed: ${_averageSpeed.toStringAsFixed(2)} m/s'),
                      Text('Time: ${_formatTime(_time)}'),
                      SizedBox(height: 20),
                      _isTracking
                          ? ElevatedButton(
                              onPressed: _stopTracking,
                              child: Text('Stop'),
                            )
                          : ElevatedButton(
                              onPressed: _startTracking,
                              child: Text('Start'),
                            ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  String _formatTime(int timeInSeconds) {
    int hours = timeInSeconds ~/ 3600;
    int minutes = (timeInSeconds % 3600) ~/ 60;
    int seconds = timeInSeconds % 60;

    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }
}
