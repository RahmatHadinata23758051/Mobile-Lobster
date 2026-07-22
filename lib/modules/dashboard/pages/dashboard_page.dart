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
  bool _isLoadingTelemetry = false;
  String? _error;
  Map<String, dynamic>? _dashboardData;
  String? _selectedNodeSerial;
  Map<String, dynamic>? _activeNodeTelemetry;
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
            final defaultSerial = body['data']['active_node_telemetry']?['serial_number'] ?? 'DEMO-NODE-001';
            _selectedNodeSerial = _selectedNodeSerial ?? defaultSerial;
            _activeNodeTelemetry ??= body['data']['active_node_telemetry']?['telemetry'] ?? {};
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

  Future<void> _fetchNodeTelemetry(String serialNumber) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    setState(() {
      _isLoadingTelemetry = true;
      _selectedNodeSerial = serialNumber;
      _activeNodeTelemetry = null; // Clear previous node telemetry immediately to prevent fallback leaks
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.mobileTelemetry}/$serialNumber'),
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
            _activeNodeTelemetry = body['data']['telemetry'] ?? {};
            _isLoadingTelemetry = false;
          });
          return;
        }
      }
    } catch (_) {}

    setState(() {
      _activeNodeTelemetry = {};
      _isLoadingTelemetry = false;
    });
  }

  String _formatSensorVal(dynamic val, [String unit = '', int decimals = 2]) {
    if (val == null) return '--';
    final num? n = num.tryParse(val.toString());
    if (n == null) return '--';
    final formatted = decimals == 0 ? n.toStringAsFixed(0) : n.toStringAsFixed(decimals);
    return unit.isNotEmpty ? '$formatted $unit' : formatted;
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
                const SizedBox(height: 16),

                // IoT Node / Edge Switcher Selector Card
                _buildNodeSwitcherCard(),
                const SizedBox(height: 20),

                // Kualitas Air & Sensor Grid Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Kualitas Air & Sensor',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        ),
                        if (_isLoadingTelemetry) ...[
                          const SizedBox(width: 8),
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGreen),
                          ),
                        ],
                      ],
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
    String location = stats['weather_location']?.toString() ?? 'Bojongsoang';
    if (location == '--' || location.trim().isEmpty) {
      location = 'Bojongsoang';
    }
    final condition = stats['weather_condition'] ?? 'Cerah';
    final temp = stats['weather_temp_c'];
    final totalNodes = stats['total_active_nodes'] ?? 0;

    final tempStr = temp != null ? '${num.tryParse(temp.toString())?.toStringAsFixed(0) ?? "--"}°C' : '--°C';

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
            'Cuaca: $condition ($tempStr)',
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeSwitcherCard() {
    final List nodes = _dashboardData?['nodes'] ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.alt_route_outlined, size: 18, color: AppTheme.primaryGreen),
                  SizedBox(width: 8),
                  Text(
                    'Pilih Perangkat IoT Node',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.badgeGreenBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, size: 6, color: AppTheme.primaryGreen),
                    SizedBox(width: 4),
                    Text('ACTIVE', style: TextStyle(color: AppTheme.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _selectedNodeSerial,
            dropdownColor: AppTheme.cardBg,
            style: const TextStyle(color: AppTheme.textDark, fontSize: 14, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              prefixIcon: Icon(Icons.memory_outlined, color: AppTheme.primaryGreen, size: 20),
            ),
            items: nodes.map<DropdownMenuItem<String>>((node) {
              final serial = node['serial_number']?.toString() ?? 'NODE';
              final cage = node['cage']?['cage_code']?.toString() ?? 'Keramba';
              return DropdownMenuItem<String>(
                value: serial,
                child: Text('$serial ($cage)', overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (newSerial) {
              if (newSerial != null && newSerial != _selectedNodeSerial) {
                _fetchNodeTelemetry(newSerial);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSensorGrid() {
    final activeTelemetry = _activeNodeTelemetry ?? {};

    final tempVal = activeTelemetry['temperature'] ?? activeTelemetry['water_temperature'] ?? activeTelemetry['ambient_temperature'];
    final phVal = activeTelemetry['ph'];
    final doVal = activeTelemetry['dissolved_oxygen'];
    final tdsVal = activeTelemetry['tds'];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: [
        _sensorCard('Suhu Air', _formatSensorVal(tempVal, '°C', 2), Icons.thermostat_outlined, AppTheme.primaryGreen, tempVal != null),
        _sensorCard('pH Air', _formatSensorVal(phVal, '', 1), Icons.water_drop_outlined, AppTheme.primaryGreen, phVal != null),
        _sensorCard('Oksigen (DO)', _formatSensorVal(doVal, 'mg/L', 2), Icons.air_outlined, AppTheme.primaryGreen, doVal != null),
        _sensorCard('TDS Air', _formatSensorVal(tdsVal, 'ppm', 2), Icons.grid_on_outlined, AppTheme.primaryGreen, tdsVal != null),
      ],
    );
  }

  Widget _sensorCard(String label, String value, IconData icon, Color color, bool hasData) {
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
            style: TextStyle(
              fontSize: value == '--' ? 22 : 20,
              fontWeight: FontWeight.w800,
              color: hasData ? AppTheme.textDark : AppTheme.textMuted,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: hasData ? AppTheme.badgeGreenBg : Colors.grey.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasData ? Icons.arrow_upward : Icons.remove,
                  size: 10,
                  color: hasData ? AppTheme.primaryGreen : AppTheme.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  hasData ? 'Normal' : '--',
                  style: TextStyle(
                    color: hasData ? AppTheme.primaryGreen : AppTheme.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceListSection() {
    final List nodes = _dashboardData?['nodes'] ?? [];

    if (nodes.isEmpty) {
      return const Text('Tidak ada perangkat terdaftar.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12));
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: nodes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        final node = nodes[idx];
        final serial = node['serial_number'] ?? 'NODE';
        final ip = node['ip_address'] ?? '192.168.1.x';
        final cageCode = node['cage']?['cage_code'] ?? 'Keramba';
        final isSelected = serial == _selectedNodeSerial;

        return InkWell(
          onTap: () => _fetchNodeTelemetry(serial),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.badgeGreenBg.withValues(alpha: 0.5) : AppTheme.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? AppTheme.primaryGreen : AppTheme.borderCard, width: isSelected ? 1.5 : 1),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: isSelected ? AppTheme.primaryGreen : AppTheme.badgeGreenBg,
                  radius: 18,
                  child: Icon(Icons.memory, size: 20, color: isSelected ? Colors.white : AppTheme.primaryGreen),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serial,
                        style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? AppTheme.primaryGreen : AppTheme.textDark, fontSize: 13),
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
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 8, color: AppTheme.primaryGreen),
                      const SizedBox(width: 4),
                      Text(
                        isSelected ? 'SELECTED' : 'ONLINE',
                        style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAllSensorsModal(BuildContext context) {
    final activeTelemetry = _activeNodeTelemetry ?? {};

    final tempVal = activeTelemetry['temperature'] ?? activeTelemetry['water_temperature'] ?? activeTelemetry['ambient_temperature'];
    final phVal = activeTelemetry['ph'];
    final doVal = activeTelemetry['dissolved_oxygen'];
    final tdsVal = activeTelemetry['tds'];
    final salinityVal = activeTelemetry['salinity'];
    final turbidityVal = activeTelemetry['turbidity'];
    final waterLevelVal = activeTelemetry['water_level'];
    final orpVal = activeTelemetry['orp'];

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detail Kualitas Air (${_selectedNodeSerial ?? "Node"})',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          'Ringkasan 8 parameter indikator tambak lobster',
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
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
                    _sensorDetailTile('Suhu Air', _formatSensorVal(tempVal, '°C', 2), 'Ideal: 25.0 - 30.0 °C', Icons.thermostat_outlined, tempVal != null),
                    _sensorDetailTile('pH Air', _formatSensorVal(phVal, '', 2), 'Ideal: 7.0 - 8.5', Icons.water_drop_outlined, phVal != null),
                    _sensorDetailTile('Oksigen Terlarut (DO)', _formatSensorVal(doVal, 'mg/L', 2), 'Ideal: > 4.0 mg/L', Icons.air_outlined, doVal != null),
                    _sensorDetailTile('TDS Air (Salinitas)', _formatSensorVal(tdsVal, 'ppm', 2), 'Ideal: 300 - 600 ppm', Icons.grid_on_outlined, tdsVal != null),
                    _sensorDetailTile('Salinitas Air', _formatSensorVal(salinityVal, 'ppt', 2), 'Ideal: 28.0 - 35.0 ppt', Icons.waves_outlined, salinityVal != null),
                    _sensorDetailTile('Turbiditas / Kekeruhan', _formatSensorVal(turbidityVal, 'NTU', 2), 'Ideal: < 25.0 NTU', Icons.blur_on_outlined, turbidityVal != null),
                    _sensorDetailTile('Ketinggian Air', _formatSensorVal(waterLevelVal, 'cm', 0), 'Ideal: 100 - 150 cm', Icons.height_outlined, waterLevelVal != null),
                    _sensorDetailTile('Potensial Redoks (ORP)', _formatSensorVal(orpVal, 'mV', 0), 'Ideal: 250 - 400 mV', Icons.bolt_outlined, orpVal != null),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sensorDetailTile(String label, String value, String idealRange, IconData icon, bool hasData) {
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: hasData ? AppTheme.textDark : AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: hasData ? AppTheme.badgeGreenBg : Colors.grey.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  hasData ? 'Normal' : '--',
                  style: TextStyle(
                    color: hasData ? AppTheme.primaryGreen : AppTheme.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
