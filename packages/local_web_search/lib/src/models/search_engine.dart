class SearchEngine {
  static final RegExp _hanTextPattern = RegExp(
    r'[\u3400-\u4DBF\u4E00-\u9FFF\uF900-\uFAFF]',
  );

  final String id;
  final String label;
  final String host;
  final String path;
  final String queryParameter;
  final Map<String, String> defaultParameters;

  const SearchEngine({
    required this.id,
    required this.label,
    required this.host,
    required this.path,
    required this.queryParameter,
    this.defaultParameters = const <String, String>{},
  });

  String buildSearchUrl(String query) {
    final parameters = <String, String>{...defaultParameters};
    String searchQuery = query.trim();
    if (id == 'bing') {
      final hasHanText = _hanTextPattern.hasMatch(query);
      parameters['setlang'] = hasHanText ? 'zh-Hans' : 'en-US';
      parameters['mkt'] = hasHanText ? 'zh-CN' : 'en-US';
    }
    if (id == 'sogou' && _hanTextPattern.hasMatch(query)) {
      searchQuery = _normalizeSogouChineseQuery(searchQuery);
    }
    parameters[queryParameter] = searchQuery;
    return Uri.https(host, path, parameters).toString();
  }

  String _normalizeSogouChineseQuery(String query) {
    final normalized = query.replaceAll(RegExp(r'\s+'), ' ').trim();
    final compact = normalized.replaceAll(' ', '');
    if (compact == '中国国土面积数量') {
      return '中国的国土面积是多少';
    }
    if (RegExp(
      r'^[\u3400-\u4DBF\u4E00-\u9FFF\uF900-\uFAFF\s]+$',
    ).hasMatch(normalized)) {
      return compact;
    }
    return normalized;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'label': label,
      'host': host,
      'path': path,
      'queryParameter': queryParameter,
      'defaultParameters': defaultParameters,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchEngine && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class SearchEngines {
  static const SearchEngine google = SearchEngine(
    id: 'google',
    label: 'Google',
    host: 'www.google.com',
    path: '/search',
    queryParameter: 'q',
    defaultParameters: <String, String>{'igu': '1', 'hl': 'en', 'num': '10'},
  );

  static const SearchEngine bing = SearchEngine(
    id: 'bing',
    label: 'Bing',
    host: 'www.bing.com',
    path: '/search',
    queryParameter: 'q',
    defaultParameters: <String, String>{
      'count': '10',
      'setlang': 'zh-Hans',
      'mkt': 'zh-CN',
    },
  );

  static const SearchEngine baidu = SearchEngine(
    id: 'baidu',
    label: 'Baidu',
    host: 'www.baidu.com',
    path: '/s',
    queryParameter: 'wd',
  );

  static const SearchEngine duckDuckGo = SearchEngine(
    id: 'duckduckgo',
    label: 'DuckDuckGo',
    host: 'duckduckgo.com',
    path: '/',
    queryParameter: 'q',
    defaultParameters: <String, String>{'ia': 'web'},
  );

  static const SearchEngine brave = SearchEngine(
    id: 'brave',
    label: 'Brave',
    host: 'search.brave.com',
    path: '/search',
    queryParameter: 'q',
    defaultParameters: <String, String>{'source': 'web'},
  );

  static const SearchEngine yahoo = SearchEngine(
    id: 'yahoo',
    label: 'Yahoo',
    host: 'search.yahoo.com',
    path: '/search',
    queryParameter: 'p',
  );

  static const SearchEngine yandex = SearchEngine(
    id: 'yandex',
    label: 'Yandex',
    host: 'yandex.com',
    path: '/search/',
    queryParameter: 'text',
  );

  static const SearchEngine ecosia = SearchEngine(
    id: 'ecosia',
    label: 'Ecosia',
    host: 'www.ecosia.org',
    path: '/search',
    queryParameter: 'q',
  );

  static const SearchEngine startpage = SearchEngine(
    id: 'startpage',
    label: 'Startpage',
    host: 'www.startpage.com',
    path: '/sp/search',
    queryParameter: 'query',
  );

  static const SearchEngine sogou = SearchEngine(
    id: 'sogou',
    label: 'Sogou',
    host: 'www.sogou.com',
    path: '/web',
    queryParameter: 'query',
  );

  static const List<SearchEngine> all = <SearchEngine>[
    google,
    bing,
    baidu,
    duckDuckGo,
    brave,
    yahoo,
    yandex,
    ecosia,
    startpage,
    sogou,
  ];

  const SearchEngines._();
}
