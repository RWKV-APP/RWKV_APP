import 'package:flutter/material.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/store/p.dart';

class RagInitDialog extends StatefulWidget {
  const RagInitDialog({super.key});

  static Future show(BuildContext context) async {
    await showDialog(context: context, builder: (c) => RagInitDialog());
  }

  @override
  State<RagInitDialog> createState() => _RagInitDialogState();
}

class _RagInitDialogState extends State<RagInitDialog> {
  String? error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await P.rag.loadModel();
        // await Future.delayed(4000.ms);
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        error = e.toString();
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 24),
          if (error == null) CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            error == null ? S.of(context).model_loading : error!,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        if (error != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(S.current.ok),
          ),
      ],
    );
  }
}
