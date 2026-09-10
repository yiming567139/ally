import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/providers.dart';
import 'theme/tokens.dart';
import 'pages/home_page.dart';
import 'pages/history_page.dart';
import 'pages/stats_page.dart';
import 'pages/add_fillup_sheet.dart';

void main() {
  runApp(const ProviderScope(child: YouJiApp()));
}

class YouJiApp extends StatelessWidget {
  const YouJiApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '油迹 YouJi',
      debugShowCheckedModeBanner: false,
      theme: Y.dark(),
      home: const _Shell(),
    );
  }
}

class _Shell extends ConsumerStatefulWidget {
  const _Shell();
  @override
  ConsumerState<_Shell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<_Shell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final vehicles = ref.watch(vehiclesProvider).value ?? [];
    if (vehicles.isEmpty) return const _Onboarding();

    final pages = [const HomePage(), const HistoryPage(), const StatsPage()];
    return Scaffold(
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Y.surfaceApp.withOpacity(.92),
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: Y.primary), label: '首页'),
          NavigationDestination(icon: Icon(Icons.list_alt), selectedIcon: Icon(Icons.list, color: Y.primary), label: '记录'),
          NavigationDestination(icon: Icon(Icons.show_chart), selectedIcon: Icon(Icons.show_chart, color: Y.primary), label: '统计'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Y.primary, foregroundColor: Y.onPrimary, elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onPressed: () => showAddFillUpSheet(context),
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

/// 首次使用：空状态引导 → 添加第一辆车
class _Onboarding extends ConsumerWidget {
  const _Onboarding();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(child: Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('油迹', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w600, color: Y.primary, letterSpacing: 4)),
          const SizedBox(height: 8),
          const Text('摩托车油耗记录 · 数据只在本机', style: TextStyle(color: Y.onSurface3)),
          const SizedBox(height: 48),
          const Icon(Icons.two_wheeler, size: 56, color: Y.onSurface3),
          const SizedBox(height: 24),
          const Text('先添加你的第一辆车', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('只填车型号和所加油品，然后开始记油', style: TextStyle(fontSize: 13, color: Y.onSurface3)),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, child: _AddFirstVehicleButton()),
        ]),
      ))),
    );
  }
}

class _AddFirstVehicleButton extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AddFirstVehicleButton> createState() => _AddFirstVehicleButtonState();
}

class _AddFirstVehicleButtonState extends ConsumerState<_AddFirstVehicleButton> {
  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: Y.primary, foregroundColor: Y.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: const Icon(Icons.add),
      label: const Text('添加车辆', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      onPressed: () async {
        final nameCtrl = TextEditingController();
        String grade = '95#';
        final ok = await showDialog<bool>(context: context, builder: (c) => StatefulBuilder(builder: (c, setS) => AlertDialog(
          title: const Text('添加车辆'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, autofocus: true,
                decoration: const InputDecoration(labelText: '车型号', hintText: '如：春风 450SR')),
            const SizedBox(height: 16),
            Row(children: [const Text('所加油品'), const SizedBox(width: 16),
              ...['92#', '95#', '98#'].map((g) => Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(
                label: Text(g), selected: grade == g,
                selectedColor: const Color(0x24F59E0B),
                labelStyle: TextStyle(color: grade == g ? const Color(0xFFF59E0B) : const Color(0xFFD1D5DB)),
                onSelected: (_) => setS(() => grade = g),
              )))]),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('取消')),
            FilledButton(style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: const Color(0xFF1A1207)),
                onPressed: () => Navigator.pop(c, nameCtrl.text.trim().isNotEmpty), child: const Text('保存')),
          ],
        )));
        if (ok == true) {
          final id = await ref.read(dbProvider).addVehicle(nameCtrl.text.trim(), grade);
          ref.read(activeVehicleIdProvider.notifier).state = id;
        }
      },
    );
  }
}
