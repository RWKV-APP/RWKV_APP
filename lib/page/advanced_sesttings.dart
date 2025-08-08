import 'package:flutter/material.dart';

class PageAdvancedSettings extends StatelessWidget {
  const PageAdvancedSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('高级设置'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buildGroupTitle('Prompt 模板'),
            item(
              title: '联网搜索模板',
              child: SizedBox(
                height: 56,
                width: 18,
                child: Icon(Icons.arrow_forward_ios, size: 18),
              ),
              onTap: () {},
            ),
            const SizedBox(height: 8),
            item(
              title: '思考模式模板',
              child: SizedBox(
                height: 56,
                width: 18,
                child: Icon(Icons.arrow_forward_ios, size: 18),
              ),
              onTap: () {},
            ),
            const SizedBox(height: 8),
            item(
              title: '新对话模板',
              child: SizedBox(
                height: 56,
                width: 18,
                child: Icon(Icons.arrow_forward_ios, size: 18),
              ),
              onTap: () {},
            ),
            const SizedBox(height: 16),
            buildGroupTitle('App 行为'),
            item(
              title: '启动时自动加载上次模型',
              child: SizedBox(
                height: 56,
                child: Switch(value: false, onChanged: (v) {}),
              ),
            ),
            const SizedBox(height: 8),
            item(
              title: '回车键发送消息',
              child: SizedBox(
                height: 56,
                child: Switch(value: false, onChanged: (v) {}),
              ),
            ),
            const SizedBox(height: 8),
            item(
              title: '启动时检查更新',
              child: SizedBox(
                height: 56,
                child: Switch(value: true, onChanged: (v) {}),
              ),
            ),
            const SizedBox(height: 8),
            item(
              title: '打开模型列表时自动更新',
              child: SizedBox(
                height: 56,
                child: Switch(value: true, onChanged: (v) {}),
              ),
            ),
            // const SizedBox(height: 16),
            // ...buildRagGroup(),
          ],
        ),
      ),
    );
  }

  Widget item({required String title, required Widget child, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
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
      ),
    );
  }

  Widget buildGroupTitle(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey.shade100,
      child: Text(title),
    );
  }

  List<Widget> buildRagGroup() {
    return [
      Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Colors.grey.shade100,
        child: const Text('知识库'),
      ),
      item(
        title: "知识库搜索结果数量",
        child: DropdownMenu(
          initialSelection: 10,
          dropdownMenuEntries: [
            DropdownMenuEntry(value: 3, label: '3'),
            DropdownMenuEntry(value: 5, label: '5'),
            DropdownMenuEntry(value: 10, label: '10'),
            DropdownMenuEntry(value: 20, label: '20'),
          ],
        ),
      ),
      const SizedBox(height: 12),
      item(
        title: "文本切割长度范围",
        child: DropdownMenu(
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
      const SizedBox(height: 12),
      item(
        title: "切割字符",
        child: Row(
          children: [
            Text('，。？！\\n'),
            const SizedBox(width: 12, height: 56),
            Icon(Icons.arrow_forward_ios, size: 18),
          ],
        ),
      ),
    ];
  }
}
