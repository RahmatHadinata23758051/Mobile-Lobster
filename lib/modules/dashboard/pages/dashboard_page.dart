import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/pages/login_page.dart';

import 'control_page.dart';
import 'profile_page.dart';

class MobileDashboardPage extends StatefulWidget {
  const MobileDashboardPage({super.key});

  @override
  State<MobileDashboardPage> createState() => _MobileDashboardPageState();
}

class _MobileDashboardPageState extends State<MobileDashboardPage> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _dashboardData;
  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse(ApiConstants.mobileSummary),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${auth.token}',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success') {
          setState(() {
            _dashboardData = body['data'];
            _isLoading = false;
          });
          return;
        }
      }
      setState(() {
        _error = 'Gagal memuat data dari server (${response.statusCode})';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error koneksi jaringan: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    final List<Widget> pages = [
      _buildDashboardView(user),
      const MobileControlPage(),
      const MobileProfilePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.water_drop, color: AppTheme.accentGreen, size: 20),
            SizedBox(width: 8),
            Text('Lobsense Mobile'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchSummary,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.dangerRed),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await auth.logout();
              navigator.pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedNavIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        backgroundColor: AppTheme.cardBg,
        selectedItemColor: AppTheme.accentGreen,
        unselectedItemColor: AppTheme.textMuted,
        onTap: (idx) => setState(() => _selectedNavIndex = idx),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dasbor'),
          BottomNavigationBarItem(icon: Icon(Icons.tune), label: 'Kontrol'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildDashboardView(UserModel? user) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: AppTheme.dangerRed)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _fetchSummary, child: const Text('Coba Lagi')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchSummary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Welcome Header
                _buildUserHeader(user),
                const SizedBox(height: 16),

                // Weather & Node Summary Stats Card
                _buildSummaryHeaderCard(),
                const SizedBox(height: 20),

                // Aggregate Sensor Readings Grid
                const Text(
                  'Kualitas Air & Sensor Agregat',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                ),
                const SizedBox(height: 12),
                _buildSensorGrid(),
                const SizedBox(height: 24),

                // Hardware Controls & Feeding Automation
                const Text(
                  'Kontrol & Otomatisasi Pakan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                ),
                const SizedBox(height: 12),
                _buildHardwareControlCard(),
                const SizedBox(height: 24),

                // Daftar Perangkat IoT Node Section
                const Text(
                  'Daftar Perangkat IoT (Active Nodes)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                ),
                const SizedBox(height: 12),
                _buildDeviceListSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader(UserModel? user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderCard),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryTeal,
            child: Text(
              user?.name.substring(0, 1).toUpperCase() ?? 'U',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, ${user?.name ?? "Pengguna"} 👋',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 2),
              Text(
                'Role: ${user?.role.toUpperCase() ?? "OPERATOR"}',
                style: const TextStyle(fontSize: 12, color: AppTheme.accentGreen, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeaderCard() {
    final stats = _dashboardData?['summary_stats'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F4C5C), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Lokasi Tambak', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              Text(
                stats?['weather_location'] ?? 'Lombok Barat',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Cuaca: ${stats?['weather_condition'] ?? "Cerah"} (${stats?['weather_temp_c']}°C)',
                style: const TextStyle(color: AppTheme.accentCyan, fontSize: 13),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(Icons.sensors, color: AppTheme.accentGreen, size: 24),
                const SizedBox(height: 4),
                Text(
                  '${stats?['total_active_nodes'] ?? 0} Node Aktif',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSensorGrid() {
    final telemetry = _dashboardData?['active_node_telemetry']?['telemetry'] ?? {};

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _sensorCard('Suhu Air', '${telemetry['water_temperature'] ?? 28.5} °C', Icons.thermostat, Colors.orange),
        _sensorCard('pH Air', '${telemetry['ph'] ?? 7.5}', Icons.science, Colors.blue),
        _sensorCard('Oksigen (DO)', '${telemetry['dissolved_oxygen'] ?? 6.2} mg/L', Icons.air, Colors.green),
        _sensorCard('TDS Air', '${telemetry['tds'] ?? 450} ppm', Icons.water, Colors.cyan),
      ],
    );
  }

  Widget _sensorCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              Icon(icon, size: 18, color: color),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildHardwareControlCard() {
    final defaultSerial = _dashboardData?['active_node_telemetry']?['serial_number'] ?? 'DEMO-NODE-001';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Node Aktif: $defaultSerial',
            style: const TextStyle(color: AppTheme.accentGreen, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.bolt, size: 18),
                  label: const Text('Buka Pakan (5s)', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal),
                  onPressed: () async {
                    final auth = Provider.of<AuthProvider>(context, listen: false);
                    final res = await http.post(
                      Uri.parse(ApiConstants.mobileFeedingInstantTrigger),
                      headers: {
                        'Content-Type': 'application/json',
                        'Authorization': 'Bearer ${auth.token}'
                      },
                      body: jsonEncode({
                        'iot_node_serial_number': defaultSerial,
                        'duration_seconds': 5,
                      }),
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res.statusCode == 200
                              ? 'Perintah pakan manual berhasil dikirim ke Node $defaultSerial!'
                              : 'Gagal mengirim perintah'),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceListSection() {
    final List nodes = _dashboardData?['nodes'] ?? [
      {'serial_number': 'DEMO-NODE-001', 'ip_address': '192.168.1.101', 'cage': {'cage_code': 'CAGE-01'}},
      {'serial_number': 'LOBSTER-ESP32-001', 'ip_address': '192.168.1.102', 'cage': {'cage_code': 'CAGE-02'}},
      {'serial_number': 'LOBSTER-ESP32-002', 'ip_address': '192.168.1.103', 'cage': {'cage_code': 'CAGE-03'}},
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: nodes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        final node = nodes[idx];
        final serial = node['serial_number'] ?? 'NODE-001';
        final ip = node['ip_address'] ?? '192.168.1.x';
        final cageCode = node['cage']?['cage_code'] ?? 'Keramba Utama';

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
                backgroundColor: AppTheme.accentGreen,
                radius: 18,
                child: Icon(Icons.memory, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      serial,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                    ),
                    Text(
                      'Lokasi: $cageCode • IP: $ip',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: AppTheme.accentGreen),
                    SizedBox(width: 4),
                    Text('ONLINE', style: TextStyle(color: AppTheme.accentGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
