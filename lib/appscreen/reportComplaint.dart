// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';

// class ReportComplaintPage extends StatefulWidget {
//   final Function(String) onComplaintReported;

//   const ReportComplaintPage({super.key, required this.onComplaintReported});

//   @override
//   _ReportComplaintPageState createState() => _ReportComplaintPageState();
// }

// class _ReportComplaintPageState extends State<ReportComplaintPage> {
//   final DatabaseReference _dbRef =
//       FirebaseDatabase.instance.ref().child('data');
//   final User? _user = FirebaseAuth.instance.currentUser;
//   int _uniqueId = -1; // Default value if ID is not set

//   @override
//   void initState() {
//     super.initState();
//     _setUniqueId();
//   }

//   Future<void> _setUniqueId() async {
//     if (_user != null) {
//       final email = _user!.email;
//       if (email == 'waterresq@gmail.com') {
//         setState(() {
//           _uniqueId = 0;
//         });
//       } else {
//         // Generate unique ID for other emails
//         // (Assuming you have a method to generate a unique ID)
//         final uniqueId = await _generateUniqueIdForUser(email!);
//         setState(() {
//           _uniqueId = uniqueId;
//         });
//       }
//     }
//   }

//   Future<int> _generateUniqueIdForUser(String email) async {
//     // Fetch current maximum unique ID and increment
//     final snapshot =
//         await _dbRef.child('unique_ids').orderByKey().limitToLast(1).get();
//     final existingIds = snapshot.value as Map?;
//     final maxId = existingIds?.keys.isNotEmpty ?? false
//         ? int.parse(existingIds!.keys.last)
//         : -1;
//     return maxId + 1;
//   }

//   Future<bool> _canReportComplaint() async {
//     if (_uniqueId == 0) {
//       return true; // No limit for email 'waterresq@gmail.com'
//     }

//     final now = DateTime.now();
//     final startOfMonth = DateTime(now.year, now.month, 1);

//     final complaintsSnapshot = await _dbRef
//         .child('complaints')
//         .orderByChild('unique_id')
//         .equalTo(_uniqueId)
//         .get();
//     print(complaintsSnapshot);
//     print("((((((((((((((((object))))))))))))))))");
//     int count = 0;
//     complaintsSnapshot.children.forEach((complaint) {
//       final complaintDate =
//           DateTime.parse(complaint.child('timestamp').value as String);
//       if (complaintDate.isAfter(startOfMonth)) {
//         count++;
//       }
//     });

//     return count < 5;
//   }

//   void _reportComplaint(String complaintDetails) async {
//     final canReport = await _canReportComplaint();
//     print(complaintDetails);
//     print("{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}");
//     if (!canReport) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//             content:
//                 Text('You have reached the limit of 3 complaints per month.')),
//       );
//       return;
//     }

//     final timestamp = DateTime.now().toIso8601String();
//     await _dbRef.push().set({
//       'unique_id': _uniqueId,
//       'complaint_details': complaintDetails,
//       'timestamp': timestamp,
//       'reply': "reply", // Add this field
//     });

//     widget.onComplaintReported(complaintDetails);
//     Navigator.pop(context);
//   }

//   Future<void> updateComplaintsStructure() async {
//     final databaseRef = FirebaseDatabase.instance.ref().child('data');
//     // Retrieve all complaints from the database
//     final snapshot = await databaseRef.get();

//     if (snapshot.exists) {
//       final complaints = snapshot.value as Map<dynamic, dynamic>?;

//       if (complaints != null) {
//         for (var entry in complaints.entries) {
//           final complaintKey = entry.key;
//           final complaintData = entry.value as Map<dynamic, dynamic>?;

//           if (complaintData != null && !complaintData.containsKey('reply')) {
//             // Update the complaint to add the 'replies' field with "No reply"
//             await databaseRef.child(complaintKey).update({
//               'reply': {'No reply': 'No replies'}
//             });
//           }
//         }
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Report a Complaint'),
//       ),
//       body: Center(
//         child: ElevatedButton(
//           onPressed: () {
//             // Example complaint reporting
//             _reportComplaint('Complaint Details');
//           },
//           child: Text('Report Complaint'),
//         ),
//       ),
//     );
//   }
// }
