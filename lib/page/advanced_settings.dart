import 'package:flutter/material.dart';
import 'package:halo/halo.dart';

class PageAdvancedSettings extends StatelessWidget {
  const PageAdvancedSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Advanced Settings'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.grey.shade100,
              child: const Text('Prompt 模板'),
            ),
            InkWell(
              onTap: () {
                //
              },
              child: item(
                '联网搜索模板',
                SizedBox(
                  height: 56,
                  width: 18,
                  child: Icon(Icons.arrow_forward_ios, size: 18),
                ),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                //
              },
              child: item(
                '知识库搜素模板',
                SizedBox(
                  height: 56,
                  width: 18,
                  child: Icon(Icons.arrow_forward_ios, size: 18),
                ),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                //
              },
              child: item(
                '新对话模板',
                SizedBox(
                  height: 56,
                  width: 18,
                  child: Icon(Icons.arrow_forward_ios, size: 18),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.grey.shade100,
              child: const Text('知识库'),
            ),
            item(
              "知识库搜索结果数量",
              DropdownMenu(
                initialSelection: 10,
                dropdownMenuEntries: [
                  DropdownMenuEntry(value: 3, label: '3'),
                  DropdownMenuEntry(value: 5, label: '5'),
                  DropdownMenuEntry(value: 10, label: '10'),
                  DropdownMenuEntry(value: 20, label: '20'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            item(
              "文本切割长度范围",
              DropdownMenu(
                initialSelection: 0,
                enableFilter: false,
                dropdownMenuEntries: [
                  DropdownMenuEntry(value: 0, label: '30-100'),
                  DropdownMenuEntry(value: 1, label: '30-150'),
                  DropdownMenuEntry(value: 2, label: '50-150'),
                  DropdownMenuEntry(value: 3, label: '100-200'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () {},
              child: item(
                "切割字符",
                Row(
                  children: [
                    Text('，。？！\\n'),
                    const SizedBox(width: 12, height: 56),
                    Icon(Icons.arrow_forward_ios, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget item(String title, Widget child) {
    return Row(
      children: [
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        child,
        const SizedBox(width: 16),
      ],
    );
  }
}
