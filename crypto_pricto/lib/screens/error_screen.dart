import 'package:flutter/material.dart';

import '../models/prediction_model.dart';
import '../services/api_service.dart';

class ErrorScreen extends StatefulWidget {
  const ErrorScreen({super.key});

  @override
  State<ErrorScreen> createState() => _ErrorScreenState();
}

class _ErrorScreenState extends State<ErrorScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<ErrorLogItem>> _errorsFuture;

  @override
  void initState() {
    super.initState();
    _errorsFuture = _apiService.getErrors();
  }

  void _refreshErrors() {
    setState(() {
      _errorsFuture = _apiService.getErrors();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error Logs'),
        actions: [
          IconButton(
            onPressed: _refreshErrors,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<ErrorLogItem>>(
          future: _errorsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Failed to load errors: ${snapshot.error}'),
              );
            }

            final errors = snapshot.data ?? [];
            if (errors.isEmpty) {
              return const Center(child: Text('No errors found.'));
            }

            return ListView.builder(
              itemCount: errors.length,
              itemBuilder: (context, index) {
                final item = errors[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${item.method}  ${item.path}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text('Path: ${item.path}'),
                        const SizedBox(height: 4),
                        Text('Method: ${item.method}'),
                        const SizedBox(height: 4),
                        Text('Message: ${item.message}'),
                        const SizedBox(height: 4),
                        Text('Timestamp: ${item.createdAt}'),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
