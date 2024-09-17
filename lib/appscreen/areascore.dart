import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LeaderboardPage extends StatefulWidget {
  @override
  _LeaderboardPageState createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref().child('data');
  Map<String, int> _areaReportCounts = {};

  @override
  void initState() {
    super.initState();
    _fetchAreaReportCounts();
  }

  Future<void> _fetchAreaReportCounts() async {
    try {
      // Listen for data changes
      _dbRef.onValue.listen((event) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;

        if (data != null) {
          final Map<String, int> areaReportCounts = {};

          data.forEach((key, value) {
            final complaint = value as Map<dynamic, dynamic>;
            final areaName = complaint['area_name'] as String?;

            if (areaName != null) {
              areaReportCounts[areaName] =
                  (areaReportCounts[areaName] ?? 0) + 1;
            }
          });

          setState(() {
            _areaReportCounts = areaReportCounts;
          });
        }
      });
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Sorting areas by count in descending order
    final sortedAreas = _areaReportCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Leaderboard',
          style: GoogleFonts.robotoMono(
            fontSize: 20,
            color: const Color.fromARGB(255, 0, 0, 0),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10.0),
        child: DataTable(
          columnSpacing: 16,
          dataRowHeight: null, // Set to null to let DataTable manage row height
          headingRowHeight: 56,
          columns: const [
            DataColumn(
              label: Text(
                'Area Name',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Count',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: sortedAreas.map((entry) {
            return DataRow(
              cells: [
                DataCell(
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth:
                          screenWidth * 0.6, // Limit width to screen width
                    ),
                    child: Text(
                      entry.key,
                      style: TextStyle(fontSize: 16),
                      softWrap: true, // Allow text to wrap
                    ),
                  ),
                ),
                DataCell(
                  Text(entry.value.toString()),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
