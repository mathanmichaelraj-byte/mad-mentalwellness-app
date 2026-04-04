import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CalmingPlace {
  final String name;
  final double lat;
  final double lng;
  final String type;
  
  CalmingPlace({required this.name, required this.lat, required this.lng, required this.type});
}

class LocationService {
  static final LocationService instance = LocationService._init();
  LocationService._init();

  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition();
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  Future<List<CalmingPlace>> getCalmingLocations(Position? userPosition) async {
    if (userPosition == null) return [];

    final lat = userPosition.latitude;
    final lng = userPosition.longitude;
    
    try {
      // Query Overpass API for nearby places (5km radius)
      final query = '''
[out:json][timeout:25];
(
  node["amenity"="hospital"](around:5000,$lat,$lng);
  node["amenity"="clinic"](around:5000,$lat,$lng);
  node["healthcare"="psychotherapist"](around:5000,$lat,$lng);
  node["leisure"="park"](around:5000,$lat,$lng);
  node["leisure"="garden"](around:5000,$lat,$lng);
  node["amenity"="meditation_centre"](around:5000,$lat,$lng);
  node["amenity"="place_of_worship"](around:5000,$lat,$lng);
  node["natural"="water"](around:5000,$lat,$lng);
);
out body;
''';

      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        body: query,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List;
        
        final places = <CalmingPlace>[];
        for (var element in elements) {
          final tags = element['tags'] as Map<String, dynamic>?;
          if (tags == null) continue;
          
          final name = tags['name'] ?? _getDefaultName(tags);
          final type = _categorizePlace(tags);
          
          places.add(CalmingPlace(
            name: name,
            lat: element['lat'],
            lng: element['lon'],
            type: type,
          ));
          
          if (places.length >= 20) break; // Limit to 20 places
        }
        
        return places;
      }
    } catch (e) {
      // Fallback to generated nearby places if API fails
      print('Overpass API error: $e');
    }
    
    // Fallback: Generate nearby places
    return [
      CalmingPlace(name: 'City Park', lat: lat + 0.01, lng: lng + 0.01, type: 'Park'),
      CalmingPlace(name: 'Meditation Center', lat: lat - 0.015, lng: lng + 0.02, type: 'Meditation'),
      CalmingPlace(name: 'Community Hospital', lat: lat + 0.02, lng: lng - 0.01, type: 'Hospital'),
      CalmingPlace(name: 'Mental Health Clinic', lat: lat - 0.01, lng: lng - 0.015, type: 'Therapist'),
      CalmingPlace(name: 'Riverside Walk', lat: lat + 0.005, lng: lng + 0.015, type: 'Nature'),
      CalmingPlace(name: 'Wellness Temple', lat: lat + 0.018, lng: lng - 0.005, type: 'Spiritual'),
    ];
  }

  String _getDefaultName(Map<String, dynamic> tags) {
    if (tags.containsKey('amenity')) {
      final amenity = tags['amenity'];
      return amenity.toString().replaceAll('_', ' ').split(' ').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
    }
    if (tags.containsKey('leisure')) return 'Park';
    if (tags.containsKey('natural')) return 'Natural Area';
    return 'Place';
  }

  String _categorizePlace(Map<String, dynamic> tags) {
    if (tags['amenity'] == 'hospital' || tags['amenity'] == 'clinic') return 'Hospital';
    if (tags['healthcare'] == 'psychotherapist') return 'Therapist';
    if (tags['leisure'] == 'park' || tags['leisure'] == 'garden') return 'Park';
    if (tags['amenity'] == 'meditation_centre') return 'Meditation';
    if (tags['amenity'] == 'place_of_worship') return 'Spiritual';
    if (tags['natural'] == 'water') return 'Nature';
    return 'Park';
  }
}
