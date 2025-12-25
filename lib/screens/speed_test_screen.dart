import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SpeedTestScreen extends StatefulWidget {
  const SpeedTestScreen({super.key});

  @override
  State<SpeedTestScreen> createState() => _SpeedTestScreenState();
}

class _SpeedTestScreenState extends State<SpeedTestScreen> {
  bool _isTesting = false;
  double _speedMbps = 0.0;
  double _progress = 0.0;
  String _status = 'Hız testi için başla butonuna basın.';
  final String _testUrl =
      'https://speed.cloudflare.com/__down?bytes=10000000'; // 10 MB

  Future<void> _startSpeedTest() async {
    setState(() {
      _isTesting = true;
      _speedMbps = 0.0;
      _progress = 0.0;
      _status = 'Sunucuyla bağlantı kuruluyor...';
    });

    final stopwatch = Stopwatch()..start();
    final client = http.Client();
    int totalBytes = 0;

    try {
      final request = http.Request('GET', Uri.parse(_testUrl));
      final response = await client.send(request);
      final contentLength = response.contentLength ?? 10000000;

      response.stream.listen(
        (List<int> chunk) {
          totalBytes += chunk.length;
          final durationInSeconds = stopwatch.elapsedMilliseconds / 1000.0;

          if (durationInSeconds > 0) {
            // bits = bytes * 8
            // Mbps = (bits / 1,000,000) / seconds
            final bits = totalBytes * 8;
            final mbps = (bits / 1000000) / durationInSeconds;

            if (mounted) {
              setState(() {
                _speedMbps = mbps;
                _progress = totalBytes / contentLength;
                _status = 'İndiriliyor: ${mbps.toStringAsFixed(1)} Mbps';
              });
            }
          }
        },
        onDone: () {
          stopwatch.stop();
          if (mounted) {
            setState(() {
              _isTesting = false;
              _progress = 1.0;
              _status = 'Test Tamamlandı!';
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isTesting = false;
              _status = 'Hata: $error';
            });
          }
        },
        cancelOnError: true,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTesting = false;
          _status = 'Bağlantı hatası: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İnternet Hız Testi'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value:
                        _isTesting ? _progress : (_progress == 1.0 ? 1.0 : 0.0),
                    strokeWidth: 15,
                    backgroundColor: Colors.grey[800],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getConnectionColor(_speedMbps),
                    ),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      _speedMbps.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Mbps',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 48),
            Text(
              _status,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            if (!_isTesting)
              ElevatedButton.icon(
                onPressed: _startSpeedTest,
                icon: const Icon(Icons.speed),
                label: const Text('Testi Başlat'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getConnectionColor(double speed) {
    if (speed < 10) return Colors.red;
    if (speed < 30) return Colors.orange;
    if (speed < 50) return Colors.yellow;
    return Colors.green;
  }
}
