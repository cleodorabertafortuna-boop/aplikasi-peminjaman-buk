import 'package:flutter/material.dart';

import '../../db/database_helper.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';

class MembersPage extends StatefulWidget {
  const MembersPage({super.key});

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  String _q = '';
  late Future<List<AppUser>> _f = Db.instance.members();

  void _reload() {
    setState(() {
      _f = Db.instance.members(q: _q);
    });
  }

  Future<void> _edit([AppUser? m]) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _MemberForm(member: m),
    );
    if (ok == true) {
      _reload();
      if (mounted) toast(context, m == null ? 'Anggota ditambahkan' : 'Data anggota diperbarui');
    }
  }

  Future<void> _delete(AppUser m) async {
    final ok = await confirmDialog(context,
        title: 'Hapus anggota?',
        message: '${m.name} beserta riwayat peminjamannya akan dihapus.',
        ok: 'Hapus',
        danger: true);
    if (!ok) return;
    try {
      await Db.instance.deleteMember(m.id!);
      _reload();
      if (mounted) toast(context, 'Anggota dihapus');
    } catch (e) {
      if (mounted) toast(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Anggota'), actions: const [LogoutButton()]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Tambah Anggota'),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: SearchField(
            hint: 'Cari nama, NIS, kelas…',
            onChanged: (v) {
              _q = v.trim();
              _reload();
            },
          ),
        ),
        Expanded(
          child: FutureBuilder<List<AppUser>>(
            future: _f,
            builder: (c, s) {
              if (!s.hasData) return const Center(child: CircularProgressIndicator());
              final list = s.data!;
              if (list.isEmpty) {
                return const EmptyState(
                    icon: Icons.groups_rounded,
                    title: 'Belum ada anggota',
                    subtitle: 'Tambahkan siswa dengan tombol di bawah.');
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (c, i) {
                  final m = list[i];
                  return FadeSlide(
                    index: i,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                        child: Row(children: [
                          Container(
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.yellow.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              m.name.isEmpty ? '?' : m.name[0].toUpperCase(),
                              style: const TextStyle(
                                  color: AppColors.yellow,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.name,
                                      style: const TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 3),
                                  Text('${m.kelas} • NIS ${m.nis}',
                                      style: const TextStyle(
                                          color: AppColors.muted, fontSize: 13)),
                                ]),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded, color: AppColors.muted),
                            onSelected: (v) => v == 'edit' ? _edit(m) : _delete(m),
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Ubah')),
                              PopupMenuItem(
                                  value: 'del',
                                  child: Text('Hapus',
                                      style: TextStyle(color: AppColors.red))),
                            ],
                          ),
                        ]),
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

class _MemberForm extends StatefulWidget {
  final AppUser? member;
  const _MemberForm({this.member});

  @override
  State<_MemberForm> createState() => _MemberFormState();
}

class _MemberFormState extends State<_MemberForm> {
  final _key = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.member?.name);
  final _password = TextEditingController();
  late final _kelas = TextEditingController(text: widget.member?.kelas);
  late final _nis = TextEditingController(text: widget.member?.nis);
  bool _busy = false;

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await Db.instance.saveMember(
        AppUser(
          id: widget.member?.id,
          name: _name.text.trim(),
          username: _name.text.trim(),
          kelas: _kelas.text.trim(),
          nis: _nis.text.trim(),
        ),
        password: _password.text,
      );
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
    final isNew = widget.member == null;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _key,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(isNew ? 'Tambah Anggota' : 'Ubah Anggota',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 16),
            TextFormField(
                controller: _name,
                validator: _req,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nama lengkap (username)')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextFormField(
                    controller: _kelas,
                    validator: _req,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(labelText: 'Kelas')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                    controller: _nis,
                    validator: _req,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'NIS')),
              ),
            ]),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: true,
              validator: (v) => isNew && (v == null || v.length < 4) ? 'Minimal 4 karakter' : null,
              decoration: InputDecoration(
                  labelText: isNew ? 'Password' : 'Password baru (opsional)'),
            ),
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
