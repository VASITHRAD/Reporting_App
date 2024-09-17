import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:reportingapp/appscreen/areareport.dart';
import 'package:reportingapp/appscreen/areascore.dart';
import 'package:reportingapp/appscreen/complaint.dart';
import 'package:reportingapp/main.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _currentPosition;
  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref().child('data');
  Map<String, LatLng> _markedAreas = {};
  Map<String, int> _areaReportCounts = {};
  Map<String, List<Map<String, dynamic>>> _complaints = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _fetchComplaints();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return; // Handle the case where location services are not enabled
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        return; // Handle the case where permissions are denied forever
      }
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });
  }

  Future<void> _fetchComplaints() async {
    _dbRef.onValue.listen((event) async {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        final newMarkedAreas = <String, LatLng>{};
        final newAreaReportCounts = <String, int>{};
        final newComplaints = <String, List<Map<String, dynamic>>>{};

        data.forEach((key, value) {
          print(data);
          print(
              "___________________________________________________________________________________");
          final complaint = value as Map<dynamic, dynamic>;
          final areaName = complaint['area_name'];
          final lat = complaint['location']['lat'];
          final lon = complaint['location']['lon'];
          // final uniqueNumber = complaint['unique_number'];
          final description = complaint['incident_description'];
          final userUid = complaint['uid'];
          final reply = complaint['reply'];
          final post_id = complaint['post_id'];
          if (areaName != null && lat != null && lon != null) {
            if (!newMarkedAreas.containsKey(areaName)) {
              newMarkedAreas[areaName] = LatLng(lat, lon);
              newAreaReportCounts[areaName] = 0; // Initialize count
            }

            // Increment count for the area
            newAreaReportCounts[areaName] =
                (newAreaReportCounts[areaName] ?? 0) + 1;

            // Update complaints list for the area
            if (!newComplaints.containsKey(areaName)) {
              newComplaints[areaName] = [];
            }
            newComplaints[areaName]!.add({
              'incident_description': description,
              // 'unique_number': uniqueNumber,
              'user_uid': userUid,
              'reply': reply ?? "No reply from the government",
              'post_id': post_id
            });
          }
        });

        // Update state with the new data
        setState(() {
          _markedAreas = newMarkedAreas;
          _areaReportCounts = newAreaReportCounts;
          _complaints = newComplaints;
        });
      }
    });
  }

  Future<int> _generateUniqueNumber(String email) async {
    const specialEmail =
        'waterresq@gmail.com'; // Replace with actual special email

    if (email == specialEmail) {
      return 0;
    }

    final snapshot = await _dbRef.orderByChild('unique_number').once();
    final data = snapshot.snapshot.value as Map?;
    int maxNumber = 0;

    if (data != null) {
      data.forEach((key, value) {
        final uniqueNumber = value['unique_number'] as int?;
        if (uniqueNumber != null && uniqueNumber > maxNumber) {
          maxNumber = uniqueNumber;
        }
      });
    }

    return maxNumber + 1;
  }

  Future<int> _countMonthlyComplaints(String uid) async {
    final startOfMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final endOfMonth =
        DateTime(DateTime.now().year, DateTime.now().month + 1, 1);

    final snapshot = await _dbRef
        .orderByChild('user_uid')
        .equalTo(uid)
        .startAt(startOfMonth.toIso8601String())
        .endAt(endOfMonth.toIso8601String())
        .once();

    final data = snapshot.snapshot.value as Map?;
    return data?.length ?? 0;
  }

  Future<void> _storeComplaint(String areaName, String description) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final email = FirebaseAuth.instance.currentUser?.email;
    if (uid == null || email == null) {
      throw Exception('User not authenticated.');
    }

    final uniqueNumber = await _generateUniqueNumber(email);
    final monthlyCount = await _countMonthlyComplaints(uid);

    if (monthlyCount >= 3) {
      throw Exception('Complaint limit reached for this month.');
    }
// guess 1
    final newComplaint = {
      'area_name': areaName,
      'incident_description': description,
      'unique_number': uniqueNumber,
      'timestamp': DateTime.now().toIso8601String(),
      'user_uid': uid,
      'reply': "No reply"
    };

    final dbRef = FirebaseDatabase.instance.ref().child('data').push();
    print(dbRef);
    await dbRef.set(newComplaint);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final mapHeight = screenHeight * 0.85;
    final buttonHeight = 50.00;
    print(_markedAreas);
    print("***********************************");
    print(_areaReportCounts);
    print("###################################################");
    return SafeArea(
      child: Scaffold(
        drawer: Container(
          width: 240,
          child: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.only(top: 10),
                  height: 70,
                  color: Colors.blue,
                  child: DrawerHeader(
                    padding: EdgeInsets.all(8.0),
                    child: Center(
                      child: Text('MENU',
                          style: GoogleFonts.robotoMono(
                            fontSize: 25,
                            color: Colors.white,
                          )),
                    ),
                  ),
                ),
                ListTile(
                  title: Text(
                    'Your Area Report',
                    style: GoogleFonts.robotoMono(
                      fontSize: 20,
                      color: Colors.black87,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => NearbyIncidentsPage()),
                    );
                  },
                ),
                ListTile(
                  title: Text('Area Score',
                      style: GoogleFonts.robotoMono(
                        fontSize: 20,
                        color: Colors.black87,
                      )),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => LeaderboardPage()),
                    );
                  },
                ),
                ListTile(
                  title: Text('Logout',
                      style: GoogleFonts.robotoMono(
                        fontSize: 20,
                        color: Colors.black87,
                      )),
                  onTap: () async {
                    try {
                      await FirebaseAuth.instance.signOut();
                      // Navigate to login screen or show a message
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    } catch (e) {
                      print('Error signing out: $e');
                      // Handle sign-out error, if necessary
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to sign out.')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: SizedBox(
                height: mapHeight,
                child: _currentPosition == null
                    ? const Center(child: CircularProgressIndicator())
                    : FlutterMap(
                        options: MapOptions(
                          initialCenter: _currentPosition!,
                          initialZoom: 15,
                          interactionOptions: InteractionOptions(
                            flags: ~InteractiveFlag.doubleTapZoom,
                          ),
                        ),
                        children: [
                          openStreetMapTileLayer,
                          MarkerLayer(
                            markers: _markedAreas.entries.map((entry) {
                              final areaName = entry.key;
                              final point = entry.value;
                              return Marker(
                                point: point,
                                width: 80,
                                height: 80,
                                child: GestureDetector(
                                  onTap: () => _showComplaints(areaName),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _getMarkerColor(areaName)
                                          .withOpacity(0.5),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _areaReportCounts[areaName]
                                                .toString() ??
                                            '0',
                                        style: TextStyle(
                                          color: const Color.fromARGB(
                                              255, 0, 0, 0),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          MarkerLayer(
                            markers: _currentPosition == null
                                ? []
                                : [
                                    Marker(
                                      point: _currentPosition!,
                                      width: 50,
                                      height: 50,
                                      child: Icon(
                                        Icons.emoji_people,
                                        color: Colors.black,
                                        size: 30,
                                      ),
                                    ),
                                  ],
                          ),
                        ],
                      ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: SizedBox(
                height: buttonHeight,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReportComplaintPage(
                          onComplaintReported: (complaintDetails) {
                            print('Complaint reported: $complaintDetails');
                            // Additional logic to handle the complaint details if needed
                          },
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7.0),
                      side: BorderSide(color: Colors.black, width: 1.5),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Report an Incident',
                    style: GoogleFonts.robotoMono(
                      fontSize: 16,
                      color: const Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMarkerColor(String areaName) {
    final complaintCount = _areaReportCounts[areaName] ?? 0;
    print(complaintCount);
    if (complaintCount >= 5) return Colors.red;
    if (complaintCount >= 1) return Colors.yellow;
    return Colors.green;
  }

  Future<void> updateComplaintsStructure() async {
    final databaseRef = FirebaseDatabase.instance.ref().child('data');
    // Retrieve all complaints from the database
    final snapshot = await databaseRef.get();

    if (snapshot.exists) {
      final complaints = snapshot.value as Map<dynamic, dynamic>?;

      if (complaints != null) {
        for (var entry in complaints.entries) {
          final complaintKey = entry.key;
          final complaintData = entry.value as Map<dynamic, dynamic>?;

          if (complaintData != null && !complaintData.containsKey('replies')) {
            // Update the complaint to add the 'replies' field
            await databaseRef.child(complaintKey).update({'replies': {}});
          }
        }
      }
    }
  }

  void _showReplyDialog(String area, Map<String, dynamic> complaint) {
    final _replyController = TextEditingController();
    final _focusNode = FocusNode();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reply to Complaint'),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 200.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _replyController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Type your reply here...',
                  ),
                  maxLines: 4,
                  autofocus: true,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final replyText = _replyController.text.trim();
              if (replyText.isNotEmpty) {
                try {
                  await _replyToComplaint(area, complaint, replyText);
                  Navigator.of(context).pop(); // Close the dialog
                } catch (e) {
                  print('Error: $e');
                }
              }
            },
            child: Text('Submit'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text('Cancel'),
          ),
        ],
      ),
    ).then((_) {
      _focusNode.unfocus(); // Unfocus after dialog is closed
    });

    Future.delayed(Duration(milliseconds: 100), () {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  Future<void> _replyToComplaint(
      String area, Map<String, dynamic> complaint, String replyText) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final email = FirebaseAuth.instance.currentUser?.email;

    if (uid == null || email == null) {
      throw Exception('User not authenticated.');
    }

    // Only allow the government email to reply
    if (email != 'waterresq@gmail.com') {
      throw Exception('Only the government can reply.');
    }

    final complaintKey = complaint['post_id'] as String?;
    if (complaintKey == null) {
      throw Exception('Complaint key is missing.');
    }

    // Reference to the specific complaint's reply field
    final complaintRef =
        FirebaseDatabase.instance.ref().child('data').child(complaintKey);

    // Update the 'reply' field with the government user's reply
    await complaintRef.update({
      // 'reply': {
      //   'reply_from': email, // Government email
      //   'reply_text': replyText, // Actual reply
      //   'timestamp': DateTime.now().toIso8601String(),
      // },
      'reply': replyText,
    });

    print('Reply saved successfully and replaced the original reply field.');
  }

  void _showComplaints(String area) {
    final complaints = _complaints[area] ?? []; // Fetch complaints for the area
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final email = FirebaseAuth.instance.currentUser?.email;
    final specialEmail = 'waterresq@gmail.com'; // Government email

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Complaints in $area',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: complaints.map((complaint) {
              // For each complaint in the area
              final complaintUid = complaint['uid'] as String?;
              final replies =
                  complaint['replies'] as Map<dynamic, dynamic>? ?? {};
              final canReplyToComplaint =
                  email == specialEmail || uid == complaintUid;

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8.0),
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 1.0),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complaint['incident_description'] ?? 'No description',
                      style: TextStyle(fontSize: 20),
                    ),
                    Text(
                      "Reply: ${complaint['reply']}" ??
                          'No reply from the government',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (canReplyToComplaint)
                      TextButton(
                        onPressed: () {
                          _showReplyDialog(area, complaint);
                        },
                        child: Text('Reply'),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}

TileLayer get openStreetMapTileLayer => TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'dev.fleaflet.flutter_map.example',
    );
