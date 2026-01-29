import 'package:flutter/material.dart';

class HomeCitizen extends StatelessWidget {
  const HomeCitizen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: SingleChildScrollView(
        child: Center(
          child: Text("Home Citizen"),
        ),
      )),
    );
  }
}
