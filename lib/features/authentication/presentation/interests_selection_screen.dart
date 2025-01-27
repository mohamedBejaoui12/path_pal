import 'package:flutter/material.dart';

class InterestsSelectionScreen extends StatefulWidget {
  const InterestsSelectionScreen({Key? key}) : super(key: key);

  @override
  _InterestsSelectionScreenState createState() => _InterestsSelectionScreenState();
}

class _InterestsSelectionScreenState extends State<InterestsSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select Your Interests')),
      body: Center(
        child: Text('Interests Selection Coming Soon!'),
      ),
    );
  }
}