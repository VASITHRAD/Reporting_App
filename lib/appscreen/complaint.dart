import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class ReportComplaintPage extends StatefulWidget {
  const ReportComplaintPage(
      {super.key,
      required Null Function(dynamic complaintDetails) onComplaintReported});

  @override
  _ReportComplaintPageState createState() => _ReportComplaintPageState();
}

class _ReportComplaintPageState extends State<ReportComplaintPage> {
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _incidentController = TextEditingController();
  final Map<String, List<String>> _complaints = {};
  final Map<String, LatLng> _markedAreas = {};
  final Map<String, int> _areaReportCounts = {};
  LatLng? _selectedArea;
  String? _selectedCrime;
  bool _isFormValid = false;

  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref().child('data');

  Future<List<String>> _getSuggestions(String query) async {
    final url =
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map<String>((item) => item['display_name']).toList();
    } else {
      throw Exception('Failed to load suggestions');
    }
  }

  void _onAreaSelected(String selectedArea) async {
    final url =
        'https://nominatim.openstreetmap.org/search?q=$selectedArea&format=json&addressdetails=1';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      if (data.isNotEmpty) {
        final location = data[0];
        final LatLng point = LatLng(
            double.parse(location['lat']), double.parse(location['lon']));
        setState(() {
          _selectedArea = point;
          _markedAreas[selectedArea] = point;
          _areaReportCounts[selectedArea] =
              (_areaReportCounts[selectedArea] ?? 0) + 1;

          // Store the complaint in Firebase
          _submitComplaint();

          // Validate form and update UI
          _validateForm();
        });
      }
    }
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _selectedCrime != null &&
          _areaController.text.isNotEmpty &&
          _incidentController.text.isNotEmpty;
    });
  }

  void _submitComplaint() {
    final areaName = _areaController.text;
    final incidentDescription = _incidentController.text;
    final crime = _selectedCrime;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final reply = "No reply from the government";

    if (areaName.isNotEmpty && incidentDescription.isNotEmpty) {
      // Generate a unique key for the complaint
      final newComplaintRef = _dbRef.push();
      final postId = newComplaintRef.key; // Get the generated unique ID

      final newComplaint = {
        'post_id': postId,
        'crime_type': crime,
        'area_name': areaName,
        'incident_description': incidentDescription,
        'location': {
          'lat': _selectedArea?.latitude,
          'lon': _selectedArea?.longitude,
        },
        'timestamp': DateTime.now().toIso8601String(),
        'uid': uid,
        'reply': reply,
      };

      // Set the new complaint under the unique key
      newComplaintRef.set(newComplaint);

      // Update the local state
      setState(() {
        _complaints[areaName] =
            (_complaints[areaName] ?? []) + [incidentDescription];
        _areaController.clear();
        _incidentController.clear();
        _selectedCrime = null;
        _selectedArea = null;
        _isFormValid = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Complaint submitted successfully!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Report a Complaint',
          style: GoogleFonts.robotoMono(
            fontSize: 25,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What crime has occurred to you?',
                    style: GoogleFonts.robotoMono(
                      fontSize: 20,
                      color: Colors.black87,
                    ),
                  ),
                  ListTile(
                    title: Text(
                      'Theft',
                      style: GoogleFonts.robotoMono(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    leading: Radio(
                      value: 'Theft',
                      groupValue: _selectedCrime,
                      onChanged: (value) {
                        setState(() {
                          _selectedCrime = value;
                          _validateForm();
                        });
                      },
                    ),
                  ),
                  ListTile(
                    title: Text(
                      'Abuse',
                      style: GoogleFonts.robotoMono(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    leading: Radio(
                      value: 'Abuse',
                      groupValue: _selectedCrime,
                      onChanged: (value) {
                        setState(() {
                          _selectedCrime = value;
                          _validateForm();
                        });
                      },
                    ),
                  ),
                  ListTile(
                    title: Text(
                      'Others',
                      style: GoogleFonts.robotoMono(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    leading: Radio(
                      value: 'Others',
                      groupValue: _selectedCrime,
                      onChanged: (value) {
                        setState(() {
                          _selectedCrime = value;
                          _validateForm();
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Enter the area name:',
                    style: GoogleFonts.robotoMono(
                      fontSize: 20,
                      color: Colors.black87,
                    ),
                  ),
                  TypeAheadField(
                    textFieldConfiguration: TextFieldConfiguration(
                      controller: _areaController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Start typing the area name...',
                      ),
                    ),
                    suggestionsCallback: _getSuggestions,
                    itemBuilder: (context, suggestion) {
                      return ListTile(
                        title: Text(suggestion),
                      );
                    },
                    onSuggestionSelected: (suggestion) {
                      _areaController.text = suggestion;
                      _onAreaSelected(suggestion);
                    },
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Explain the incident to us:',
                    style: GoogleFonts.robotoMono(
                      fontSize: 20,
                      color: Colors.black87,
                    ),
                  ),
                  TextField(
                    controller: _incidentController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Describe your incident...',
                    ),
                    onChanged: (text) {
                      _validateForm();
                    },
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isFormValid ? _submitComplaint : null,
                    child: Text('Submit Complaint'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
