import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/font_info.dart';
import 'package:zone/store/p.dart';

class FontPickerBottomSheet extends ConsumerStatefulWidget {
  final String? currentFont;
  final bool isMonospace;
  final Function(String?) onFontSelected;
  final ScrollController scrollController;

  const FontPickerBottomSheet({
    super.key,
    required this.currentFont,
    required this.isMonospace,
    required this.onFontSelected,
    required this.scrollController,
  });

  static Future<void> show({
    required BuildContext context,
    required String? currentFont,
    required bool isMonospace,
    required Function(String?) onFontSelected,
  }) async {
    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: .85,
        maxChildSize: .9,
        minChildSize: .5,
        expand: false,
        snap: false,
        builder: (context, scrollController) => FontPickerBottomSheet(
          scrollController: scrollController,
          currentFont: currentFont,
          isMonospace: isMonospace,
          onFontSelected: onFontSelected,
        ),
      ),
    );
  }

  @override
  ConsumerState<FontPickerBottomSheet> createState() => _FontPickerBottomSheetState();
}

class _FontPickerBottomSheetState extends ConsumerState<FontPickerBottomSheet> {
  bool _isLoading = true;
  String? _selectedFont;

  // 字体列表
  final List<String> _fonts = [];

  // 分组后的字体
  final Map<String, List<String>> _grouped = {};

  // 排序后的字母键
  List<String> _keys = [];

  // 滚动控制器和section keys
  final Map<String, GlobalKey> _sectionKeys = {};

  @override
  void initState() {
    super.initState();
    // 如果 currentFont 是 null，表示使用默认，应该选择 'System'
    _selectedFont = widget.currentFont ?? 'System';
    _loadFonts();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadFonts() async {
    try {
      final fontInfos = await P.font.getSystemFontsWithInfo();
      setState(() {
        _separateFontsByType(fontInfos);
        _isLoading = false;
      });
    } catch (e) {
      // 如果失败，使用默认字体列表（通过名称推断）
      final defaultFonts = P.font.getDefaultFonts();
      final fontInfos = defaultFonts
          .map(
            (name) => FontInfo(
              name: name,
              isMonospace: P.font.inferMonospaceFromName(name),
            ),
          )
          .toList();
      setState(() {
        _separateFontsByType(fontInfos);
        _isLoading = false;
      });
    }
  }

  void _separateFontsByType(List<FontInfo> fontInfos) {
    _fonts.clear();

    // 根据 isMonospace 过滤字体
    for (final fontInfo in fontInfos) {
      if (fontInfo.isMonospace == widget.isMonospace) {
        _fonts.add(fontInfo.name);
      }
    }

    // 添加"默认"选项
    _fonts.insert(0, 'System');

    // 分组
    _groupFontsByFirstLetter(_fonts, _grouped, _sectionKeys);

    // 生成排序后的字母列表
    _keys = _getSortedKeys(_grouped);
  }

  void _groupFontsByFirstLetter(
    List<String> fonts,
    Map<String, List<String>> groupedFonts,
    Map<String, GlobalKey> sectionKeys,
  ) {
    groupedFonts.clear();
    sectionKeys.clear();

    // 按首字母分组
    for (final font in fonts) {
      final firstLetter = font.isNotEmpty ? font[0].toUpperCase() : '#';
      final letter = _isLetter(firstLetter) ? firstLetter : '#';

      if (!groupedFonts.containsKey(letter)) {
        groupedFonts[letter] = [];
        sectionKeys[letter] = GlobalKey();
      }
      groupedFonts[letter]!.add(font);
    }

    // 对每个字母组内的字体进行排序
    for (final key in groupedFonts.keys) {
      groupedFonts[key]!.sort();
    }
  }

  List<String> _getSortedKeys(Map<String, List<String>> groupedFonts) {
    return groupedFonts.keys.toList()..sort((a, b) {
      if (a == '#') return 1;
      if (b == '#') return -1;
      return a.compareTo(b);
    });
  }

  bool _isLetter(String char) {
    return char.length == 1 && char.codeUnitAt(0) >= 65 && char.codeUnitAt(0) <= 90;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final appTheme = ref.watch(P.app.theme);
    final qb = ref.watch(P.app.qb);
    final paddingBottom = ref.watch(P.app.quantizedIntPaddingBottom);

    return ClipRRect(
      borderRadius: const .only(
        topLeft: .circular(16),
        topRight: .circular(16),
      ),
      child: Container(
        color: appTheme.settingBg,
        child: Column(
          crossAxisAlignment: .start,
          children: [
            // 标题栏
            Row(
              mainAxisAlignment: .spaceBetween,
              children: [
                Padding(
                  padding: const .only(left: 16, top: 16),
                  child: Text(
                    widget.isMonospace ? s.monospace_font_setting : s.ui_font_setting,
                    style: const TS(s: 20, w: .w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            // 字体列表
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: Padding(
                    padding: .all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  controller: widget.scrollController,
                  padding: .only(bottom: paddingBottom),
                  itemCount: _getTotalItemCount(_grouped, _keys),
                  itemBuilder: (context, index) {
                    final item = _getItemAtIndex(_grouped, _keys, index);
                    if (item is _SectionHeader) {
                      return _buildSectionHeader(
                        item.letter,
                        _sectionKeys[item.letter]!,
                        qb,
                      );
                    } else if (item is _FontItem) {
                      return _buildFontItem(item.font, qb);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            // 确认和恢复默认按钮
            const SizedBox(height: 8),
            Padding(
              padding: const .symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        widget.onFontSelected(null);
                        Navigator.of(context).pop();
                      },
                      child: Text(s.restore_default),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // 如果选择的是 'System'，传递 null
                        final fontToSave = _selectedFont == 'System' ? null : _selectedFont;
                        widget.onFontSelected(fontToSave);
                        Navigator.of(context).pop();
                      },
                      child: Text(s.confirm),
                    ),
                  ),
                ],
              ),
            ),
            paddingBottom.h,
          ],
        ),
      ),
    );
  }

  int _getTotalItemCount(
    Map<String, List<String>> groupedFonts,
    List<String> sortedKeys,
  ) {
    int count = 0;
    for (final key in sortedKeys) {
      count += 1; // 字母标题
      count += groupedFonts[key]!.length; // 字体项
    }
    return count;
  }

  dynamic _getItemAtIndex(
    Map<String, List<String>> groupedFonts,
    List<String> sortedKeys,
    int index,
  ) {
    int currentIndex = 0;
    for (final key in sortedKeys) {
      if (currentIndex == index) {
        return _SectionHeader(key);
      }
      currentIndex++;

      final fonts = groupedFonts[key]!;
      for (final font in fonts) {
        if (currentIndex == index) {
          return _FontItem(font);
        }
        currentIndex++;
      }
    }
    return null;
  }

  Widget _buildSectionHeader(String letter, GlobalKey key, Color qb) {
    return Container(
      key: key,
      padding: const .symmetric(horizontal: 16, vertical: 8),
      color: qb.q(.1),
      child: Text(
        letter,
        style: TS(
          s: 14,
          w: .w600,
          c: qb.q(.8),
        ),
      ),
    );
  }

  Widget _buildFontItem(String font, Color qb) {
    final isSelected = _selectedFont == font;
    return _FontPreviewItem(
      font: font,
      isSelected: isSelected,
      qb: qb,
      onTap: () {
        setState(() {
          _selectedFont = font;
        });
      },
    );
  }
}

class _FontPreviewItem extends StatefulWidget {
  final String font;
  final bool isSelected;
  final Color qb;
  final VoidCallback onTap;

  const _FontPreviewItem({
    required this.font,
    required this.isSelected,
    required this.qb,
    required this.onTap,
  });

  @override
  State<_FontPreviewItem> createState() => _FontPreviewItemState();
}

class _FontPreviewItemState extends State<_FontPreviewItem> {
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadFont();
  }

  Future<void> _loadFont() async {
    if (widget.font == 'System') {
      if (mounted) {
        setState(() {
          _isLoaded = true;
        });
      }
      return;
    }

    try {
      await P.font.loadFontByName(widget.font);
      if (mounted) {
        setState(() {
          _isLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Failed to load font preview for ${widget.font}: $e');
      // If loading fails, we still show the item but maybe without the custom font style
      if (mounted) {
        setState(() {
          _isLoaded = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 当选择"默认字体"（System）时，只显示"默认"，不显示系统字体名称
    // 因为"默认字体"指的是 Flutter 的默认字体（Roboto），而不是系统的默认字体
    final displayName = widget.font == 'System' ? S.of(context).default_font : widget.font;

    // 当选择"默认字体"（System）时，不设置 fontFamily，让 Flutter 使用其自带的默认字体（Roboto）
    final fontFamily = (widget.font == 'System' || !_isLoaded) ? null : widget.font;

    return ListTile(
      title: Text(
        displayName,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: widget.isSelected ? .w600 : .normal,
        ),
      ),
      subtitle: Text(
        '示例文本 The quick brown fox',
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          color: widget.qb.q(.6),
        ),
      ),
      trailing: widget.isSelected ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
      selected: widget.isSelected,
      onTap: widget.onTap,
    );
  }
}

// 辅助类用于区分列表项类型
class _SectionHeader {
  final String letter;
  _SectionHeader(this.letter);
}

class _FontItem {
  final String font;
  _FontItem(this.font);
}
