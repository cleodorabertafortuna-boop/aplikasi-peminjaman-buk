import 'package:flutter/material.dart';

import '../../db/database_helper.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';

class StaffBooksPage extends StatefulWidget {
  const StaffBooksPage({super.key});

  @override
  State<StaffBooksPage> createState() => _StaffBooksPageState();
}

class _StaffBooksPageState extends State<StaffBooksPage> {
  String _q = '';
  late Future<List<Book>> _f = Db.instance.getBooks();

  void _reload() {
    setState(() {
      _f = Db.instance.getBooks(q: _q);
    });
  }

  Future<void> _edit([Book? b]) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BookForm(book: b),
    );
    if (ok == true) {
      _reload();
      if (mounted) toast(context, b == null ? 'Buku ditambahkan' : 'Buku diperbarui');
    }
  }

  Future<void> _delete(Book b) async {
    final ok = await confirmDialog(context,
        title: 'Hapus buku?',
        message: '"${b.title}" beserta riwayat peminjamannya akan dihapus.',
        ok: 'Hapus',
        danger: true);
    if (!ok) return;
    try {
      await Db.instance.deleteBook(b.id!);
      _reload();
      if (mounted) toast(context, 'Buku dihapus');
    } catch (e) {
      if (mounted) toast(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Buku'), actions: const [LogoutButton()]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Buku'),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: SearchField(
            hint: 'Cari judul, pengarang, penerbit…',
            onChanged: (v) {
              _q = v.trim();
              _reload();
            },
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Book>>(
            future: _f,
            builder: (c, s) {
              if (!s.hasData) return const Center(child: CircularProgressIndicator());
              final list = s.data!;
              if (list.isEmpty) {
                return const EmptyState(
                    icon: Icons.menu_book_rounded,
                    title: 'Buku tidak ditemukan',
                    subtitle: 'Tambahkan buku baru dengan tombol di bawah.');
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (c, i) {
                  final b = list[i];
                  return FadeSlide(
                    index: i,
                    child: BookTile(
                      book: b,
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, color: AppColors.muted),
                        onSelected: (v) => v == 'edit' ? _edit(b) : _delete(b),
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Ubah')),
                          PopupMenuItem(
                              value: 'del',
                              child: Text('Hapus', style: TextStyle(color: AppColors.red))),
                        ],
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

class _BookForm extends StatefulWidget {
  final Book? book;
  const _BookForm({this.book});

  @override
  State<_BookForm> createState() => _BookFormState();
}

class _BookFormState extends State<_BookForm> {
  final _key = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.book?.title);
  late final _author = TextEditingController(text: widget.book?.author);
  late final _publisher = TextEditingController(text: widget.book?.publisher);
  late final _category = TextEditingController(text: widget.book?.category);
  late final _stock = TextEditingController(text: widget.book?.stock.toString() ?? '1');
  late final _shelf = TextEditingController(text: widget.book?.shelf);
  bool _busy = false;

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _busy = true);
    await Db.instance.saveBook(Book(
      id: widget.book?.id,
      title: _title.text.trim(),
      author: _author.text.trim(),
      publisher: _publisher.text.trim(),
      category: _category.text.trim(),
      stock: int.parse(_stock.text.trim()),
      shelf: _shelf.text.trim(),
    ));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _key,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(widget.book == null ? 'Tambah Buku' : 'Ubah Buku',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 16),
            TextFormField(
                controller: _title,
                validator: _req,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Judul')),
            const SizedBox(height: 12),
            TextFormField(
                controller: _author,
                validator: _req,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Pengarang')),
            const SizedBox(height: 12),
            TextFormField(
                controller: _publisher,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Penerbit')),
            const SizedBox(height: 12),
            TextFormField(
                controller: _category,
                validator: _req,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Kategori')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _stock,
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      (int.tryParse((v ?? '').trim()) ?? -1) < 0 ? 'Angka ≥ 0' : null,
                  decoration: const InputDecoration(labelText: 'Stok'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _shelf,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Rak'),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy ? null : _save,
                child: const Text('Simpan'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
