part of '../benchmark.dart';

const double _benchmarkPrefillAxisTickStep = 400;

class _BenchmarkResultsCard extends ConsumerStatefulWidget {
  final List<BenchmarkRunResult> results;

  const _BenchmarkResultsCard({required this.results});

  @override
  ConsumerState<_BenchmarkResultsCard> createState() => _BenchmarkResultsCardState();
}

class _BenchmarkResultsCardState extends ConsumerState<_BenchmarkResultsCard> {
  int? _hoveredBatchSize;

  void _setHoveredBatchSize(int? value) {
    if (_hoveredBatchSize == value) return;
    setState(() {
      _hoveredBatchSize = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.results.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final s = S.of(context);
    final qb = ref.watch(P.app.qb);
    final appTheme = ref.watch(P.app.theme);
    final sorted = [...widget.results]..sort((a, b) => a.batchSize.compareTo(b.batchSize));
    final hoveredBatchSize = sorted.any((result) => result.batchSize == _hoveredBatchSize) ? _hoveredBatchSize : null;
    final bestDecode = sorted.map((e) => e.decodeSpeed).reduce(max);
    final bestDecodePerBatch = sorted.map((e) => e.decodeSpeedPerBatch).reduce(max);
    final bestBw = sorted.map((e) => e.bw).reduce(max);
    final bestFlops = sorted.map((e) => e.flops).reduce(max);
    final totalDecodeColor = qb.q(.74);
    const decodePerBatchColor = Color(0xFF1F9D8A);
    const prefillColor = Color(0xFFDE6A2E);

    return Material(
      color: appTheme.settingItem,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: qb.q(.14), width: .5),
      ),
      child: Padding(
        padding: const .symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart, size: 18, color: qb.q(.78)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.test_result,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _BenchmarkChartLegend(
              totalDecodeLabel: s.benchmark_total_decode,
              decodePerBatchLabel: s.benchmark_decode_per_batch,
              prefillLabel: s.prefill,
              totalDecodeColor: totalDecodeColor,
              decodePerBatchColor: decodePerBatchColor,
              prefillColor: prefillColor,
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 220,
              child: _BenchmarkResultChart(
                results: sorted,
                totalDecodeColor: totalDecodeColor,
                decodePerBatchColor: decodePerBatchColor,
                prefillColor: prefillColor,
                hoverBandColor: qb.q(.08),
                tooltipBackgroundColor: qb.q(.9),
                tooltipTextColor: appTheme.settingBg,
                gridColor: qb.q(.12),
                labelColor: qb.q(.62),
                labelStyle: theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12),
                hoveredBatchSize: hoveredBatchSize,
                hoveredBatchLabel: hoveredBatchSize == null ? null : s.benchmark_batch(hoveredBatchSize),
                totalDecodeLabel: s.benchmark_total_decode,
                decodePerBatchLabel: s.benchmark_decode_per_batch,
                prefillLabel: s.prefill,
                onHoverBatchSizeChanged: _setHoveredBatchSize,
              ),
            ),
            const SizedBox(height: 12),
            _BenchmarkResultRows(
              results: sorted,
              hoveredBatchSize: hoveredBatchSize,
              onHoverBatchSizeChanged: _setHoveredBatchSize,
            ),
            Container(
              margin: const .symmetric(vertical: 10),
              decoration: BoxDecoration(color: qb.q(.12)),
              height: .5,
            ),
            _InlineInfoRow(label: s.benchmark_best_decode, value: "${bestDecode.toStringAsFixed(2)} t/s"),
            const SizedBox(height: 4),
            _InlineInfoRow(label: s.benchmark_best_decode_per_batch, value: "${bestDecodePerBatch.toStringAsFixed(2)} t/s"),
            const SizedBox(height: 4),
            _InlineInfoRow(label: s.benchmark_best_bw, value: "${bestBw.toStringAsFixed(2)} GB/s"),
            const SizedBox(height: 4),
            _InlineInfoRow(label: s.benchmark_best_flops, value: "${bestFlops.toStringAsFixed(2)} T/s"),
          ],
        ),
      ),
    );
  }
}

class _BenchmarkChartLegend extends StatelessWidget {
  final String totalDecodeLabel;
  final String decodePerBatchLabel;
  final String prefillLabel;
  final Color totalDecodeColor;
  final Color decodePerBatchColor;
  final Color prefillColor;

  const _BenchmarkChartLegend({
    required this.totalDecodeLabel,
    required this.decodePerBatchLabel,
    required this.prefillLabel,
    required this.totalDecodeColor,
    required this.decodePerBatchColor,
    required this.prefillColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children: [
        _LegendItem(label: totalDecodeLabel, color: totalDecodeColor, style: theme.textTheme.bodySmall),
        _LegendItem(label: decodePerBatchLabel, color: decodePerBatchColor, style: theme.textTheme.bodySmall),
        _LegendItem(label: prefillLabel, color: prefillColor, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final TextStyle? style;

  const _LegendItem({
    required this.label,
    required this.color,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: const SizedBox.square(dimension: 8),
        ),
        const SizedBox(width: 6),
        Text(label, style: style),
      ],
    );
  }
}

class _BenchmarkResultRows extends ConsumerWidget {
  final List<BenchmarkRunResult> results;
  final int? hoveredBatchSize;
  final ValueChanged<int?> onHoverBatchSizeChanged;

  const _BenchmarkResultRows({
    required this.results,
    required this.hoveredBatchSize,
    required this.onHoverBatchSizeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final qb = ref.watch(P.app.qb);

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        for (final result in results)
          MouseRegion(
            onEnter: (_) => onHoverBatchSizeChanged(result.batchSize),
            onExit: (_) => onHoverBatchSizeChanged(null),
            child: Builder(
              builder: (context) {
                final hovered = result.batchSize == hoveredBatchSize;
                final batchText = s.benchmark_batch_result(result.batchSize);
                final speedLineText = s.benchmark_result_speed_line(
                  result.prefillSpeed.toStringAsFixed(2),
                  result.decodeSpeed.toStringAsFixed(2),
                );
                final perBatchText = "${s.benchmark_decode_per_batch}: ${result.decodeSpeedPerBatch.toStringAsFixed(2)} t/s";

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOut,
                  padding: const .symmetric(horizontal: 8, vertical: 6),
                  margin: const .symmetric(vertical: 1),
                  decoration: BoxDecoration(
                    color: hovered ? qb.q(.08) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: hovered ? qb.q(.22) : Colors.transparent, width: .5),
                  ),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      Text(
                        batchText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: hovered ? qb : null,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        speedLineText,
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        perBatchText,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _BenchmarkResultChart extends StatelessWidget {
  final List<BenchmarkRunResult> results;
  final Color totalDecodeColor;
  final Color decodePerBatchColor;
  final Color prefillColor;
  final Color hoverBandColor;
  final Color tooltipBackgroundColor;
  final Color tooltipTextColor;
  final Color gridColor;
  final Color labelColor;
  final TextStyle labelStyle;
  final int? hoveredBatchSize;
  final String? hoveredBatchLabel;
  final String totalDecodeLabel;
  final String decodePerBatchLabel;
  final String prefillLabel;
  final ValueChanged<int?> onHoverBatchSizeChanged;

  const _BenchmarkResultChart({
    required this.results,
    required this.totalDecodeColor,
    required this.decodePerBatchColor,
    required this.prefillColor,
    required this.hoverBandColor,
    required this.tooltipBackgroundColor,
    required this.tooltipTextColor,
    required this.gridColor,
    required this.labelColor,
    required this.labelStyle,
    required this.hoveredBatchSize,
    required this.hoveredBatchLabel,
    required this.totalDecodeLabel,
    required this.decodePerBatchLabel,
    required this.prefillLabel,
    required this.onHoverBatchSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final chartSize = constraints.biggest;
        return MouseRegion(
          cursor: SystemMouseCursors.precise,
          onHover: (event) =>
              onHoverBatchSizeChanged(_batchSizeAtPosition(results: results, size: chartSize, position: event.localPosition)),
          onExit: (_) => onHoverBatchSizeChanged(null),
          child: CustomPaint(
            painter: _BenchmarkResultChartPainter(
              results: results,
              totalDecodeColor: totalDecodeColor,
              decodePerBatchColor: decodePerBatchColor,
              prefillColor: prefillColor,
              hoverBandColor: hoverBandColor,
              tooltipBackgroundColor: tooltipBackgroundColor,
              tooltipTextColor: tooltipTextColor,
              gridColor: gridColor,
              labelColor: labelColor,
              labelStyle: labelStyle,
              hoveredBatchSize: hoveredBatchSize,
              hoveredBatchLabel: hoveredBatchLabel,
              totalDecodeLabel: totalDecodeLabel,
              decodePerBatchLabel: decodePerBatchLabel,
              prefillLabel: prefillLabel,
            ),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }

  static Rect _chartRectFor(Size size) {
    return Rect.fromLTWH(
      46,
      10,
      max(0, size.width - 104),
      max(0, size.height - 42),
    );
  }

  static int? _batchSizeAtPosition({
    required List<BenchmarkRunResult> results,
    required Size size,
    required Offset position,
  }) {
    if (results.isEmpty || size.width <= 0 || size.height <= 0) return null;
    final chartRect = _chartRectFor(size);
    if (chartRect.width <= 0 || chartRect.height <= 0) return null;
    if (position.dx < chartRect.left || position.dx > chartRect.right) return null;
    if (position.dy < chartRect.top - 10 || position.dy > chartRect.bottom + 30) return null;

    final slotWidth = chartRect.width / results.length;
    final index = ((position.dx - chartRect.left) / slotWidth).floor().clamp(0, results.length - 1).toInt();
    return results[index].batchSize;
  }
}

class _BenchmarkResultChartPainter extends CustomPainter {
  final List<BenchmarkRunResult> results;
  final Color totalDecodeColor;
  final Color decodePerBatchColor;
  final Color prefillColor;
  final Color hoverBandColor;
  final Color tooltipBackgroundColor;
  final Color tooltipTextColor;
  final Color gridColor;
  final Color labelColor;
  final TextStyle labelStyle;
  final int? hoveredBatchSize;
  final String? hoveredBatchLabel;
  final String totalDecodeLabel;
  final String decodePerBatchLabel;
  final String prefillLabel;

  const _BenchmarkResultChartPainter({
    required this.results,
    required this.totalDecodeColor,
    required this.decodePerBatchColor,
    required this.prefillColor,
    required this.hoverBandColor,
    required this.tooltipBackgroundColor,
    required this.tooltipTextColor,
    required this.gridColor,
    required this.labelColor,
    required this.labelStyle,
    required this.hoveredBatchSize,
    required this.hoveredBatchLabel,
    required this.totalDecodeLabel,
    required this.decodePerBatchLabel,
    required this.prefillLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (results.isEmpty || size.width <= 0 || size.height <= 0) return;

    final chartRect = _BenchmarkResultChart._chartRectFor(size);
    if (chartRect.width <= 0 || chartRect.height <= 0) return;

    BenchmarkRunResult? hoveredResult;
    for (final result in results) {
      if (result.batchSize == hoveredBatchSize) {
        hoveredResult = result;
        break;
      }
    }

    final decodeAxisMax = _niceAxisMax(
      results.fold<double>(0, (value, result) {
        return max(value, max(result.decodeSpeed, result.decodeSpeedPerBatch));
      }),
    );
    final prefillAxisMax = _prefillAxisMax(
      results.fold<double>(0, (value, result) => max(value, result.prefillSpeed)),
    );
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = labelColor.withValues(alpha: .28)
      ..strokeWidth = 1;
    final barPaint = Paint()..isAntiAlias = true;
    final hoverBandPaint = Paint()
      ..color = hoverBandColor
      ..isAntiAlias = true;
    final hoverGuidePaint = Paint()
      ..color = tooltipBackgroundColor.withValues(alpha: .24)
      ..strokeWidth = 1;
    final decodePerBatchLinePaint = Paint()
      ..color = decodePerBatchColor
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final prefillLinePaint = Paint()
      ..color = prefillColor
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final decodePerBatchDotPaint = Paint()
      ..color = decodePerBatchColor
      ..isAntiAlias = true;
    final prefillDotPaint = Paint()
      ..color = prefillColor
      ..isAntiAlias = true;

    for (final step in Iterable<int>.generate(5)) {
      final value = decodeAxisMax * step / 4;
      final y = chartRect.bottom - chartRect.height * value / decodeAxisMax;
      canvas.drawLine(Offset(chartRect.left, y), Offset(chartRect.right, y), step == 0 ? axisPaint : gridPaint);
      _paintChartText(
        canvas: canvas,
        text: _formatChartValue(value),
        offset: Offset(0, y - 7),
        maxWidth: 40,
        style: labelStyle.copyWith(color: labelColor, fontSize: 11),
        textAlign: TextAlign.right,
      );
    }

    for (double value = 0; value <= prefillAxisMax + .001; value += _benchmarkPrefillAxisTickStep) {
      final y = chartRect.bottom - chartRect.height * value / prefillAxisMax;
      canvas.drawLine(Offset(chartRect.right, y), Offset(chartRect.right + 4, y), axisPaint);
      _paintChartText(
        canvas: canvas,
        text: value.toStringAsFixed(0),
        offset: Offset(chartRect.right + 8, y - 7),
        maxWidth: 46,
        style: labelStyle.copyWith(color: prefillColor.withValues(alpha: .9), fontSize: 11),
      );
    }

    final slotWidth = chartRect.width / results.length;
    final barWidth = max(4, min(20, slotWidth * .48)).toDouble();
    final decodePerBatchPath = Path();
    final prefillPath = Path();

    for (final entry in results.indexed) {
      final i = entry.$1;
      final result = entry.$2;
      final centerX = chartRect.left + slotWidth * i + slotWidth / 2;
      final hovered = hoveredResult?.batchSize == result.batchSize;
      if (hovered) {
        final hoverRect = Rect.fromLTWH(centerX - slotWidth / 2 + 2, chartRect.top, max(0, slotWidth - 4), chartRect.height);
        canvas.drawRRect(RRect.fromRectAndRadius(hoverRect, const Radius.circular(6)), hoverBandPaint);
        canvas.drawLine(Offset(centerX, chartRect.top), Offset(centerX, chartRect.bottom), hoverGuidePaint);
      }

      final barHeight = chartRect.height * (result.decodeSpeed / decodeAxisMax).clamp(0, 1);
      final barRect = Rect.fromLTWH(
        centerX - barWidth / 2,
        chartRect.bottom - barHeight,
        barWidth,
        barHeight,
      );
      if (barHeight > 0) {
        barPaint.color = hoveredBatchSize == null || hovered ? totalDecodeColor : totalDecodeColor.withValues(alpha: .38);
        canvas.drawRRect(
          RRect.fromLTRBAndCorners(
            barRect.left,
            barRect.top,
            barRect.right,
            barRect.bottom,
            topLeft: const Radius.circular(3),
            topRight: const Radius.circular(3),
          ),
          barPaint,
        );
      }

      final decodePerBatchY = chartRect.bottom - chartRect.height * (result.decodeSpeedPerBatch / decodeAxisMax).clamp(0, 1);
      final prefillY = chartRect.bottom - chartRect.height * (result.prefillSpeed / prefillAxisMax).clamp(0, 1);
      final decodePerBatchPoint = Offset(centerX, decodePerBatchY);
      final prefillPoint = Offset(centerX, prefillY);
      if (i == 0) {
        decodePerBatchPath.moveTo(decodePerBatchPoint.dx, decodePerBatchPoint.dy);
        prefillPath.moveTo(prefillPoint.dx, prefillPoint.dy);
      } else {
        decodePerBatchPath.lineTo(decodePerBatchPoint.dx, decodePerBatchPoint.dy);
        prefillPath.lineTo(prefillPoint.dx, prefillPoint.dy);
      }
    }

    canvas.drawPath(prefillPath, prefillLinePaint);
    canvas.drawPath(decodePerBatchPath, decodePerBatchLinePaint);

    final maxLabels = max(2, (chartRect.width / 36).floor());
    final labelStride = max(1, (results.length / maxLabels).ceil());
    for (final entry in results.indexed) {
      final i = entry.$1;
      final result = entry.$2;
      final centerX = chartRect.left + slotWidth * i + slotWidth / 2;
      final decodePerBatchY = chartRect.bottom - chartRect.height * (result.decodeSpeedPerBatch / decodeAxisMax).clamp(0, 1);
      final prefillY = chartRect.bottom - chartRect.height * (result.prefillSpeed / prefillAxisMax).clamp(0, 1);
      final hovered = hoveredResult?.batchSize == result.batchSize;
      decodePerBatchDotPaint.color = hoveredBatchSize == null || hovered ? decodePerBatchColor : decodePerBatchColor.withValues(alpha: .42);
      prefillDotPaint.color = hoveredBatchSize == null || hovered ? prefillColor : prefillColor.withValues(alpha: .42);
      canvas.drawCircle(Offset(centerX, decodePerBatchY), hovered ? 4.6 : 3.2, decodePerBatchDotPaint);
      canvas.drawCircle(Offset(centerX, prefillY), hovered ? 4.6 : 3.2, prefillDotPaint);

      if (i == 0 || i == results.length - 1 || i % labelStride == 0) {
        _paintChartText(
          canvas: canvas,
          text: result.batchSize.toString(),
          offset: Offset(centerX - 18, chartRect.bottom + 8),
          maxWidth: 36,
          style: labelStyle.copyWith(color: labelColor, fontSize: 11),
          textAlign: TextAlign.center,
        );
      }
    }

    if (hoveredResult != null && hoveredBatchLabel != null) {
      final hoveredIndex = results.indexWhere((result) => result.batchSize == hoveredResult!.batchSize);
      final centerX = chartRect.left + slotWidth * hoveredIndex + slotWidth / 2;
      _paintTooltip(
        canvas: canvas,
        chartRect: chartRect,
        centerX: centerX,
        maxWidth: min(260, max(140, size.width - 24)),
        lines: [
          hoveredBatchLabel!,
          "$totalDecodeLabel: ${hoveredResult.decodeSpeed.toStringAsFixed(2)} t/s",
          "$decodePerBatchLabel: ${hoveredResult.decodeSpeedPerBatch.toStringAsFixed(2)} t/s",
          "$prefillLabel: ${hoveredResult.prefillSpeed.toStringAsFixed(2)} t/s",
        ],
      );
    }
  }

  double _niceAxisMax(double raw) {
    if (raw <= 0) return 1;
    final magnitude = pow(10, (log(raw) / ln10).floor()).toDouble();
    final normalized = raw / magnitude;
    final niceNormalized = switch (normalized) {
      <= 2 => 2,
      <= 5 => 5,
      _ => 10,
    };
    return niceNormalized * magnitude;
  }

  double _prefillAxisMax(double raw) {
    if (raw <= 0) return _benchmarkPrefillAxisTickStep;
    return max(_benchmarkPrefillAxisTickStep, (raw / _benchmarkPrefillAxisTickStep).ceil() * _benchmarkPrefillAxisTickStep);
  }

  String _formatChartValue(double value) {
    if (value >= 100) return value.toStringAsFixed(0);
    if (value >= 10) return value.toStringAsFixed(1);
    return value.toStringAsFixed(2);
  }

  void _paintChartText({
    required Canvas canvas,
    required String text,
    required Offset offset,
    required double maxWidth,
    required TextStyle style,
    TextAlign textAlign = TextAlign.left,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(minWidth: maxWidth, maxWidth: maxWidth);
    painter.paint(canvas, offset);
  }

  void _paintTooltip({
    required Canvas canvas,
    required Rect chartRect,
    required double centerX,
    required double maxWidth,
    required List<String> lines,
  }) {
    final textStyle = labelStyle.copyWith(color: tooltipTextColor, fontSize: 11, height: 1.25);
    final titleStyle = textStyle.copyWith(fontWeight: FontWeight.w600);
    final spans = <InlineSpan>[];
    for (final entry in lines.indexed) {
      final i = entry.$1;
      final line = entry.$2;
      spans.add(TextSpan(text: line, style: i == 0 ? titleStyle : textStyle));
      if (i != lines.length - 1) spans.add(const TextSpan(text: '\n'));
    }

    final painter = TextPainter(
      text: TextSpan(children: spans),
      textDirection: TextDirection.ltr,
      maxLines: lines.length,
    )..layout(maxWidth: maxWidth - 18);

    final tooltipSize = Size(painter.width + 18, painter.height + 14);
    final maxLeft = max(chartRect.left, chartRect.right - tooltipSize.width);
    final left = (centerX - tooltipSize.width / 2).clamp(chartRect.left, maxLeft).toDouble();
    final top = chartRect.top + 8;
    final rect = Rect.fromLTWH(left, top, tooltipSize.width, tooltipSize.height);
    final backgroundPaint = Paint()
      ..color = tooltipBackgroundColor
      ..isAntiAlias = true;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(7)), backgroundPaint);
    painter.paint(canvas, Offset(rect.left + 9, rect.top + 7));
  }

  @override
  bool shouldRepaint(covariant _BenchmarkResultChartPainter oldDelegate) {
    return oldDelegate.results != results ||
        oldDelegate.totalDecodeColor != totalDecodeColor ||
        oldDelegate.decodePerBatchColor != decodePerBatchColor ||
        oldDelegate.prefillColor != prefillColor ||
        oldDelegate.hoverBandColor != hoverBandColor ||
        oldDelegate.tooltipBackgroundColor != tooltipBackgroundColor ||
        oldDelegate.tooltipTextColor != tooltipTextColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.labelColor != labelColor ||
        oldDelegate.labelStyle != labelStyle ||
        oldDelegate.hoveredBatchSize != hoveredBatchSize ||
        oldDelegate.hoveredBatchLabel != hoveredBatchLabel ||
        oldDelegate.totalDecodeLabel != totalDecodeLabel ||
        oldDelegate.decodePerBatchLabel != decodePerBatchLabel ||
        oldDelegate.prefillLabel != prefillLabel;
  }
}
