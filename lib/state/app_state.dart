import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/database_helper.dart';
import '../models/models.dart';

class AppState extends ChangeNotifier {
  AppUser? user;

  Future<void> restore() async {
    final p = await SharedPreferences.getInstance();
    final id = p.getInt('uid');
    if (id != null) user = await Db.instance.userById(id);
  }

  Future<void> _set(AppUser u) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('uid', u.id!);
    user = u;
    notifyListeners();
  }

  /// Mengembalikan pesan error, atau null jika berhasil.
  Future<String?> login(String username, String password) async {
    final u = await Db.instance.login(username, password);
    if (u == null) return 'Username atau password salah';
    await _set(u);
    return null;
  }

  Future<void> register({
    required String name,
    required String password,
    required String kelas,
    required String nis,
  }) async {
    await Db.instance.saveMember(
      AppUser(name: name.trim(), username: name.trim(), kelas: kelas.trim(), nis: nis.trim()),
      password: password,
    );
    final err = await login(name, password);
    if (err != null) throw err;
  }

  Future<void> logout() async {
    final p = await SharedPreferences.getInstance();
    await p.remove('uid');
    user = null;
    notifyListeners();
  }
}
