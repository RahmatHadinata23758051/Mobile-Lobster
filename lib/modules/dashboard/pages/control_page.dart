import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class MobileControlPage extends StatefulWidget {
  const MobileControlPage({super.key});

  @override
  State<MobileControlPage> createState() => _MobileControlPageState();
}

class _MobileControlPageState extends State<MobileControlPage> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _feedingLogs = [];
  String _selectedSerial = 'DEMO-NODE-001';
  final _foodTypeController = TextEditingController(text: 'Pakan Pelet Super');
  final _amountController = TextEditingController(text: '1.5');

  @override
  void initState() {
    super.initState();
    _fetchControlData();
  }

  Future<void> _fetchControlData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await http.get(
        Uri.parse(ApiConstants.mobileFeedingSchedules),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${auth.token}',
        },
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['status'] == 'success') {
          setState(() {
            _feedingLogs = body['data']['recent_logs'] ?? [];
            _isLoading = false;
          });
          return;
        }
      }
      setState(() {
        _error = 'Gagal memuat data kontrol (${res.statusCode})';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error jaringan: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _submitSchedule() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final amount = double.tryParse(_amountController.text.trim()) ?? 1.0;

    try {
      final res = await http.post(
        Uri.parse(ApiConstants.mobileFeedingScheduleStore),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${auth.token}',
        },
        body: jsonEncode({
          'iot_node_serial_number': _selectedSerial,
          'food_type': _foodTypeController.text.trim(),
          'amount_kg': amount,
          'notes': 'Jadwal pakan via Mobile App',
        }),
      );

      if (mounted) {
        if (res.statusCode == 201 || res.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Jadwal pakan berhasil disimpan!')),
          );
          _fetchControlData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menyimpan jadwal pakan')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pengaturan & Otomatisasi Pakan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 4),
              const Text(
                'Kelola jadwal pemberian pakan otomatis dan trigger instan',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 20),

              // Form Tambah Jadwal Pakan
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!, style: const TextStyle(color: AppTheme.dangerRed, fontSize: 12)),
                ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderCard),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tambah Jadwal Pakan Baru',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.accentGreen),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSerial,
                      dropdownColor: AppTheme.cardBg,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Pilih IoT Node'),
                      items: const [
                        DropdownMenuItem(value: 'DEMO-NODE-001', child: Text('DEMO-NODE-001')),
                        DropdownMenuItem(value: 'LOBSTER-ESP32-001', child: Text('LOBSTER-ESP32-001')),
                        DropdownMenuItem(value: 'LOBSTER-ESP32-002', child: Text('LOBSTER-ESP32-002')),
                        DropdownMenuItem(value: 'LOBSTER-ESP32-003', child: Text('LOBSTER-ESP32-003')),
                      ],
                      onChanged: (v) => setState(() => _selectedSerial = v!),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _foodTypeController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Jenis Pakan'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Jumlah Dosis (Kg)'),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add_alarm, size: 18),
                        label: const Text('Simpan Jadwal Pakan'),
                        onPressed: _submitSchedule,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tabel Riwayat Log Pakan
              const Text(
                'Riwayat Log Pakan Terbaru',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),

              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan))
                  : _feedingLogs.isEmpty
                      ? const Text('Belum ada riwayat pakan', style: TextStyle(color: AppTheme.textMuted))
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _feedingLogs.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final log = _feedingLogs[idx];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.cardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.borderCard),
                              ),
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: AppTheme.primaryTeal,
                                    radius: 18,
                                    child: Icon(Icons.restaurant, size: 18, color: Colors.white),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          log['food_type'] ?? 'Pakan',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                                        ),
                                        Text(
                                          'Dosis: ${log['amount_kg']} kg • ${log['iot_node']?['serial_number'] ?? _selectedSerial}',
                                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    log['fed_at'] != null ? log['fed_at'].toString().substring(11, 16) : '--:--',
                                    style: const TextStyle(color: AppTheme.accentCyan, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ],
          ),
        ),
      ),
    );
  }
}
