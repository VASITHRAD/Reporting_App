import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

class NearbyIncidentsPage extends StatefulWidget {
  @override
  _NearbyIncidentsPageState createState() => _NearbyIncidentsPageState();
}

class _NearbyIncidentsPageState extends State<NearbyIncidentsPage> {
  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref().child('data');
  List<Map<String, dynamic>> _incidents = [];
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return; // Handle the case where location services are not enabled
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied.');
        return; // Handle the case where permissions are denied forever
      }
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = position;
      _fetchIncidents();
    });
  }

  Future<void> _fetchIncidents() async {
    if (_currentPosition == null) return;

    final currentLat = _currentPosition!.latitude;
    final currentLon = _currentPosition!.longitude;

    try {
      _dbRef.once().then((event) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;

        if (data != null) {
          final List<Map<String, dynamic>> incidents = [];

          data.forEach((key, value) {
            final complaint = value as Map<dynamic, dynamic>;
            final areaName = complaint['area_name'] as String?;
            final lat = complaint['location']['lat'] as double?;
            final lon = complaint['location']['lon'] as double?;

            if (areaName != null && lat != null && lon != null) {
              final distance = Geolocator.distanceBetween(
                currentLat,
                currentLon,
                lat,
                lon,
              );

              if (distance <= 5000) {
                // 5 km radius
                incidents.add({
                  'areaName': areaName,
                  'incidentDescription': complaint['incident_description'],
                  'distance': distance,
                });
              }
            }
          });

          // Sort the incidents by distance in ascending order
          incidents.sort((a, b) => a['distance'].compareTo(b['distance']));

          setState(() {
            _incidents = incidents;
          });
        } else {
          print('No data found in the database.');
        }
      }).catchError((e) {
        print('Error fetching data: $e');
      });
    } catch (e) {
      print('Error fetching incidents: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Nearby Incidents',
          style: GoogleFonts.robotoMono(
            fontSize: 20,
            color: const Color.fromARGB(255, 0, 0, 0),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _incidents.isEmpty
            ? Center(child: Text('No incidents nearby.'))
            : ListView.builder(
                itemCount: _incidents.length,
                itemBuilder: (context, index) {
                  final incident = _incidents[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                          color: Colors.grey.withOpacity(0.5), width: 1.5),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    elevation: 2,
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16.0),
                      title: Text(
                        incident['areaName'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Description: ${incident['incidentDescription']}',
                        style: TextStyle(color: Colors.black54),
                      ),
                      trailing: Text(
                          '${(incident['distance'] / 1000).toStringAsFixed(2)} km'),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
