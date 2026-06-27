Map<String, dynamic> castJsonMap(Object? object) {
  if (object is Map) {
    return object.map((k, v) => MapEntry(k.toString(), v));
  }
  throw "json_cast: target is not JSON:\n$object";
}

List<dynamic> castList(Object? object) {
  if (object is List) return object;
  throw "json_cast: target is not List:\n$object";
}

List<Map<dynamic, dynamic>> castMapList(Object? object) {
  final list = castList(object);
  final result = <Map<dynamic, dynamic>>[];
  for (final item in list) {
    if (item is! Map) {
      throw "json_cast: element in list is not Map";
    }
    result.add(item);
  }
  return result;
}

List<Map<String, dynamic>> castJsonList(Object? object) {
  final list = castMapList(object);
  final result = <Map<String, dynamic>>[];
  for (final item in list) {
    result.add(castJsonMap(item));
  }
  return result;
}
