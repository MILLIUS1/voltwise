import 'screens/login_screen.dart';
import 'widgets/app_header.dart';
import 'widgets/voltwise_drawer.dart';
import 'services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // Continue even if .env is missing because ApiService uses a fixed cloud URL.
  }

  runApp(const SHEMSApp());
}

class SHEMSApp extends StatelessWidget {
  const SHEMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VoltWise SHEMS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xffF7F9FC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff0B6EF6),
        ),
      ),
      home: const LoginScreen(),
      routes: {
        '/home': (context) => const MainShell(),
      },
    );
  }
}


class SystemSettings {
  static double conservationThreshold = 50;
  static double criticalThreshold = 20;
  static double reserveLevel = 10;
  static bool notificationsEnabled = true;
  static bool darkModeEnabled = false;
}

class UserProfileData {
  static String name = 'Millius N. Liswaniso';
  static String email = 'milliusn@gmail.com';
  static String phone = '+260 965 634 501';
  static String location = 'Lusaka, Zambia';
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int selectedIndex = 0;
  late Future<List<dynamic>> appliancesFuture;

  @override
  void initState() {
    super.initState();
    appliancesFuture = ApiService.getAppliances();
  }

  Future<void> refreshAppliances() async {
    setState(() {
      appliancesFuture = ApiService.getAppliances();
    });
  }

  List<Appliance> mapApiAppliances(List<dynamic> data) {
    return data.map((item) {
      final name = item['name'] ?? 'Unknown';
      final priority = (item['priority'] ?? 'LOW').toString();
      final powerRating = item['power_rating'] ?? 0;
      final status = item['status'] == true;

      return Appliance(
        item['id'] ?? 0,
        name,
        priority[0] + priority.substring(1).toLowerCase(),
        '$powerRating W',
        getApplianceIcon(name),
        getApplianceColor(priority),
        status,
      );
    }).toList();
  }

  IconData getApplianceIcon(String name) {
    final lowerName = name.toLowerCase();

    if (lowerName.contains('refrigerator')) return Icons.kitchen;
    if (lowerName.contains('light')) return Icons.lightbulb;
    if (lowerName.contains('wifi') || lowerName.contains('wi-fi')) {
      return Icons.wifi;
    }
    if (lowerName.contains('television') || lowerName.contains('tv')) {
      return Icons.tv;
    }
    if (lowerName.contains('air')) return Icons.ac_unit;

    return Icons.electrical_services;
  }

  Color getApplianceColor(String priority) {
    if (priority == 'HIGH') return Colors.red;
    if (priority == 'MEDIUM') return Colors.orange;
    return Colors.green;
  }

  Future<void> updateAppliancePriority(
    String applianceName,
    String newPriority,
  ) async {
    final appliances = mapApiAppliances(await appliancesFuture);
    final appliance = appliances.firstWhere(
      (item) => item.name == applianceName,
    );

    await ApiService.updateAppliancePriority(
      applianceId: appliance.id,
      priority: newPriority,
    );

    await refreshAppliances();
  }

  Future<void> updateApplianceStatus(String applianceName, bool isOn) async {
    final appliances = mapApiAppliances(await appliancesFuture);
    final appliance = appliances.firstWhere(
      (item) => item.name == applianceName,
    );

    await ApiService.updateApplianceStatus(
      applianceId: appliance.id,
      status: isOn,
    );

    await refreshAppliances();
  }

  Widget get currentPage {
    switch (selectedIndex) {
      case 0:
        return const HomeDashboard();
      case 1:
        return FutureBuilder<List<dynamic>>(
          future: appliancesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const AppHeader(
                    title: 'Appliances',
                    leftIcon: Icons.arrow_back_ios_new,
                  ),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: cardDecoration(Colors.white),
                    child: Text(
                      'Failed to load appliances: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: refreshAppliances,
                    child: const Text('Retry'),
                  ),
                ],
              );
            }

            final appliances = mapApiAppliances(snapshot.data ?? []);

            return RefreshIndicator(
              onRefresh: refreshAppliances,
              child: ApplianceScreen(
                appliances: appliances,
                onPriorityChanged: updateAppliancePriority,
                onStatusChanged: updateApplianceStatus,
              ),
            );
          },
        );
      case 2:
        return const EnergyAutomationScreen();
      case 3:
        return const ReportsScreen();
      default:
        return const HomeDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const VoltWiseDrawer(),
      body: SafeArea(child: currentPage),
      bottomNavigationBar: NavigationBar(
        height: 70,
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_input_component_outlined),
            selectedIcon: Icon(Icons.settings_input_component),
            label: 'Appliances',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Automation',
          ),
          NavigationDestination(
            icon: Icon(Icons.insert_chart_outlined),
            selectedIcon: Icon(Icons.insert_chart),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  late Future<Map<String, dynamic>> dashboardFuture;

  @override
  void initState() {
    super.initState();
    dashboardFuture = ApiService.getDashboard();
  }

  Future<void> refreshDashboard() async {
    setState(() {
      dashboardFuture = ApiService.getDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const AppHeader(title: 'VoltWise', showSubtitle: true),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: cardDecoration(Colors.white),
                child: Text(
                  'Failed to load dashboard data: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: refreshDashboard,
                child: const Text('Retry'),
              ),
            ],
          );
        }

        final data = snapshot.data!;
        final gridStatus = data['grid_status'] == true;
        final batteryLevel = data['battery_level'] ?? 0;
        final currentUsage = data['current_usage'] ?? 0;
        final activeAppliances = data['active_appliances'] ?? 0;
        final totalAppliances = data['total_appliances'] ?? 0;
        final todayEnergyUsage = data['today_energy_usage'] ?? 0;
        final latestAlert = data['latest_alert'] ?? 'No alerts';

        return RefreshIndicator(
          onRefresh: refreshDashboard,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            children: [
              const AppHeader(title: 'VoltWise', showSubtitle: true),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: cardDecoration(
                  gridStatus ? const Color(0xffEAF8EE) : const Color(0xffFEECEC),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Power Source', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 10),
                          Text(
                            gridStatus ? 'ZESCO POWER' : 'BATTERY BACKUP',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: gridStatus ? const Color(0xff16A34A) : Colors.red,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(gridStatus ? 'Status: Normal' : 'Status: Grid Offline'),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.circle,
                                color: gridStatus ? const Color(0xff16A34A) : Colors.red,
                                size: 10,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      gridStatus ? Icons.electric_bolt : Icons.battery_saver,
                      size: 72,
                      color: gridStatus ? const Color(0xff16A34A) : Colors.red,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InfoCard(
                      title: 'Battery Level',
                      value: '${batteryLevel.round()}%',
                      subtitle: gridStatus ? 'Charging' : 'Backup Mode',
                      icon: Icons.battery_charging_full,
                      color: const Color(0xff16A34A),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: InfoCard(
                      title: 'Total Power',
                      value: '$currentUsage W',
                      subtitle: 'Current Usage',
                      icon: Icons.flash_on,
                      color: const Color(0xff0B6EF6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: cardDecoration(Colors.white),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Active Appliances', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 10),
                          Text(
                            '$activeAppliances / $totalAppliances',
                            style: const TextStyle(fontSize: 26, color: Color(0xff0B6EF6), fontWeight: FontWeight.w900),
                          ),
                          const Text('Appliances ON'),
                        ],
                      ),
                    ),
                    const Icon(Icons.home_work_outlined, size: 70, color: Color(0xff0B6EF6)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: cardDecoration(Colors.white),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Today's Energy Usage", style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 10),
                          Text(
                            '$todayEnergyUsage W',
                            style: const TextStyle(fontSize: 25, color: Color(0xff6D5DF6), fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            latestAlert,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    const MiniBars(color: Color(0xff8B5CF6)),
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

class ApplianceScreen extends StatefulWidget {
  final List<Appliance> appliances;
  final Future<void> Function(String applianceName, String newPriority) onPriorityChanged;
  final Future<void> Function(String applianceName, bool isOn) onStatusChanged;

  const ApplianceScreen({
    super.key,
    required this.appliances,
    required this.onPriorityChanged,
    required this.onStatusChanged,
  });

  @override
  State<ApplianceScreen> createState() => _ApplianceScreenState();
}

class _ApplianceScreenState extends State<ApplianceScreen> {
  String selectedFilter = 'All';

  List<Appliance> get filteredAppliances {
    return widget.appliances.where((item) {
      if (selectedFilter == 'ON') return item.isOn;
      if (selectedFilter == 'OFF') return !item.isOn;
      if (selectedFilter == 'High') return item.priority == 'High';
      if (selectedFilter == 'Medium') return item.priority == 'Medium';
      if (selectedFilter == 'Low') return item.priority == 'Low';
      return true;
    }).toList();
  }

  void openManagePriorityPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManagePriorityScreen(
          appliances: widget.appliances,
          onPriorityChanged: widget.onPriorityChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onCount = widget.appliances.where((item) => item.isOn).length;
    final offCount = widget.appliances.length - onCount;
    final highCount = widget.appliances.where((item) => item.priority == 'High').length;
    final mediumCount = widget.appliances.where((item) => item.priority == 'Medium').length;
    final lowCount = widget.appliances.where((item) => item.priority == 'Low').length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      children: [
        const AppHeader(title: 'Appliances', leftIcon: Icons.arrow_back_ios_new),
        Row(
          children: [
            filterChip('All (${widget.appliances.length})', 'All'),
            filterChip('ON ($onCount)', 'ON'),
            filterChip('OFF ($offCount)', 'OFF'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            filterChip('High ($highCount)', 'High'),
            filterChip('Medium ($mediumCount)', 'Medium'),
            filterChip('Low ($lowCount)', 'Low'),
          ],
        ),
        const SizedBox(height: 14),
        ...filteredAppliances.map(
          (a) => ApplianceTile(
            appliance: a,
            onStatusChanged: (value) async {
              final previousStatus = a.isOn;
              setState(() => a.isOn = value);

              try {
                await widget.onStatusChanged(a.name, value);
              } catch (error) {
                if (!mounted) return;
                setState(() => a.isOn = previousStatus);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update ${a.name}: $error')),
                );
              }
            },
          ),
        ),
        const SizedBox(height: 18),
        ElevatedButton.icon(
          onPressed: openManagePriorityPage,
          icon: const Icon(Icons.tune),
          label: const Text('Manage Priorities'),
        ),
      ],
    );
  }

  Widget filterChip(String label, String filter) {
    final active = selectedFilter == filter;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedFilter = filter),
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? const Color(0xff0B6EF6) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xffE2E8F0)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}


class ManagePriorityScreen extends StatefulWidget {
  final List<Appliance> appliances;
  final Future<void> Function(String applianceName, String newPriority) onPriorityChanged;

  const ManagePriorityScreen({
    super.key,
    required this.appliances,
    required this.onPriorityChanged,
  });

  @override
  State<ManagePriorityScreen> createState() => _ManagePriorityScreenState();
}

class _ManagePriorityScreenState extends State<ManagePriorityScreen> {
  late List<AppliancePrioritySetting> prioritySettings;

  final List<String> priorityLevels = const ['High', 'Medium', 'Low'];

  @override
  void initState() {
    super.initState();
    prioritySettings = widget.appliances
        .map(
          (appliance) => AppliancePrioritySetting(
            name: appliance.name,
            priority: appliance.priority,
            power: appliance.power,
            icon: appliance.icon,
            color: appliance.color,
          ),
        )
        .toList();
  }

  Color priorityColor(String priority) {
    if (priority == 'High') return Colors.red;
    if (priority == 'Medium') return Colors.orange;
    return Colors.green;
  }

  String priorityDescription(String priority) {
    if (priority == 'High') return 'Protected during outages';
    if (priority == 'Medium') return 'Managed based on available power';
    return 'Disconnected first during low power';
  }

  int get highCount => prioritySettings.where((item) => item.priority == 'High').length;
  int get mediumCount => prioritySettings.where((item) => item.priority == 'Medium').length;
  int get lowCount => prioritySettings.where((item) => item.priority == 'Low').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F9FC),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Manage Priorities',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.save_outlined),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Priority settings saved successfully')),
                      );
                    },
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: cardDecoration(const Color(0xffEEF6FF)),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tune, color: Color(0xff0B6EF6)),
                      SizedBox(width: 10),
                      Text(
                        'Load Priority Control',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Set which appliances should remain powered first when backup energy is limited.',
                    style: TextStyle(color: Colors.black54, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                PrioritySummaryCard(label: 'High', value: '$highCount', color: Colors.red),
                const SizedBox(width: 10),
                PrioritySummaryCard(label: 'Medium', value: '$mediumCount', color: Colors.orange),
                const SizedBox(width: 10),
                PrioritySummaryCard(label: 'Low', value: '$lowCount', color: Colors.green),
              ],
            ),
            const SizedBox(height: 16),
            ...prioritySettings.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: cardDecoration(Colors.white),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: item.color.withAlpha(38),
                            child: Icon(item.icon, color: item.color),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                                const SizedBox(height: 4),
                                Text(item.power, style: const TextStyle(color: Colors.black54)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: priorityColor(item.priority).withAlpha(28),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              item.priority,
                              style: TextStyle(
                                color: priorityColor(item.priority),
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: item.priority,
                        decoration: InputDecoration(
                          labelText: 'Priority Level',
                          filled: true,
                          fillColor: const Color(0xffF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xffE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xffE2E8F0)),
                          ),
                        ),
                        items: priorityLevels.map((level) {
                          return DropdownMenuItem(
                            value: level,
                            child: Row(
                              children: [
                                Icon(Icons.circle, size: 10, color: priorityColor(level)),
                                const SizedBox(width: 8),
                                Text(level),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) async {
                          if (value == null) return;

                          final previousPriority = item.priority;
                          setState(() => item.priority = value);

                          try {
                            await widget.onPriorityChanged(item.name, value);
                          } catch (error) {
                            if (!mounted) return;
                            setState(() => item.priority = previousPriority);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to update ${item.name}: $error'),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          priorityDescription(item.priority),
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Priority settings saved successfully')),
                );
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Save Priority Settings'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor: const Color(0xff16A34A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppliancePrioritySetting {
  final String name;
  String priority;
  final String power;
  final IconData icon;
  final Color color;

  AppliancePrioritySetting({
    required this.name,
    required this.priority,
    required this.power,
    required this.icon,
    required this.color,
  });
}

class PrioritySummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const PrioritySummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: cardDecoration(Colors.white),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 22, color: color, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}


class EnergyAutomationScreen extends StatefulWidget {
  const EnergyAutomationScreen({super.key});

  @override
  State<EnergyAutomationScreen> createState() => _EnergyAutomationScreenState();
}

class _EnergyAutomationScreenState extends State<EnergyAutomationScreen> {
  late Future<List<dynamic>> alertsFuture;

  @override
  void initState() {
    super.initState();
    alertsFuture = ApiService.getAlerts();
  }

  Future<void> refreshAlerts() async {
    setState(() {
      alertsFuture = ApiService.getAlerts();
    });
  }

  Color severityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return Colors.red;
      case 'WARNING':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  IconData severityIcon(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return Icons.emergency;
      case 'WARNING':
        return Icons.warning_amber;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final conservation = SystemSettings.conservationThreshold.round();
    final critical = SystemSettings.criticalThreshold.round();
    final reserve = SystemSettings.reserveLevel.round();

    return FutureBuilder<List<dynamic>>(
      future: alertsFuture,
      builder: (context, snapshot) {
        final alerts = snapshot.data ?? [];
        final warningCount = alerts.where((alert) {
          return (alert['severity'] ?? '').toString().toUpperCase() == 'WARNING';
        }).length;

        return RefreshIndicator(
          onRefresh: refreshAlerts,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            children: [
              const AppHeader(
                title: 'Energy Automation',
                leftIcon: Icons.arrow_back_ios_new,
                rightIcon: Icons.auto_awesome,
              ),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: cardDecoration(const Color(0xffEEF6FF)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Color(0xff0B6EF6),
                          child: Icon(Icons.auto_awesome, color: Colors.white),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Automated Energy Decisions',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'VoltWise uses your Settings values to automate load control. Conservation: $conservation%, Critical: $critical%, Reserve: $reserve%.',
                      style: const TextStyle(color: Colors.black54, height: 1.45),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  AutomationStatCard(
                    value: '${alerts.length}',
                    label: 'Alerts',
                    icon: Icons.notifications_active,
                    color: const Color(0xff0B6EF6),
                  ),
                  const SizedBox(width: 10),
                  const AutomationStatCard(
                    value: '4',
                    label: 'Modes',
                    icon: Icons.battery_saver,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 10),
                  AutomationStatCard(
                    value: '$warningCount',
                    label: 'Warnings',
                    icon: Icons.warning_amber,
                    color: Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: cardDecoration(Colors.white),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Battery Automation Rules',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 12),
                    BatteryRuleRow(
                      level: '> $conservation%',
                      mode: 'Normal Operation',
                      action: 'All appliances allowed',
                      color: Colors.green,
                    ),
                    BatteryRuleRow(
                      level: '≤ $conservation%',
                      mode: 'Battery Conservation Mode',
                      action: 'Low-priority appliances disconnected',
                      color: Colors.orange,
                    ),
                    BatteryRuleRow(
                      level: '≤ $critical%',
                      mode: 'Critical Power Mode',
                      action: 'Only high-priority appliances remain ON',
                      color: const Color(0xff0B6EF6),
                    ),
                    BatteryRuleRow(
                      level: '≤ $reserve%',
                      mode: 'Emergency Reserve Mode',
                      action: 'Emergency reserve protection active',
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Live Automation Alerts',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              if (!SystemSettings.notificationsEnabled)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: cardDecoration(Colors.white),
                  child: const Text('Notifications are currently disabled in Settings.'),
                )
              else if (snapshot.connectionState == ConnectionState.waiting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (snapshot.hasError)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: cardDecoration(Colors.white),
                  child: Text(
                    'Failed to load alerts: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              else if (alerts.isEmpty)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: cardDecoration(Colors.white),
                  child: const Text('No automation alerts available.'),
                )
              else
                ...alerts.map((alert) {
                  final severity = (alert['severity'] ?? 'INFO').toString();
                  final color = severityColor(severity);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: cardDecoration(Colors.white),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          severityIcon(severity),
                          size: 42,
                          color: color,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alert['title'] ?? 'System Alert',
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(alert['message'] ?? ''),
                              const SizedBox(height: 8),
                              Text(
                                alert['timestamp'] ?? '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      children: [
        const AppHeader(
          title: 'Energy Reports',
          leftIcon: Icons.arrow_back_ios_new,
          rightIcon: Icons.calendar_month,
        ),
        Row(
          children: [
            tabButton('Daily', true),
            tabButton('Weekly', false),
            tabButton('Monthly', false),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: cardDecoration(const Color(0xffEEF6FF)),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today’s Energy Summary',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 12),
              Text(
                '8.45 kWh',
                style: TextStyle(
                  fontSize: 34,
                  color: Color(0xff0B6EF6),
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Total consumption recorded today',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: const [
            ReportMetricCard(
              title: 'Peak Load',
              value: '2.10 kW',
              icon: Icons.trending_up,
              color: Colors.red,
            ),
            SizedBox(width: 10),
            ReportMetricCard(
              title: 'Savings',
              value: '21%',
              icon: Icons.savings,
              color: Colors.green,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: cardDecoration(Colors.white),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Consumption Pattern', style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text('Hourly usage distribution', style: TextStyle(color: Colors.black54, fontSize: 12)),
              const SizedBox(height: 20),
              const BarChartMock(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: cardDecoration(Colors.white),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('System Performance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              SizedBox(height: 10),
              SummaryRow(label: 'Total Consumption', value: '8.45 kWh', color: Color(0xff0B6EF6)),
              SummaryRow(label: 'Peak Usage', value: '2.10 kW', color: Colors.red),
              SummaryRow(label: 'Average Usage', value: '0.85 kW', color: Colors.green),
              SummaryRow(label: 'Estimated Savings', value: '2.35 kWh', color: Colors.green),
              SummaryRow(label: 'Automations Executed', value: '5', color: Colors.orange),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: cardDecoration(Colors.white),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Appliance Consumption Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              SizedBox(height: 12),
              ApplianceUsageRow(name: 'Electric Iron', value: '2.10 kWh', percent: '25%', color: Colors.pink),
              ApplianceUsageRow(name: 'Washing Machine', value: '1.80 kWh', percent: '21%', color: Colors.indigo),
              ApplianceUsageRow(name: 'Refrigerator', value: '1.50 kWh', percent: '18%', color: Colors.blue),
              ApplianceUsageRow(name: 'Lighting', value: '1.20 kWh', percent: '14%', color: Colors.amber),
              ApplianceUsageRow(name: 'Television', value: '0.95 kWh', percent: '11%', color: Colors.deepPurple),
              ApplianceUsageRow(name: 'Security Cameras', value: '0.40 kWh', percent: '5%', color: Colors.teal),
            ],
          ),
        ),
      ],
    );
  }

  Widget tabButton(String label, bool active) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0xff0B6EF6) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xffE2E8F0)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: active ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}


class InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const InfoCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(Colors.white),
      child: Column(
        children: [
          Align(alignment: Alignment.centerLeft, child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
          const SizedBox(height: 12),
          Icon(icon, color: color, size: 40),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 25, color: color, fontWeight: FontWeight.w900)),
          Text(subtitle),
        ],
      ),
    );
  }
}

class Appliance {
  final int id;
  final String name;
  String priority;
  final String power;
  final IconData icon;
  final Color color;
  bool isOn;

  Appliance(
    this.id,
    this.name,
    this.priority,
    this.power,
    this.icon,
    this.color,
    this.isOn,
  );
}

class ApplianceTile extends StatelessWidget {
  final Appliance appliance;
  final ValueChanged<bool> onStatusChanged;

  const ApplianceTile({
    super.key,
    required this.appliance,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColor = appliance.priority == 'High'
        ? Colors.red
        : appliance.priority == 'Medium'
            ? Colors.orange
            : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(Colors.white),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: appliance.color.withAlpha(38),
            child: Icon(appliance.icon, color: appliance.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appliance.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: priorityColor, borderRadius: BorderRadius.circular(6)),
                  child: Text(appliance.priority, style: const TextStyle(color: Colors.white, fontSize: 11)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(appliance.power, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: appliance.isOn ? const Color(0xffEAF8EE) : const Color(0xffF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: appliance.isOn ? const Color(0xff16A34A) : const Color(0xffCBD5E1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      appliance.isOn ? Icons.power : Icons.power_off,
                      size: 12,
                      color: appliance.isOn ? const Color(0xff16A34A) : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      appliance.isOn ? 'ON' : 'OFF',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: appliance.isOn ? const Color(0xff16A34A) : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Switch(
            value: appliance.isOn,
            onChanged: onStatusChanged,
            thumbIcon: WidgetStateProperty.resolveWith<Icon?>((states) {
              if (states.contains(WidgetState.selected)) {
                return const Icon(Icons.check, size: 16);
              }
              return const Icon(Icons.close, size: 16);
            }),
          ),
        ],
      ),
    );
  }
}

class AlertItem {
  final IconData icon;
  final String title;
  final String message;
  final String time;
  final Color color;
  final Color bg;

  AlertItem(this.icon, this.title, this.message, this.time, this.color, this.bg);
}

class AlertCard extends StatelessWidget {
  final AlertItem alert;

  const AlertCard({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(alert.bg),
      child: Row(
        children: [
          Icon(alert.icon, size: 42, color: alert.color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.title, style: TextStyle(color: alert.color, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(alert.message),
              ],
            ),
          ),
          Text(alert.time, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }
}

class BarChartMock extends StatelessWidget {
  const BarChartMock({super.key});

  final values = const [0.3, 0.8, 1.8, 0.6, 1.2, 0.7, 1.5, 0.9, 0.8, 0.4, 0.5, 1.3, 0.7, 1.0, 0.6, 0.4, 0.7, 1.1, 0.9, 1.8, 0.8];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: values.map((v) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: v * 75,
              decoration: BoxDecoration(
                color: const Color(0xff0B6EF6),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class MiniBars extends StatelessWidget {
  final Color color;

  const MiniBars({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    final bars = [20.0, 35.0, 48.0, 30.0, 60.0, 25.0, 50.0];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: bars.map((h) {
        return Container(
          width: 9,
          height: h,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(color: color.withAlpha(179), borderRadius: BorderRadius.circular(6)),
        );
      }).toList(),
    );
  }
}

class SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const SummaryRow({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}


class AutomationStatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const AutomationStatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: cardDecoration(Colors.white),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 22, color: color, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class BatteryRuleRow extends StatelessWidget {
  final String level;
  final String mode;
  final String action;
  final Color color;

  const BatteryRuleRow({
    super.key,
    required this.level,
    required this.mode,
    required this.action,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: color.withAlpha(28),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              level,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mode, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(action, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReportMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const ReportMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: cardDecoration(Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black54)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 24, color: color, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class ApplianceUsageRow extends StatelessWidget {
  final String name;
  final String value;
  final String percent;
  final Color color;

  const ApplianceUsageRow({
    super.key,
    required this.name,
    required this.value,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(width: 10),
          Text(percent, style: TextStyle(color: color, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return SimplePage(
      title: 'Profile',
      children: [
        const ProfileHeaderCard(),
        const SizedBox(height: 16),
        infoTile(Icons.person, 'Name', UserProfileData.name),
        infoTile(Icons.email, 'Email', UserProfileData.email),
        infoTile(Icons.phone, 'Phone', UserProfileData.phone),
        infoTile(Icons.location_on, 'Home Location', UserProfileData.location),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfilePage()),
            );
            setState(() {});
          },
          icon: const Icon(Icons.edit),
          label: const Text('Edit Profile'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: const Color(0xff0B6EF6),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;
  late final TextEditingController locationController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: UserProfileData.name);
    emailController = TextEditingController(text: UserProfileData.email);
    phoneController = TextEditingController(text: UserProfileData.phone);
    locationController = TextEditingController(text: UserProfileData.location);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SimplePage(
      title: 'Edit Profile',
      children: [
        editField(Icons.person, 'Name', nameController),
        editField(Icons.email, 'Email', emailController),
        editField(Icons.phone, 'Phone', phoneController),
        editField(Icons.location_on, 'Home Location', locationController),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            UserProfileData.name = nameController.text.trim();
            UserProfileData.email = emailController.text.trim();
            UserProfileData.phone = phoneController.text.trim();
            UserProfileData.location = locationController.text.trim();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully')),
            );
            Navigator.pop(context);
          },
          icon: const Icon(Icons.save),
          label: const Text('Save Changes'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: const Color(0xff16A34A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  Widget editField(IconData icon, String label, TextEditingController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF16A34A)),
          filled: true,
          fillColor: const Color(0xffF8FAFC),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: cardDecoration(const Color(0xffEAF8EE)),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 42,
            backgroundColor: Color(0xFF16A34A),
            child: Icon(Icons.person, color: Colors.white, size: 46),
          ),
          const SizedBox(height: 12),
          Text(
            UserProfileData.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text('VoltWise System User', style: TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      final settings = await ApiService.getSettings();

      setState(() {
        SystemSettings.conservationThreshold =
            (settings['conservation_threshold'] as num).toDouble();
        SystemSettings.criticalThreshold =
            (settings['critical_threshold'] as num).toDouble();
        SystemSettings.reserveLevel =
            (settings['reserve_level'] as num).toDouble();
        SystemSettings.notificationsEnabled =
            settings['notifications_enabled'] ?? true;
        SystemSettings.darkModeEnabled =
            settings['dark_mode_enabled'] ?? false;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Using local settings: $e')),
      );
    }
  }

  Future<void> saveSettings() async {
    setState(() => isSaving = true);

    try {
      await ApiService.saveSettings(
        conservationThreshold: SystemSettings.conservationThreshold,
        criticalThreshold: SystemSettings.criticalThreshold,
        reserveLevel: SystemSettings.reserveLevel,
        notificationsEnabled: SystemSettings.notificationsEnabled,
        darkModeEnabled: SystemSettings.darkModeEnabled,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save settings: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xffF7F9FC),
        body: SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return SimplePage(
      title: 'Settings',
      children: [
        settingsSlider(
          title: 'Energy Thresholds',
          subtitle: 'Battery conservation mode starts at this level',
          icon: Icons.bolt,
          value: SystemSettings.conservationThreshold,
          min: 30,
          max: 80,
          unit: '%',
          onChanged: (value) {
            setState(() {
              SystemSettings.conservationThreshold = value;
            });
          },
        ),
        settingsSlider(
          title: 'Critical Battery Threshold',
          subtitle: 'Only critical loads remain ON from this level',
          icon: Icons.warning_amber,
          value: SystemSettings.criticalThreshold,
          min: 10,
          max: 40,
          unit: '%',
          onChanged: (value) {
            setState(() {
              SystemSettings.criticalThreshold = value;
            });
          },
        ),
        settingsSlider(
          title: 'Battery Reserve Level',
          subtitle: 'Minimum protected battery reserve',
          icon: Icons.battery_saver,
          value: SystemSettings.reserveLevel,
          min: 5,
          max: 30,
          unit: '%',
          onChanged: (value) {
            setState(() {
              SystemSettings.reserveLevel = value;
            });
          },
        ),
        SwitchListTile(
          value: SystemSettings.notificationsEnabled,
          onChanged: (value) {
            setState(() {
              SystemSettings.notificationsEnabled = value;
            });
          },
          title: const Text(
            'Notification Preferences',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: const Text('Receive system alerts and automation messages'),
          secondary: const Icon(
            Icons.notifications,
            color: Color(0xFF16A34A),
          ),
        ),
        SwitchListTile(
          value: SystemSettings.darkModeEnabled,
          onChanged: (value) {
            setState(() {
              SystemSettings.darkModeEnabled = value;
            });
          },
          title: const Text(
            'Dark Mode',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: const Text('Enable dark appearance'),
          secondary: const Icon(
            Icons.dark_mode,
            color: Color(0xFF16A34A),
          ),
        ),
        const SizedBox(height: 18),
        ElevatedButton.icon(
          onPressed: isSaving ? null : saveSettings,
          icon: isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: Text(isSaving ? 'Saving...' : 'Save Settings'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: const Color(0xff16A34A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  Widget settingsSlider({
    required String title,
    required String subtitle,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required String unit,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(const Color(0xffF8FAFC)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xffEAF8EE),
                child: Icon(icon, color: const Color(0xFF16A34A)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${value.round()}$unit',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).round(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class UsageHistoryPage extends StatelessWidget {
  const UsageHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SimplePage(
      title: 'Usage History',
      children: [
        Row(
          children: const [
            Expanded(child: UsageSummaryCard(title: 'Daily', value: '8.45', unit: 'kWh', color: Color(0xff0B6EF6))),
            SizedBox(width: 10),
            Expanded(child: UsageSummaryCard(title: 'Weekly', value: '52.30', unit: 'kWh', color: Colors.orange)),
          ],
        ),
        const SizedBox(height: 10),
        const UsageSummaryCard(title: 'Monthly', value: '210.80', unit: 'kWh', color: Color(0xFF16A34A)),
        const SizedBox(height: 16),
        infoTile(Icons.today, 'Daily Usage', 'Today: 8.45 kWh'),
        infoTile(Icons.calendar_view_week, 'Weekly Usage', 'This week: 52.30 kWh'),
        infoTile(Icons.calendar_month, 'Monthly Usage', 'This month: 210.80 kWh'),
        infoTile(Icons.videocam, 'Security Cameras', 'Continuous monitoring load: 0.40 kWh today'),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Usage data exported successfully')),
            );
          },
          icon: const Icon(Icons.download),
          label: const Text('Export Data'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: const Color(0xff16A34A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }
}

class UsageSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final Color color;

  const UsageSummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black54)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 26, color: color, fontWeight: FontWeight.w900)),
          Text(unit, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SimplePage(
      title: 'Help & Support',
      children: [
        infoTile(Icons.menu_book, 'User Guide', 'Use the dashboard to monitor power source, battery level and appliance status.'),
        infoTile(Icons.question_answer, 'FAQs', 'Common questions about energy monitoring, automation and reports.'),
        infoTile(Icons.phone, 'Contact Support', 'Millius N. Liswaniso\n+260 965 634 501'),
        infoTile(Icons.build, 'Troubleshooting', 'Check grid status, battery level, appliance priority and connection state.'),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: cardDecoration(const Color(0xffEAF8EE)),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Support Contact', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              SizedBox(height: 10),
              Text('For technical support, system configuration, or application-related issues, contact Millius N. Liswaniso on +260 965 634 501.'),
            ],
          ),
        ),
      ],
    );
  }
}

class AboutVoltWisePage extends StatelessWidget {
  const AboutVoltWisePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SimplePage(
      title: 'About VoltWise',
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: cardDecoration(const Color(0xffEAF8EE)),
          child: const Column(
            children: [
              CircleAvatar(
                radius: 38,
                backgroundColor: Colors.white,
                child: Icon(Icons.energy_savings_leaf, color: Color(0xFF16A34A), size: 44),
              ),
              SizedBox(height: 12),
              Text('VoltWise', style: TextStyle(fontSize: 28, color: Color(0xFF16A34A), fontWeight: FontWeight.w900)),
              Text('Smart Home Energy Management System', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        infoTile(Icons.verified, 'App Version', 'Version 1.0.0'),
        infoTile(
          Icons.info,
          'Description',
          'VoltWise is a Smart Home Energy Management System designed to monitor household energy consumption, automate appliance control, and optimize power usage during normal and backup power operation.',
        ),
        infoTile(Icons.developer_mode, 'Developer', 'Millius N. Liswaniso'),
        infoTile(Icons.copyright, 'Copyright', '© 2026 Millius N. Liswaniso'),
      ],
    );
  }
}

class SimplePage extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SimplePage({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F9FC),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            AppHeader(
              title: title,
              leftIcon: Icons.arrow_back_ios_new,
              rightIcon: Icons.energy_savings_leaf,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: cardDecoration(Colors.white),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget infoTile(IconData icon, String title, String subtitle) {
  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: const Color(0xffF8FAFC),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xffE2E8F0)),
    ),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xffEAF8EE),
        child: Icon(icon, color: const Color(0xFF16A34A)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
    ),
  );
}


BoxDecoration cardDecoration(Color color) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: const Color(0xffE2E8F0)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withAlpha(13),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
