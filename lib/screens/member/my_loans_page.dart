import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../db/database_helper.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';

class MyLoansPage extends StatefulWidget {
  const MyLoansPage({super.key});

  @override
  State<MyLoansPage> createState() => _MyLoansPageState();
}

class _MyLoansPageState extends State<MyLoansPage> {
  late Future<List<Loan>> _f = _load();

  Future<List<Loan>> _load() => Db.instance
      .loans(status: const ['requested', 'borrowed'], userId: context.read<AppState>().user!.id);

  void _reload() {
    setState(() {
      _f = _load();
    });
  }

  Future<void> _cancel(Loan l) async {
    final ok = await confirmDialog(context,
        title: 'Batalkan permintaan?',
        message: 'Permintaan untuk "${l.bookTitle}" akan dihapus.',
        ok: 'Batalkan',
        danger: true);
    if (!ok) return;
    await Db.instance.cancelRequest(l.id);
    _reload();
    if (mounted) toast(context, 'Permintaan dibatalkan');
  }

  Widget _reminder(List<Loan> urgent) {
    final late = urgent.where((l) => l.overdue).length;
    final soon = urgent.length - late;
    final parts = <String>[
      if (late > 0) '$late buku terlambat dikembalikan',
      if (soon > 0) '$soon buku jatuh tempo ≤ 2 hari',
    ];
    final color = late > 0 ? AppColors.red : AppColors.yellow;
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: const Icon(Icons.notifications_active_rounded, color: AppColors.ink),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Pengingat pengembalian',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 2),
            Text(parts.join(' • '),
                style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          ]),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pinjaman Saya'), actions: const [LogoutButton()]),
      body: FutureBuilder<List<Loan>>(
        future: _f,
        builder: (c, s) {
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          final all = s.data!;
          if (all.isEmpty) {
            return const EmptyState(
              icon: Icons.bookmark_border_rounded,
              title: 'Belum ada pinjaman',
              subtitle: 'Buka Katalog dan ajukan buku yang ingin kamu baca.',
            );
          }
          final requested = all.where((l) => l.status == 'requested').toList();
          final borrowed = all.where((l) => l.status == 'borrowed').toList();
          final urgent = borrowed.where((l) => (l.daysLeft ?? 9) <= 2).toList();
          var idx = 0;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              if (urgent.isNotEmpty) FadeSlide(child: _reminder(urgent)),
              if (borrowed.isNotEmpty) ...[
                const SectionTitle('Sedang Dipinjam'),
                for (final l in borrowed) ...[
                  FadeSlide(index: idx++, child: LoanCard(loan: l)),
                  const SizedBox(height: 12),
                ],
              ],
              if (requested.isNotEmpty) ...[
                const SizedBox(height: 6),
                const SectionTitle('Menunggu Persetujuan'),
                for (final l in requested) ...[
                  FadeSlide(
                    index: idx++,
                    child: LoanCard(
                      loan: l,
                      actions: [
                        OutlinedButton(
                            onPressed: () => _cancel(l), child: const Text('Batalkan')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}
