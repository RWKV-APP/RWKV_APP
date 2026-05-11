import 'package:flutter_test/flutter_test.dart';
import 'package:zone/config.dart';
import 'package:zone/func/get_batch_info.dart';

void main() {
  group('buildBatchContent', () {
    test('keeps the existing batch storage format', () {
      final content = buildBatchContent(<String>['first', 'second'], selectedBatch: 1);

      expect(content, 'first${Config.batchMarker}second${Config.batchMarker}1');
    });
  });

  group('normalizeBatchResponseBufferContent', () {
    test('keeps a normal response buffer unchanged', () {
      final normalized = normalizeBatchResponseBufferContent(
        responseBufferContent: <String>['first', 'second'],
        expectedBatchCount: 2,
      );

      expect(normalized, <String>['first', 'second']);
    });

    test('uses the latest complete snapshot from a repeated batch buffer', () {
      final normalized = normalizeBatchResponseBufferContent(
        responseBufferContent: <String>[
          'old 1',
          'old 2',
          '-1',
          'latest 1',
          'latest 2',
          '-1',
        ],
        expectedBatchCount: 2,
      );

      expect(normalized, <String>['latest 1', 'latest 2']);
    });

    test('clamps an oversized response without a complete snapshot', () {
      final normalized = normalizeBatchResponseBufferContent(
        responseBufferContent: <String>['a', 'b', 'c'],
        expectedBatchCount: 2,
      );

      expect(normalized, <String>['a', 'b']);
    });

    test('uses runtime max batch size when the expected count is invalid', () {
      final normalized = normalizeBatchResponseBufferContent(
        responseBufferContent: List<String>.generate(72, (index) => 'slot $index'),
        expectedBatchCount: 72,
        maxBatchSlotCount: 40,
      );

      expect(normalized.length, 40);
      expect(normalized.first, 'slot 0');
      expect(normalized.last, 'slot 39');
    });
  });
}
