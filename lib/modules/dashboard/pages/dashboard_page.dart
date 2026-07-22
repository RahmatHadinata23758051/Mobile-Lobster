import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_logo.dart';
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
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBg,
        elevation: 0,
        centerTitle: false,
        title: const Row(
          children: [
            AppLogo(size: 24, showText: false),
            SizedBox(width: 10),
            Text(
              'Lobsense Mobile',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textDark),
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined, color: AppTheme.textDark, size: 24),
                onPressed: () {},
              ),
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _selectedNavIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.cardBg,
          border: Border(top: BorderSide(color: AppTheme.borderCard, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedNavIndex,
          backgroundColor: AppTheme.cardBg,
          elevation: 0,
          selectedItemColor: AppTheme.primaryGreen,
          unselectedItemColor: AppTheme.textMuted,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          onTap: (idx) => setState(() => _selectedNavIndex = idx),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              activeIcon: Icon(Icons.grid_view_rounded, color: AppTheme.primaryGreen),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.tune_outlined),
              activeIcon: Icon(Icons.tune_outlined, color: AppTheme.primaryGreen),
              label: 'Kontrol',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person_outline, color: AppTheme.primaryGreen),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardView(UserModel? user) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
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
                // Banner Lokasi Tambak & Cuaca (Reference Green Card)
                _buildLocationWeatherBanner(),
                const SizedBox(height: 20),

                // Kualitas Air & Sensor Grid Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Kualitas Air & Sensor',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    InkWell(
                      onTap: () => _showAllSensorsModal(context),
                      child: const Row(
                        children: [
                          Text('Lihat Semua', style: TextStyle(fontSize: 12, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                          SizedBox(width: 2),
                          Icon(Icons.chevron_right, size: 16, color: AppTheme.primaryGreen),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 4 Sensor Cards Grid
                _buildSensorGrid(),
                const SizedBox(height: 20),

                // Ringkasan Sistem & Perangkat
                const Text(
                  'Ringkasan Sistem & Perangkat',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
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

  Widget _buildLocationWeatherBanner() {
    final stats = _dashboardData?['summary_stats'] ?? {};
    final location = stats['weather_location'] ?? 'Bojongsoang';
    final condition = stats['weather_condition'] ?? 'Cerah';
    final temp = stats['weather_temp_c'] ?? 28;
    final totalNodes = stats['total_active_nodes'] ?? 5;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lokasi Tambak',
                      style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      location,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sensors, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '$totalNodes Node Aktif',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Cuaca: $condition (${temp.toStringAsFixed(0)}°C)',
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorGrid() {
    final activeTelemetry = _dashboardData?['active_node_telemetry']?['telemetry'] ?? {};
    final temp = (activeTelemetry['temperature'] ?? 26.68).toDouble();
    final ph = (activeTelemetry['ph'] ?? 7.3).toDouble();
    final doVal = (activeTelemetry['dissolved_oxygen'] ?? 6.46).toDouble();
    final tds = (activeTelemetry['tds'] ?? 426.15).toDouble();

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: [
        _sensorCard('Suhu Air', '${temp.toStringAsFixed(2)} °C', Icons.thermostat_outlined, AppTheme.primaryGreen),
        _sensorCard('pH Air', ph.toStringAsFixed(1), Icons.water_drop_outlined, AppTheme.primaryGreen),
        _sensorCard('Oksigen (DO)', '${doVal.toStringAsFixed(2)} mg/L', Icons.air_outlined, AppTheme.primaryGreen),
        _sensorCard('TDS Air', '${tds.toStringAsFixed(2)} ppm', Icons.grid_on_outlined, AppTheme.primaryGreen),
      ],
    );
  }

  Widget _sensorCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 22),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textDark),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.badgeGreenBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_upward, size: 10, color: AppTheme.primaryGreen),
                SizedBox(width: 4),
                Text('Normal', style: TextStyle(color: AppTheme.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
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
                backgroundColor: AppTheme.badgeGreenBg,
                radius: 18,
                child: Icon(Icons.memory, size: 20, color: AppTheme.primaryGreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      serial,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 13),
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
                  color: AppTheme.badgeGreenBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: AppTheme.primaryGreen),
                    SizedBox(width: 4),
                    Text('ONLINE', style: TextStyle(color: AppTheme.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAllSensorsModal(BuildContext context) {
    final activeTelemetry = _dashboardData?['active_node_telemetry']?['telemetry'] ?? {};
    final temp = (activeTelemetry['temperature'] ?? 26.68).toDouble();
    final ph = (activeTelemetry['ph'] ?? 7.30).toDouble();
    final doVal = (activeTelemetry['dissolved_oxygen'] ?? 6.46).toDouble();
    final tds = (activeTelemetry['tds'] ?? 426.15).toDouble();
    final salinity = (activeTelemetry['salinity'] ?? 32.50).toDouble();
    final turbidity = (activeTelemetry['turbidity'] ?? 12.40).toDouble();
    final waterLevel = (activeTelemetry['water_level'] ?? 120.0).toDouble();
    final orp = (activeTelemetry['orp'] ?? 310.0).toDouble();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.82,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppTheme.lightBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modal Handle & Header
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderCard,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detail Kualitas Air & Sensor',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                      ),
                      Text(
                        'Ringkasan 8 parameter indikator tambak lobster',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Full Sensor List Grid
              Expanded(
                child: ListView(
                  children: [
                    _sensorDetailTile('Suhu Air', '${temp.toStringAsFixed(2)} °C', 'Ideal: 25.0 - 30.0 °C', Icons.thermostat_outlined),
                    _sensorDetailTile('pH Air', ph.toStringAsFixed(2), 'Ideal: 7.0 - 8.5', Icons.water_drop_outlined),
                    _sensorDetailTile('Oksigen Terlarut (DO)', '${doVal.toStringAsFixed(2)} mg/L', 'Ideal: > 4.0 mg/L', Icons.air_outlined),
                    _sensorDetailTile('TDS Air (Salinitas)', '${tds.toStringAsFixed(2)} ppm', 'Ideal: 300 - 600 ppm', Icons.grid_on_outlined),
                    _sensorDetailTile('Salinitas Air', '${salinity.toStringAsFixed(2)} ppt', 'Ideal: 28.0 - 35.0 ppt', Icons.waves_outlined),
                    _sensorDetailTile('Turbiditas / Kekeruhan', '${turbidity.toStringAsFixed(2)} NTU', 'Ideal: < 25.0 NTU', Icons.blur_on_outlined),
                    _sensorDetailTile('Ketinggian Air', '${waterLevel.toStringAsFixed(0)} cm', 'Ideal: 100 - 150 cm', Icons.height_outlined),
                    _sensorDetailTile('Potensial Redoks (ORP)', '${orp.toStringAsFixed(0)} mV', 'Ideal: 250 - 400 mV', Icons.bolt_outlined),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sensorDetailTile(String label, String value, String idealRange, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderCard),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.badgeGreenBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryGreen, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 14),
                ),
                Text(
                  idealRange,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDark),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.badgeGreenBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Normal', style: TextStyle(color: AppTheme.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
