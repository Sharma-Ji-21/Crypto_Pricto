class Metrics {
  final double rmse;
  final double mae;
  final double mda;

  Metrics({required this.rmse, required this.mae, required this.mda});

  factory Metrics.fromJson(Map<String, dynamic> json) {
    return Metrics(
      rmse: (json['rmse'] as num?)?.toDouble() ?? 0,
      mae: (json['mae'] as num?)?.toDouble() ?? 0,
      mda: (json['mda'] as num?)?.toDouble() ?? 0,
    );
  }
}

class PredictResult {
  final String crypto;
  final String targetDate;
  final String modelUsed;
  final double predictedPrice;
  final Metrics metrics;

  PredictResult({
    required this.crypto,
    required this.targetDate,
    required this.modelUsed,
    required this.predictedPrice,
    required this.metrics,
  });

  factory PredictResult.fromJson(Map<String, dynamic> json) {
    return PredictResult(
      crypto: json['crypto'] as String? ?? '',
      targetDate: json['target_date'] as String? ?? '',
      modelUsed: json['model_used'] as String? ?? 'LSTM',
      predictedPrice: (json['predicted_price'] as num?)?.toDouble() ?? 0,
      metrics: Metrics.fromJson(
        (json['metrics'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }
}

class HistoryItem {
  final int id;
  final String crypto;
  final String targetDate;
  final double predictedPrice;
  final String modelUsed;
  final double rmse;
  final double mae;
  final double mda;
  final String createdAt;

  HistoryItem({
    required this.id,
    required this.crypto,
    required this.targetDate,
    required this.predictedPrice,
    required this.modelUsed,
    required this.rmse,
    required this.mae,
    required this.mda,
    required this.createdAt,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'] as int? ?? 0,
      crypto: json['crypto'] as String? ?? '',
      targetDate: json['target_date'] as String? ?? '',
      predictedPrice: (json['predicted_price'] as num?)?.toDouble() ?? 0,
      modelUsed: json['model_used'] as String? ?? 'LSTM',
      rmse: (json['rmse'] as num?)?.toDouble() ?? 0,
      mae: (json['mae'] as num?)?.toDouble() ?? 0,
      mda: (json['mda'] as num?)?.toDouble() ?? 0,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class PredictionPoint {
  final String date;
  final double predictedPrice;

  PredictionPoint({required this.date, required this.predictedPrice});

  factory PredictionPoint.fromJson(Map<String, dynamic> json) {
    return PredictionPoint(
      date: json['date'] as String? ?? '',
      predictedPrice: (json['predicted_price'] as num?)?.toDouble() ?? 0,
    );
  }
}

class PredictionDetail {
  final int id;
  final String crypto;
  final int horizon;
  final String modelUsed;
  final Metrics metrics;
  final String createdAt;
  final List<PredictionPoint> predictions;

  PredictionDetail({
    required this.id,
    required this.crypto,
    required this.horizon,
    required this.modelUsed,
    required this.metrics,
    required this.createdAt,
    required this.predictions,
  });

  factory PredictionDetail.fromJson(Map<String, dynamic> json) {
    final rawPredictions = json['predictions'] as List<dynamic>? ?? [];
    return PredictionDetail(
      id: json['id'] as int? ?? 0,
      crypto: json['crypto'] as String? ?? '',
      horizon: json['horizon'] as int? ?? 0,
      modelUsed: json['model_used'] as String? ?? 'LSTM',
      metrics: Metrics.fromJson(
        (json['metrics'] as Map<String, dynamic>?) ?? {},
      ),
      createdAt: json['created_at'] as String? ?? '',
      predictions: rawPredictions
          .map((item) => PredictionPoint.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ErrorLogItem {
  final int id;
  final String path;
  final String method;
  final String message;
  final String createdAt;

  ErrorLogItem({
    required this.id,
    required this.path,
    required this.method,
    required this.message,
    required this.createdAt,
  });

  factory ErrorLogItem.fromJson(Map<String, dynamic> json) {
    return ErrorLogItem(
      id: json['id'] as int? ?? 0,
      path: json['path'] as String? ?? '',
      method: json['method'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
