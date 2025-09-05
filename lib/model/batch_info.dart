import 'package:equatable/equatable.dart';

// TODO: Use this class to optimize the performance of the batch message rendering @wangce
class BatchInfo extends Equatable {
  final List<String> batch;
  final bool isBatch;
  final int batchCount;
  final int? selectedBatch;

  const BatchInfo({
    required this.batch,
    required this.isBatch,
    required this.batchCount,
    required this.selectedBatch,
  });

  @override
  List<Object?> get props => [
    batch,
    isBatch,
    batchCount,
    selectedBatch,
  ];

  static const none = BatchInfo(
    batch: [],
    isBatch: false,
    batchCount: 0,
    selectedBatch: null,
  );
}
