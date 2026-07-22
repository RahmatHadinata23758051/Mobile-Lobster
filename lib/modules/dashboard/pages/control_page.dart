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
                'Pengaturan Pakan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
              const SizedBox(height: 16),

              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.badgeRedBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.dangerRed.withValues(alpha: 0.3)),
                  ),
                  child: Text(_error!, style: const TextStyle(color: AppTheme.dangerRed, fontSize: 12, fontWeight: FontWeight.w600)),
                ),

              // Form Card (Reference Screen 2)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderCard),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.alarm, color: AppTheme.primaryGreen, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Tambah Jadwal Pakan Baru',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Kelola jadwal pemberian pakan otomatis',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 16),

                    // Pilih Node Dropdown
                    const Text('Pilih Node Aktif', style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSerial,
                      dropdownColor: AppTheme.cardBg,
                      style: const TextStyle(color: AppTheme.textDark, fontSize: 14),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'DEMO-NODE-001', child: Text('DEMO-NODE-001')),
                        DropdownMenuItem(value: 'LOBSTER-ESP32-001', child: Text('LOBSTER-ESP32-001')),
                        DropdownMenuItem(value: 'LOBSTER-ESP32-002', child: Text('LOBSTER-ESP32-002')),
                      ],
                      onChanged: (v) => setState(() => _selectedSerial = v!),
                    ),
                    const SizedBox(height: 14),

                    // Jenis Pakan Input
                    const Text('Jenis Pakan', style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _foodTypeController,
                      style: const TextStyle(color: AppTheme.textDark, fontSize: 14),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Dosis Input
                    const Text('Jumlah Dosis (Kg)', style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppTheme.textDark, fontSize: 14),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.calendar_month_outlined, size: 18),
                        label: const Text('Simpan Jadwal Pakan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _submitSchedule,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Riwayat Log Pakan Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Riwayat Log Pakan Terbaru',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  InkWell(
                    onTap: () {},
                    child: const Text('Lihat Semua', style: TextStyle(fontSize: 12, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Log Items List (Reference Screen 2)
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
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
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.cardBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.borderCard),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.badgeGreenBg,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.calendar_today_outlined, size: 18, color: AppTheme.primaryGreen),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          log['food_type'] ?? 'Pakan Pelet Super',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 13),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${log['amount_kg']} Kg • ${log['iot_node']?['serial_number'] ?? _selectedSerial}',
                                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        log['fed_at'] != null ? log['fed_at'].toString().substring(11, 16) : '08:30',
                                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                      ),
                                      const SizedBox(height: 2),
                                      const Icon(Icons.check_circle_outline, color: AppTheme.primaryGreen, size: 16),
                                    ],
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
