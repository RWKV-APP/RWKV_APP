import 'package:flutter/material.dart';

class PageHome extends StatefulWidget {
  const PageHome({super.key});

  @override
  State<PageHome> createState() => _PageHomeState();
}

class _PageHomeState extends State<PageHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to RWKV Chat'),
      ),
      body: ListView.builder(
        itemBuilder: (context, index) {
          return Text('Welcome to RWKV Chat');
        },
        itemCount: 10,
      ),
    );
  }
}
