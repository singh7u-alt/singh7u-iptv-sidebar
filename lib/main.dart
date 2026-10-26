import 'package:flutter/material.dart';
import 'screens/home.dart';

void main() => runApp(const M3UPlayer());

class M3UPlayer extends StatelessWidget {
  const M3UPlayer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Live Tv',
      theme: ThemeData.dark(useMaterial3: true),
      home: const Scaffold(body: SafeArea(child: Home())),
    );
  }
}
