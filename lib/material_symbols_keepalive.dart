import 'package:flutter/widgets.dart';

@pragma('vm:entry-point')
void keepUsedMaterialSymbols() {
  // Keep the Symbols glyphs used by the app in release font subsetting.
  final usedSymbols = <IconData>[
    const IconData(0xe05f, fontFamily: 'MaterialSymbolsOutlined', fontPackage: 'material_symbols_icons'),
    const IconData(0xe65f, fontFamily: 'MaterialSymbolsOutlined', fontPackage: 'material_symbols_icons'),
    const IconData(0xe5ca, fontFamily: 'MaterialSymbolsOutlined', fontPackage: 'material_symbols_icons'),
    const IconData(0xe14d, fontFamily: 'MaterialSymbolsOutlined', fontPackage: 'material_symbols_icons'),
    const IconData(0xe92e, fontFamily: 'MaterialSymbolsOutlined', fontPackage: 'material_symbols_icons'),
    const IconData(0xf097, fontFamily: 'MaterialSymbolsOutlined', fontPackage: 'material_symbols_icons'),
    const IconData(0xe5cf, fontFamily: 'MaterialSymbolsOutlined', fontPackage: 'material_symbols_icons'),
    const IconData(0xea5b, fontFamily: 'MaterialSymbolsOutlined', fontPackage: 'material_symbols_icons'),
    const IconData(0xe90f, fontFamily: 'MaterialSymbolsOutlined', fontPackage: 'material_symbols_icons'),
    const IconData(0xe5d3, fontFamily: 'MaterialSymbolsOutlined', fontPackage: 'material_symbols_icons'),
    const IconData(0xe5d5, fontFamily: 'MaterialSymbolsOutlined', fontPackage: 'material_symbols_icons'),
    const IconData(0xe163, fontFamily: 'MaterialSymbolsOutlined', fontPackage: 'material_symbols_icons'),
    const IconData(0xe80d, fontFamily: 'MaterialSymbolsRounded', fontPackage: 'material_symbols_icons'),
    const IconData(0xe047, fontFamily: 'MaterialSymbolsOutlined', fontPackage: 'material_symbols_icons'),
    const IconData(0xe2db, fontFamily: 'MaterialSymbolsOutlined', fontPackage: 'material_symbols_icons'),
  ];
  if (usedSymbols.isEmpty) {
    return;
  }
}
