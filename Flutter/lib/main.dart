import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:running_app/screens/signin.dart';
import 'package:running_app/screens/user_profile.dart';

import 'auth_service.dart';

void main() {
  runApp(AuthenticationApp());
}

class AuthenticationApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthService()),
      ],
      child: MaterialApp(
        title: 'Authentication App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Home(),
      ),
    );
  }
}

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Consumer<AuthService>(
          builder: (context, authService, _) =>
              authService.isAuthenticated ? UserProfile() : SignIn(),
        ),
      ),
    );
  }
}
