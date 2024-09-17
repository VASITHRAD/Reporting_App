import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:reportingapp/appscreen/map.dart';
import 'package:reportingapp/firebase_options.dart';

// Initialize Google Sign-In and Firebase Auth
final GoogleSignIn _googleSignIn = GoogleSignIn();
final FirebaseAuth _auth = FirebaseAuth.instance;

Future<User?> signInWithGoogle() async {
  try {
    // Force re-authentication to ensure fresh sign-in
    await _googleSignIn.signOut();

    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      // The user canceled the sign-in
      print('Google sign-in canceled.');
      return null;
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential =
        await _auth.signInWithCredential(credential);
    final User? user = userCredential.user;

    if (user != null) {
      await handleUserPermissions(user);
    }

    return user;
  } catch (e) {
    print('Error signing in with Google: $e');
    return null;
  }
}

Future<int> _generateUniqueNumber(String uid) async {
  // Define a special UID for the waterresq user
  const specialUid = 'SPECIAL_UID_FOR_WATERRESQ';

  if (uid == specialUid) {
    return 0;
  }

  // Query existing complaints to find the next unique number
  final dbRef = FirebaseDatabase.instance.ref().child('data');
  final snapshot = await dbRef.orderByChild('unique_number').once();

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

Future<void> handleUserPermissions(User? user) async {
  if (user == null) return;

  final String email = user.email!;

  if (email == 'waterresq@gmail.com') {
    // Provide government permissions
    print('Government user detected.');
  } else {
    // Handle regular user logic
    print('Regular user detected.');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home:
          AuthWrapper(), // Use AuthWrapper to manage navigation based on authentication
    );
  }
}

class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  @override
  void initState() {
    super.initState();
    _auth.authStateChanges().listen((User? user) {
      setState(() {
        _user = user;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_user != null) {
      return MapScreen(); // User is signed in, navigate to the map screen
    } else {
      return LoginScreen(); // User is not signed in, show login screen
    }
  }
}

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            User? user = await signInWithGoogle();
            if (user != null) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => MapScreen()),
              );
            } else {
              // Handle login failure (e.g., show an error message)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to sign in with Google.')),
              );
            }
          },
          child: Text('Sign in with Google'),
        ),
      ),
    );
  }
}
