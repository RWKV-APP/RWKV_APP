import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PageLambada extends ConsumerWidget {
  const PageLambada({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lambada'),
      ),
      body: Center(child: Text('Lambada')),
    );
  }
}
