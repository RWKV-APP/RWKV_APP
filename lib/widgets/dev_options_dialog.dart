import 'package:flutter/material.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/model/feature_rollout.dart';
import 'package:zone/state/p.dart' show P;

class WithDevOption extends StatefulWidget {
  final Widget child;

  const WithDevOption({super.key, required this.child});

  @override
  State<WithDevOption> createState() => _WithDevOptionState();
}

class _WithDevOptionState extends State<WithDevOption> {
  int count = 0;
  int firstTap = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (count == 0) {
          firstTap = DateTime.now().millisecondsSinceEpoch;
        }
        count++;
        if (count >= 10) {
          final span = DateTime.now().millisecondsSinceEpoch - firstTap;
          if (span < 1500) {
            _DevOptionsDialog.show(context);
            count = 0;
          } else {
            count = 0;
          }
        }
      },
      child: widget.child,
    );
  }
}

class _DevOptionsDialog extends StatefulWidget {
  const _DevOptionsDialog();

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: .8,
          maxChildSize: .8,
          expand: false,
          snap: true,
          builder: (BuildContext context, ScrollController scrollController) {
            return const _DevOptionsDialog();
          },
        );
      },
    );
  }

  @override
  State<_DevOptionsDialog> createState() => _DevOptionsDialogState();
}

class _DevOptionsDialogState extends State<_DevOptionsDialog> {
  late FeatureRollout featureRollout = P.app.featureRollout.q;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Row(
            children: [
              Expanded(
                child: Text(
                  "Dev Options",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                ),
              ),
              CloseButton(),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 0),
            leading: const Text('Web Search', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            trailing: Switch(
              value: featureRollout.webSearch,
              onChanged: (v) {
                featureRollout = featureRollout.copyWith(webSearch: v);
                P.app.featureRollout.q = featureRollout;
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }
}
