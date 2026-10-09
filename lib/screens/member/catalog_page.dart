import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../db/database_helper.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  String _q = '';
  String? _cat;
  late Future<List<Book>> _books = Db.instance.getBooks();
  late final Future<List<String>> _cats = Db.instance.categories();

  void _reload() {
    setState(() {
      _books = Db.instance.getBooks(q: _q, category: _cat);
    });
  }

  Future<void> _request(Book b) async {
    final uid = context.read<AppState>().user!.id!;
    final ok = await confirmDialog(
      context,
      title: 'Ajukan peminjaman?',
      message:
          '"${b.title}"\nLama pinjam $kLoanDays hari. Denda keterlambatan ${rupiah.format(kFinePerDay)}/hari. Ambil bukunya di petugas setelah permintaan disetujui.',
      ok: 'Ajukan',
    );
    if (!ok) return;
    try {
      await Db.instance.requestLoan(uid, b.id!);
      if (mounted) toast(context, 'Permintaan terkirim, tunggu persetujuan petugas');
    } catch (e) {
      if (mounted) toast(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user!;
    final first = user.name.split(' ').first;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Halo, $first',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.muted)),
          const Text('Cari buku'),
        ]),
        actions: const [LogoutButton()],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: SearchField(
            hint: 'Judul, pengarang, penerbit…',
            onChanged: (v) {
              _q = v.trim();
              _reload();
            },
          ),
        ),
        SizedBox(
          height: 44,
          child: FutureBuilder<List<String>>(
            future: _cats,
            builder: (c, s) {
              final cats = ['Semua', ...?s.data];
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: cats.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (c, i) {
                  final selected = i == 0 ? _cat == null : _cat == cats[i];
                  return ChoiceChip(
                    label: Text(cats[i]),
                    selected: selected,
                    labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: selected ? AppColors.ink : AppColors.text),
                    onSelected: (_) {
                      _cat = i == 0 ? null : cats[i];
                      _reload();
                    },
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: FutureBuilder<List<Book>>(
            future: _books,
            builder: (c, s) {
              if (!s.hasData) return const Center(child: CircularProgressIndicator());
              final list = s.data!;
              if (list.isEmpty) {
                return const EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'Buku tidak ditemukan',
                    subtitle: 'Coba kata kunci atau kategori lain.');
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (c, i) {
                  final b = list[i];
                  return FadeSlide(
                    index: i,
                    child: BookTile(
                      book: b,
                      trailing: FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onPressed: b.stock > 0 ? () => _request(b) : null,
                        child: Text(b.stock > 0 ? 'Pinjam' : 'Habis'),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}
