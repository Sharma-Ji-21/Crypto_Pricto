import 'package:flutter/material.dart';

import '../models/prediction_model.dart';
import '../services/api_service.dart';

class PredictionScreen extends StatefulWidget {
  final String selectedCrypto;

  const PredictionScreen({super.key, required this.selectedCrypto});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  final ApiService _apiService = ApiService();
  final DateTime _minDate = DateTime(2021, 7, 7);
  final DateTime _maxDate = DateTime(2021, 8, 5);

  DateTime? _selectedDate;
  bool _isLoading = false;
  PredictResult? _result;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? _minDate,
      firstDate: _minDate,
      lastDate: _maxDate,
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  bool _isValidDate(DateTime date) {
    final start = DateTime(_minDate.year, _minDate.month, _minDate.day);
    final selected = DateTime(date.year, date.month, date.day);
    final end = DateTime(_maxDate.year, _maxDate.month, _maxDate.day);
    return !selected.isBefore(start) && !selected.isAfter(end);
  }

  Future<void> _predict() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a target date.')),
      );
      return;
    }

    if (!_isValidDate(_selectedDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Date must be between 2021-07-07 and 2021-08-07.'),
        ),
      );
      return;
    }

    final formattedDate =
        '${_selectedDate!.year.toString().padLeft(4, '0')}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';

    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final result = await _apiService.getPrediction(
        crypto: widget.selectedCrypto,
        targetDate: formattedDate,
      );

      if (!mounted) return;
      setState(() {
        _result = result;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildResultCard(PredictResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insights),
                const SizedBox(width: 8),
                Text(
                  'Prediction Result',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Target Date: ${result.targetDate}'),
            const SizedBox(height: 8),
            Text(
              'Predicted Price: ${result.predictedPrice.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text('Model: ${result.modelUsed}'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text('RMSE ${result.metrics.rmse.toStringAsFixed(4)}'),
                ),
                Chip(
                  label: Text('MAE ${result.metrics.mae.toStringAsFixed(4)}'),
                ),
                Chip(
                  label: Text('MDA ${result.metrics.mda.toStringAsFixed(4)}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.selectedCrypto} Prediction')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Available date range: 2021-07-07 to 2021-08-07',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            OutlinedButton(
              onPressed: _pickDate,
              child: Text(
                _selectedDate == null
                    ? 'Select Target Date'
                    : 'Target Date: ${_selectedDate!.year.toString().padLeft(4, '0')}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : _predict,
              child: const Text('Predict'),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_result != null)
              _buildResultCard(_result!),
          ],
        ),
      ),
    );
  }
}
