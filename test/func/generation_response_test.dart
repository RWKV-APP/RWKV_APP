import 'package:flutter_test/flutter_test.dart';
import 'package:zone/func/generation_response.dart';

void main() {
  test('late completion responses cannot update or cancel a newer generation', () {
    const firstGeneration = 10;
    const finalBuffer = 12;
    const finalSpeed = 13;
    const nextGeneration = 14;
    expect(isCurrentGenerationResponse(finalBuffer, firstGeneration), isTrue);
    expect(isCurrentGenerationResponse(finalSpeed, firstGeneration), isTrue);
    expect(isCurrentGenerationResponse(finalBuffer, nextGeneration), isFalse);
    expect(isCurrentGenerationResponse(finalSpeed, nextGeneration), isFalse);
    expect(isCurrentGenerationResponse(15, nextGeneration), isTrue);
  });

  test('legacy anonymous responses retain their existing behavior', () {
    expect(isCurrentGenerationResponse(null, 14), isTrue);
    expect(isCurrentGenerationResponse(12, null), isTrue);
  });
}
