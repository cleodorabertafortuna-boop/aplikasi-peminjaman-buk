import 'package:flutter/material.dart';

import '../../db/database_helper.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';

class CirculationPage extends StatefulWidget {
  const CirculationPage({super.key});

  @override
  State<CirculationPage> createState() => _CirculationPageState();
}

class _CirculationPageState extends State<CirculationPage> {
  int _v = 0;
  void _bump() => setState(() => _v++);

  Future<void> _newLoan() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _NewLoanSheet(),
    );
    if (ok == true) {
      _bump();
      if (mounted) toast(context, 'Peminjaman dicatat');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sirkulasi'),
          actions: const [LogoutButton()],
          bottom: const TabBar(
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [Tab(text: 'Permintaan'), Tab(text: 'Dipinjam'), Tab(text: 'Selesai')],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _newLoan,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Pinjam Baru'),
        ),
        body: TabBarView(children: [
          _LoanList(key: ValueKey('r$_v'), statuses: const ['requested'], onChanged: _bump),
          _LoanList(key: ValueKey('b$_v'), statuses: const ['borrowed'], onChanged: _bump),
          _LoanList(
              key: ValueKey('d$_v'),
              statuses: const ['returned', 'rejected'],
              onChanged: _bump),
        ]),
      ),
    );
  }
}

class _LoanList extends StatefulWidget {
  final List<String> statuses;
  final VoidCallback onChanged;
  const _LoanList({super.key, required this.statuses, required this.onChanged});

  @override
  State<_LoanList> createState() => _LoanListState();
}

class _LoanListState extends State<_LoanList> {
  late final Future<List<Loan>> _f = Db.instance.loans(status: widget.statuses);

  Future<void> _run(Future<String?> Function() job) async {
    try {
      final msg = await job();
      if (!mounted) return;
      if (msg != null) toast(context, msg);
      widget.onChanged();
    } catch (e) {
      if (mounted) toast(context, e.toString(), error: true);
    }
  }

  Future<void> _return(Loan l) async {
    final fine = l.currentFine;
    final ok = await confirmDialog(
      context,
      title: 'Terima pengembalian?',
      message: fine > 0
          ? '"${l.bookTitle}" terlambat ${l.lateDays} hari.\nDenda: ${rupiah.format(fine)} (${rupiah.format(kFinePerDay)}/hari).'
          : '"${l.bookTitle}" dikembalikan tepat waktu. Tidak ada denda.',
      ok: 'Terima',
    );
    if (!ok) return;
    await _run(() async {
      final f = await Db.instance.returnLoan(l.id);
      return f > 0 ? 'Dikembalikan • Denda ${rupiah.format(f)}' : 'Buku dikembalikan';
    });
  }

  List<Widget>? _actions(Loan l) {
    switch (l.status) {
      case 'requested':
        return [
          OutlinedButton(
            onPressed: () => _run(() async {
              await Db.instance.rejectLoan(l.id);
              return 'Permintaan ditolak';
            }),
            child: const Text('Tolak'),
          ),
          FilledButton(
            onPressed: () => _run(() async {
              await Db.instance.approveLoan(l.id);
              return 'Disetujui • jatuh tempo $kLoanDays hari lagi';
            }),
            child: const Text('Setujui'),
          ),
        ];
      case 'borrowed':
        return [
          FilledButton.icon(
            onPressed: () => _return(l),
            icon: const Icon(Icons.assignment_return_rounded, size: 20),
            label: Text(l.overdue ? 'Kembalikan + denda' : 'Kembalikan'),
          ),
        ];
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Loan>>(
      future: _f,
      builder: (c, s) {
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final list = s.data!;
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.inbox_rounded,
            title: 'Belum ada data',
            subtitle: 'Transaksi akan muncul di sini.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (c, i) => FadeSlide(
            index: i,
            child: LoanCard(loan: list[i], showUser: true, actions: _actions(list[i])),
          ),
        );
      },
    );
  }
}

class _NewLoanSheet extends StatefulWidget {
  const _NewLoanSheet();

  @override
  State<_NewLoanSheet> createState() => _NewLoanSheetState();
}

class _NewLoanSheetState extends State<_NewLoanSheet> {
  late final Future<(List<AppUser>, List<Book>)> _f = _load();
  int? _member, _book;
  bool _busy = false;

  Future<(List<AppUser>, List<Book>)> _load() async {
    final m = await Db.instance.members();
    final b = (await Db.instance.getBooks()).where((e) => e.stock > 0).toList();
    return (m, b);
  }

  Future<void> _save() async {
    if (_member == null || _book == null) {
      toast(context, 'Pilih anggota dan buku', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await Db.instance.directBorrow(_member!, _book!);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        toast(context, e.toString(), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: FutureBuilder<(List<AppUser>, List<Book>)>(
        future: _f,
        builder: (c, s) {
          if (!s.hasData) {
            return const SizedBox(
                height: 160, child: Center(child: CircularProgressIndicator()));
          }
          final (members, books) = s.data!;
          return Column(mainAxisSize: MainAxisSize.min, children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Peminjaman Baru',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Lama pinjam $kLoanDays hari • denda ${rupiah.format(kFinePerDay)}/hari',
                  style: const TextStyle(color: AppColors.muted)),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              isExpanded: true,
              dropdownColor: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              decoration: const InputDecoration(labelText: 'Anggota'),
              items: [
                for (final m in members)
                  DropdownMenuItem(
                      value: m.id,
                      child: Text('${m.name} • ${m.kelas}', overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => _member = v,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              isExpanded: true,
              dropdownColor: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              decoration: const InputDecoration(labelText: 'Buku (stok tersedia)'),
              items: [
                for (final b in books)
                  DropdownMenuItem(
                      value: b.id,
                      child: Text('${b.title} (${b.stock})', overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => _book = v,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy ? null : _save,
                child: const Text('Proses Peminjaman'),
              ),
            ),
          ]);
        },
      ),
    );
  }
}
