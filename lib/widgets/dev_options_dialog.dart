// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:halo_state/halo_state.dart';

// Project imports:
import 'package:zone/model/feature_rollout.dart';
import 'package:zone/store/albatross.dart';
import 'package:zone/store/p.dart' show P, $Preference;

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
        if (count >= 6) {
          final span = DateTime.now().millisecondsSinceEpoch - firstTap;
          if (span < 1300) {
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
  final TextEditingController _controllerHost = TextEditingController(text: Albatross.instance.host);

  @override
  void initState() {
    super.initState();
  }


  @override
  void dispose() {
    final host = _controllerHost.text;
    if (host != Albatross.instance.host) {
      Albatross.instance.host = host;
      Albatross.instance.init();
    }
    _controllerHost.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const .symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          const SizedBox(height: 8),
          const Row(
            children: [
              Expanded(
                child: Text(
                  "Dev Options",
                  style: TextStyle(fontWeight: .w600, fontSize: 18),
                ),
              ),
              CloseButton(),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: const .symmetric(horizontal: 0),
            leading: const Text('Web Search', style: TextStyle(fontSize: 16, fontWeight: .w600)),
            trailing: Switch(
              value: featureRollout.webSearch,
              onChanged: (v) {
                featureRollout = featureRollout.copyWith(webSearch: v);
                P.preference.setFeatureRollout(featureRollout);
                P.app.featureRollout.q = featureRollout;
                setState(() {});
              },
            ),
          ),
          // if (Platform.isWindows || Platform.isLinux)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 0),
            leading: const Text('Albatross', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            trailing: Switch(
              value: P.rwkv.enableAlbatross.q,
              onChanged: (v) async {
                P.rwkv.enableAlbatross.q = v;
                setState(() {});
              },
            ),
          ),
          // if (Platform.isWindows || Platform.isLinux)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 0),
            leading: const Text('Albatross Host', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            title: TextField(
              keyboardType: TextInputType.url,
              controller: _controllerHost,
            ),
          ),
        ],
      ),
    );
  }
}
