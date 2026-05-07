part of 'p.dart';

class _RWKVContext {
  late final currentWorldType = qs<WorldType?>(null);

  late final currentGroupInfo = qs<GroupInfo?>(null);

  late final isAlbatrossLoaded = qp<bool>((ref) {
    final currentModel = ref.watch(P.rwkvModel.latest);
    return currentModel?.tags.contains('albatross') ?? false;
  });

  late final inTTSTranslateOrSee = qp<bool>((ref) {
    final model = ref.watch(P.rwkvModel.latest);
    if (model == null) return false;
    final isTTS = model.isTTS;
    final isTranslate = model.tags.contains("translate");
    final isWorld = model.fileName.contains("modrwkv") || model.fileName.contains("rwkv-vl");
    return isTTS || isTranslate || isWorld;
  });
}
