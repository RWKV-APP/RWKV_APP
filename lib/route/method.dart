import 'package:zone/route/page_key.dart';
import 'package:go_router/go_router.dart';
import 'package:halo/halo.dart';
import 'package:zone/route/router.dart';

/// # 直接替换导航堆栈, 可能?
///
/// https://pub.dev/documentation/go_router/latest/topics/Navigation-topic.html
void go(PageKey pageKey, {Object? extra}) {
  final location = pageKey.path;
  final context = getContext();
  if (context == null) {
    qqw("Context is null when calling go");
    return;
  }
  context.go(location, extra: extra);
}

void replace(PageKey pageKey, {Object? extra}) {
  final location = pageKey.path;
  final context = getContext();
  if (context == null) {
    qqw("Context is null when calling replace");
    return;
  }
  context.replace(location, extra: extra);
}

/// # 可能有返回值的推
Future<T?> push<T extends Object?>(PageKey pageKey, {Object? extra}) async {
  final location = pageKey.path;
  final context = getContext();
  if (context == null) {
    qqw("Context is null when calling push");
    return null;
  }
  final r = await context.push<T>(location, extra: extra);
  return r;
}

/// # 返回, 传递返回值
FV pop<T extends Object?>([T? result]) async {
  final context = getContext();
  if (context == null) {
    qqw("Context is null when calling pop");
    return;
  }
  if (!context.canPop()) {
    return;
  }
  context.pop(result);
}
