import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:running_app/screens/run_screen.dart';

import '../auth_service.dart';

class UserProfile extends StatefulWidget {
  @override
  _UserProfileState createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final userData = await context.read<AuthService>().getUserData();
      setState(() {
        _userData = userData;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Widget _buildProfileItem({required String label, String? value}) {
    return ListTile(
      title: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(value ?? 'No data'),
    );
  }

  Widget _buildRunningSession(dynamic runningSession) {
    return Card(
      child: ListTile(
        title: Text('Run ID: ${runningSession['runId']}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Time: ${runningSession['time']} seconds'),
            Text('Average Speed: ${runningSession['averageSpeed']} m/h'),
            Text('Distance: ${runningSession['distance']} m'),
            Text('Calories: ${runningSession['calories']} kcal'),
            Text('Start Date: ${runningSession['start_date']}'),
            Text('End Date: ${runningSession['end_date']}'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User Profile')),
      body: _userData == null
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchUserData,
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                children: [
                  _buildProfileItem(label: 'Name', value: _userData?['name']),
                  _buildProfileItem(label: 'Email', value: _userData?['email']),
                  _buildProfileItem(
                      label: 'Height', value: '${_userData?['height']} cm'),
                  _buildProfileItem(
                      label: 'Weight', value: '${_userData?['weight']} kg'),
                  _buildProfileItem(
                      label: 'Age', value: _userData?['age']?.toString()),
                  _buildProfileItem(
                      label: 'Gender', value: _userData?['gender']),
                  SizedBox(height: 32),
                  if (_userData?['runningData'] != null)
                    ..._userData?['runningData']
                        .map<Widget>(_buildRunningSession)
                        .toList(),
                  SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RunScreen()),
                      );
                    },
                    child: Text('Run!'),
                  ),
                  SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      context.read<AuthService>().signOut();
                    },
                    child: Text('Sign Out'),
                  ),
                ],
              ),
            ),
    );
  }
}
