import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zone/router/method.dart';
import 'package:zone/router/page_key.dart';
import 'package:zone/store/p.dart' show P, $Chat;
import 'package:zone/widgets/app_scaffold.dart';

class PageHome extends StatefulWidget {
  const PageHome({super.key});

  @override
  State<PageHome> createState() => _PageHomeState();
}

class _PageHomeState extends State<PageHome> {
  @override
  Widget build(BuildContext context) {
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
                  height: 100,
                  width: 100,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Welcome to RWKV",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 100),
            buildRow([
              buildButton(
                title: "Chat",
                subtitle: "Chat with various model",
                onTap: () async {
                  P.chat.startNewChat();
                  push(PageKey.chat);
                },
                color: Colors.blueAccent,
                icon: FontAwesomeIcons.comments,
              ),
              buildButton(
                title: "Neko",
                subtitle: "Nyan~~, Nyan~~",
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
                title: "Completion",
                subtitle: "Text completion mode",
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
