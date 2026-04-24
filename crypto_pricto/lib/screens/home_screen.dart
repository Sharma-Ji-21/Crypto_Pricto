import 'package:flutter/material.dart';

import '../models/prediction_model.dart';
import '../services/api_service.dart';
import 'error_screen.dart';
import 'history_detail_screen.dart';
import 'prediction_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<HistoryItem>> _historyFuture;

  final List<Map<String, dynamic>> _cryptos = const [
    {
      'name': 'Bitcoin',
      'icon': Icons.currency_bitcoin,
      'color': Color(0xFFF7931A),
    },
    {'name': 'Ethereum', 'icon': Icons.bolt, 'color': Color(0xFF627EEA)},
    {'name': 'Dogecoin', 'icon': Icons.pets, 'color': Color(0xFFC2A633)},
  ];

  @override
  void initState() {
    super.initState();
    _historyFuture = _apiService.getHistory();
  }

  void _refreshHistory() {
    setState(() {
      _historyFuture = _apiService.getHistory();
    });
  }

  void _openPrediction(String crypto) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PredictionScreen(selectedCrypto: crypto),
      ),
    ).then((_) => _refreshHistory());
  }

  Widget _buildCryptoButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _cryptos
          .map(
            (crypto) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: (crypto['color'] as Color).withValues(
                    alpha: 0.18,
                  ),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _openPrediction(crypto['name'] as String),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(crypto['icon'] as IconData),
                    const SizedBox(width: 8),
                    Text(crypto['name'] as String),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildHistoryList(List<HistoryItem> history) {
    if (history.isEmpty) {
      return const Center(child: Text('No history found.'));
    }

    return ListView.builder(
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.2),
              child: const Icon(Icons.show_chart),
            ),
            title: Text('${item.crypto} - ${item.targetDate}'),
            subtitle: Text(
              'Predicted: ${item.predictedPrice.toStringAsFixed(2)}\n'
              'Model: ${item.modelUsed}',
            ),
            isThreeLine: false,
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HistoryDetailScreen(predictionId: item.id),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CriptoPricto')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              margin: const EdgeInsets.only(bottom: 14),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.auto_graph),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Crypto Forecast Dashboard',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Pick a coin, choose date, and predict quickly.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Text(
              'Select Crypto',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildCryptoButtons(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: _refreshHistory,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<HistoryItem>>(
                future: _historyFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Failed to load history: ${snapshot.error}'),
                    );
                  }

                  return _buildHistoryList(snapshot.data ?? []);
                },
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ErrorScreen()),
                );
              },
              child: const Text('View Error Logs'),
            ),
          ],
        ),
      ),
    );
  }
}
