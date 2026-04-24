import 'package:flutter/material.dart';

import '../models/prediction_model.dart';
import '../services/api_service.dart';

class HistoryDetailScreen extends StatefulWidget {
  final int predictionId;

  const HistoryDetailScreen({super.key, required this.predictionId});

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  final ApiService _apiService = ApiService();
  late Future<PredictionDetail> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = _apiService.getPredictionDetail(widget.predictionId);
  }

  Widget _buildDetail(PredictionDetail detail) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.query_stats),
                      const SizedBox(width: 8),
                      Text(
                        'Prediction Summary',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Crypto: ${detail.crypto}'),
                  const SizedBox(height: 6),
                  Text('Horizon: ${detail.horizon}'),
                  const SizedBox(height: 6),
                  Text('Model: ${detail.modelUsed}'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        label: Text(
                          'RMSE ${detail.metrics.rmse.toStringAsFixed(4)}',
                        ),
                      ),
                      Chip(
                        label: Text(
                          'MAE ${detail.metrics.mae.toStringAsFixed(4)}',
                        ),
                      ),
                      Chip(
                        label: Text(
                          'MDA ${detail.metrics.mda.toStringAsFixed(4)}',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Predictions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: detail.predictions.length,
              itemBuilder: (context, index) {
                final item = detail.predictions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(item.date),
                    subtitle: Text(
                      'Predicted Price: ${item.predictedPrice.toStringAsFixed(2)}',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History Detail')),
      body: FutureBuilder<PredictionDetail>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load detail: ${snapshot.error}'),
            );
          }

          final detail = snapshot.data;
          if (detail == null) {
            return const Center(child: Text('No detail found.'));
          }

          return _buildDetail(detail);
        },
      ),
    );
  }
}
