import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zone/gen/l10n.dart' show S;
import 'package:zone/router/method.dart';
import 'package:zone/router/page_key.dart';
import 'package:zone/store/p.dart' show P, $Chat;
import 'package:zone/widgets/app_scaffold.dart';

class PageHome extends ConsumerWidget {
  const PageHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(P.app.version);

    return AppScaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 100),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/img/chat/rwkv.png',
                  height: 80,
                  width: 80,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              S.of(context).welcome_to_rwkv_chat,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "v$version",
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 100),
            buildRow([
              buildButton(
                title: S.of(context).chat,
                subtitle: S.of(context).chat_with_rwkv_model,
                onTap: () async {
                  P.chat.startNewChat();
                  push(PageKey.chat);
                },
                color: Colors.blueAccent,
                icon: FontAwesomeIcons.comments,
              ),
              buildButton(
                title: S.of(context).neko,
                subtitle: S.of(context).nyan_nyan,
                onTap: () {
                  push(PageKey.chat);
                },
                color: Colors.pinkAccent,
                icon: FontAwesomeIcons.cat,
              ),
            ]),
            const SizedBox(height: 16),
            buildRow([
              buildButton(
                title: S.of(context).completion_mode,
                subtitle: S.of(context).text_completion_mode,
                onTap: () {
                  push(PageKey.completion);
                },
                color: Colors.lightGreen,
                icon: FontAwesomeIcons.feather,
              ),
              SizedBox(),
            ]),
          ],
        ),
      ),
    );
  }

  Widget buildRow(List<Widget> children) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: children[0],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: children[1],
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget buildButton({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
    required IconData icon,
  }) {
    return Material(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: FaIcon(icon, color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}
