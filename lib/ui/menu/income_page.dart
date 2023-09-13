import 'package:flutter/material.dart';

class IncomePage extends StatefulWidget {
  String accesstoken;
  IncomePage({super.key, required this.accesstoken});

  @override
  State<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage> {
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
