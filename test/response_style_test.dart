// Flutter imports:
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/response_style.dart';

void main() {
  test(
    'English response style uses clear localized titles without changing its stored label',
    () async {
      final expectedTitles = <Locale, String>{
        const Locale.fromSubtags(languageCode: 'en'): 'English',
        const Locale.fromSubtags(languageCode: 'ja'): '英語回答',
        const Locale.fromSubtags(languageCode: 'ko'): '영어 답변',
        const Locale.fromSubtags(languageCode: 'ru'): 'Ответ EN',
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'):
            '英文回答',
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'):
            '英文回答',
      };

      for (final entry in expectedTitles.entries) {
        final s = await S.load(entry.key);
        expect(ResponseStyleRoute.en.title(s), entry.value);
      }

      expect(ResponseStyleRoute.en.label, '英');
    },
  );
}
