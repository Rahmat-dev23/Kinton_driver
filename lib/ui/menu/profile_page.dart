import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  String accesstoken;
  ProfilePage({super.key, required this.accesstoken});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child:  TextButton(
          onPressed: () => throw Exception(),
          child: const Text("Throw Test Exception"),
        ),
      ),
    );
  }
}
