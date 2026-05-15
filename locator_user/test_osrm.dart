// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/72.5714,23.0225;72.6369,23.2156?overview=full&geometries=geojson&steps=false');
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final coords = data['routes'][0]['geometry']['coordinates'] as List;
      print('Status 200 OK');
      print('Number of coordinates: ${coords.length}');
      print('First 3: ${coords.take(3).toList()}');
      print('Distance: ${data['routes'][0]['distance']}');
    } else {
      print('Error: ${response.statusCode}');
    }
  } catch (e) {
    print('Exception: $e');
  }
}
