// Flutter imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:zone/model/file_download_source.dart';

void main() {
  group('FileDownloadSource.resolveUrl', () {
    test('passes through local HTTP URLs for Debug model serving', () {
      const raw = 'http://127.0.0.1:8765/rwkv7-g1i-1.5b.gguf';

      expect(FileDownloadSource.huggingface.resolveUrl(raw), raw);
      expect(FileDownloadSource.modelscope.resolveUrl(raw), raw);
    });

    test('keeps source-specific handling for repository-relative paths', () {
      const raw = 'mollysama/rwkv-mobile-models/resolve/main/gguf/model.gguf';

      expect(FileDownloadSource.huggingface.resolveUrl(raw), 'https://huggingface.co/$raw');
      expect(
        FileDownloadSource.modelscope.resolveUrl(raw),
        'https://modelscope.cn/models/RWKV/rwkv-mobile-models/resolve/master/gguf/model.gguf',
      );
    });

    test('maps formal weights between Hugging Face and ModelScope', () {
      const raw = 'HaloWang/rwkv-weights/resolve/main/artifacts/rwkv7/chat/1.5b/model.gguf';

      expect(FileDownloadSource.huggingface.resolveUrl(raw), 'https://huggingface.co/$raw');
      expect(FileDownloadSource.hfmirror.resolveUrl(raw), 'https://hf-mirror.com/$raw?download=true');
      expect(FileDownloadSource.aifasthub.resolveUrl(raw), 'https://aifasthub.com/$raw?download=true');
      expect(
        FileDownloadSource.modelscope.resolveUrl(raw),
        'https://modelscope.cn/models/HaloWang1991/rwkv-weights/resolve/master/artifacts/rwkv7/chat/1.5b/model.gguf',
      );
    });
  });
}
