import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../db/database_helper.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';

class _ReportData {
  final Map<String, int> stats;
  final List<Map<String, Object?>> monthly, top;
  _ReportData(this.stats, this.monthly, this.top);
}

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  late final Future<_ReportData> _f = _load();

  Future<_ReportData> _load() async => _ReportData(
        await Db.instance.stats(),
        await Db.instance.monthlyLoans(),
        await Db.instance.topBooks(),
      );

  String _month(String ym) {
    final p = ym.split('-');
    return DateFormat('MMM', 'id_ID').format(DateTime(int.parse(p[0]), int.parse(p[1])));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan'), actions: const [LogoutButton()]),
      body: FutureBuilder<_ReportData>(
        future: _f,
        builder: (c, s) {
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          final d = s.data!;
          final st = d.stats;
          final cards = [
            StatCard(
                icon: Icons.menu_book_rounded,
                value: '${st['titles']}',
                label: 'Judul • ${st['stock']} eksemplar tersedia'),
            StatCard(
                icon: Icons.groups_rounded,
                value: '${st['members']}',
                label: 'Anggota terdaftar',
                color: AppColors.blue),
            StatCard(
                icon: Icons.auto_stories_rounded,
                value: '${st['borrowed']}',
                label: 'Sedang dipinjam'),
            StatCard(
                icon: Icons.warning_amber_rounded,
                value: '${st['overdue']}',
                label: 'Terlambat',
                color: AppColors.red),
            StatCard(
                icon: Icons.check_circle_rounded,
                value: '${st['returned']}',
                label: 'Selesai dikembalikan',
                color: AppColors.green),
            StatCard(
                icon: Icons.payments_rounded,
                value: rupiah.format(st['fines']),
                label: 'Total denda',
                color: AppColors.red),
          ];
          final maxMonth = d.monthly.fold<int>(1, (m, e) => (e['c'] as int) > m ? e['c'] as int : m);
          final maxTop = d.top.isEmpty ? 1 : d.top.first['c'] as int;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              FadeSlide(
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: cards,
                ),
              ),
              const SizedBox(height: 22),
              const SectionTitle('Peminjaman per Bulan'),
              FadeSlide(
                index: 2,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
                    child: d.monthly.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                                child: Text('Belum ada data',
                                    style: TextStyle(color: AppColors.muted))))
                        : SizedBox(
                            height: 170,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                for (int i = 0; i < d.monthly.length; i++)
                                  Expanded(
                                    child: _Bar(
                                      value: d.monthly[i]['c'] as int,
                                      max: maxMonth,
                                      label: _month(d.monthly[i]['ym'] as String),
                                      highlight: i == d.monthly.length - 1,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const SectionTitle('Buku Terfavorit'),
              if (d.top.isEmpty)
                const EmptyState(icon: Icons.star_rounded, title: 'Belum ada data peminjaman')
              else
                for (int i = 0; i < d.top.length; i++) ...[
                  FadeSlide(
                    index: i + 3,
                    child: _TopRow(
                      rank: i + 1,
                      title: d.top[i]['title'] as String,
                      author: d.top[i]['author'] as String,
                      category: d.top[i]['category'] as String,
                      count: d.top[i]['c'] as int,
                      max: maxTop,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final int value, max;
  final String label;
  final bool highlight;
  const _Bar({required this.value, required this.max, required this.label, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
      Text('$value', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
      const SizedBox(height: 6),
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value / max),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (c, v, _) => Container(
          width: 26,
          height: 110 * v + 6,
          decoration: BoxDecoration(
            color: highlight ? AppColors.yellow : AppColors.line,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
    ]);
  }
}

class _TopRow extends StatelessWidget {
  final int rank, count, max;
  final String title, author, category;
  const _TopRow({
    required this.rank,
    required this.title,
    required this.author,
    required this.category,
    required this.count,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    final first = rank == 1;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: first ? AppColors.yellow : AppColors.line,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text('$rank',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: first ? AppColors.ink : AppColors.text)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              Text('$author • $category',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
              const SizedBox(height: 8),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: count / max),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (c, v, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: v,
                    minHeight: 6,
                    backgroundColor: AppColors.line,
                    color: first ? AppColors.yellow : AppColors.muted,
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(width: 14),
          Text('${count}x',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        ]),
      ),
    );
  }
}
