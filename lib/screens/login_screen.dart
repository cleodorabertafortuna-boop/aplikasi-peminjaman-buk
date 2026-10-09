import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(); // nama lengkap = username
  final _pass = TextEditingController();
  final _kelas = TextEditingController();
  final _nis = TextEditingController();
  bool _register = false, _busy = false, _hide = true;

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final app = context.read<AppState>();
    try {
      if (_register) {
        await app.register(
          name: _name.text,
          password: _pass.text,
          kelas: _kelas.text,
          nis: _nis.text,
        );
      } else {
        final err = await app.login(_name.text, _pass.text);
        if (err != null && mounted) toast(context, err, error: true);
      }
    } catch (e) {
      if (mounted) toast(context, e.toString(), error: true);
    }
    if (mounted) setState(() => _busy = false);
  }

  Widget _tab(String text, bool active, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: active ? AppColors.yellow : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(text,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: active ? AppColors.ink : AppColors.muted)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(children: [
                  FadeSlide(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFD75E), Color(0xFFFF9F1C)],
                        ),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.yellow.withValues(alpha: 0.35),
                              blurRadius: 30,
                              offset: const Offset(0, 12)),
                        ],
                      ),
                      child: const Icon(Icons.auto_stories_rounded,
                          size: 40, color: AppColors.ink),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const FadeSlide(
                    index: 1,
                    child: Text('Perpustakaan',
                        style: TextStyle(
                            fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)),
                  ),
                  const SizedBox(height: 6),
                  const FadeSlide(
                    index: 2,
                    child: Text('Pinjam buku jadi lebih mudah',
                        style: TextStyle(color: AppColors.muted, fontSize: 15)),
                  ),
                  const SizedBox(height: 30),
                  FadeSlide(
                    index: 3,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(children: [
                        _tab('Masuk', !_register, () => setState(() => _register = false)),
                        _tab('Daftar Siswa', _register, () => setState(() => _register = true)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 18),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: Column(children: [
                      TextFormField(
                        controller: _name,
                        validator: _req,
                        autocorrect: false,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                            labelText: 'Nama lengkap (username)',
                            prefixIcon: Icon(Icons.person_outline_rounded)),
                      ),
                      const SizedBox(height: 12),
                      if (_register) ...[
                        Row(children: [
                          Expanded(
                            child: TextFormField(
                              controller: _kelas,
                              validator: _req,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(labelText: 'Kelas'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _nis,
                              validator: _req,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'NIS'),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: _pass,
                        obscureText: _hide,
                        validator: (v) =>
                            (v == null || v.length < 4) ? 'Minimal 4 karakter' : null,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(_hide
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () => setState(() => _hide = !_hide),
                          ),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: AppColors.ink))
                          : Text(_register ? 'Buat Akun' : 'Masuk'),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
