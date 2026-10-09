import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../db/database_helper.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late final Future<List<Loan>> _f = Db.instance
      .loans(status: const ['returned', 'rejected'], userId: context.read<AppState>().user!.id);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat'), actions: const [LogoutButton()]),
      body: FutureBuilder<List<Loan>>(
        future: _f,
        builder: (c, s) {
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          final list = s.data!;
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.history_rounded,
              title: 'Riwayat masih kosong',
              subtitle: 'Buku yang sudah dikembalikan akan tercatat di sini.',
            );
          }
          final done = list.where((l) => l.status == 'returned').length;
          final fines = list.fold<int>(0, (a, l) => a + l.fine);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              FadeSlide(
                child: Row(children: [
                  Expanded(
                    child: SizedBox(
                      height: 112,
                      child: StatCard(
                          icon: Icons.check_circle_rounded,
                          value: '$done',
                          label: 'Buku dibaca',
                          color: AppColors.green),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 112,
                      child: StatCard(
                          icon: Icons.payments_rounded,
                          value: rupiah.format(fines),
                          label: 'Total denda',
                          color: AppColors.red),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 18),
              const SectionTitle('Semua Riwayat'),
              for (int i = 0; i < list.length; i++) ...[
                FadeSlide(index: i + 1, child: LoanCard(loan: list[i])),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}
