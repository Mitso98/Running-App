import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RunningDataCalculator {
  static double calculateDistance(LatLng oldLatLng, LatLng newLatLng) {
    const double earthRadius = 6371000; // in meters

    double dLat = _degreesToRadians(newLatLng.latitude - oldLatLng.latitude);
    double dLon = _degreesToRadians(newLatLng.longitude - oldLatLng.longitude);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(oldLatLng.latitude)) *
            cos(_degreesToRadians(newLatLng.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  static double calculateAverageSpeed(double distance, int time) {
    return distance / time; // m/s
  }

  static double calculateCaloriesBurned(
      double distance, int weight, double averageSpeed) {
    // MET value for running
    // Reference: https://sites.google.com/site/compendiumofphysicalactivities/
    const double metValue = 9.0;

    double distanceInKm = distance / 1000;
    double weightInKg = weight.toDouble();
    double speedInKmPerHour = averageSpeed * 3.6;

    // Time in hours
    double timeInHours = distanceInKm / speedInKmPerHour;

    // Calories burned formula: MET * weight (kg) * time (hours)
    return metValue * weightInKg * timeInHours;
  }
}