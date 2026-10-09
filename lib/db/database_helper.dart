import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/models.dart';

class Db {
  Db._();
  static final Db instance = Db._();

  Database? _db;
  Future<Database> get db async => _db ??= await _open();

  static String hash(String s) => sha256.convert(utf8.encode(s)).toString();

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'perpustakaan.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (d, v) async {
        await d.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            username TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL,
            role TEXT NOT NULL,
            kelas TEXT,
            nis TEXT
          )''');
        await d.execute('''
          CREATE TABLE books(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            author TEXT NOT NULL,
            publisher TEXT,
            category TEXT NOT NULL,
            stock INTEGER NOT NULL DEFAULT 0,
            shelf TEXT
          )''');
        await d.execute('''
          CREATE TABLE loans(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            book_id INTEGER NOT NULL,
            user_id INTEGER NOT NULL,
            status TEXT NOT NULL,
            request_date TEXT NOT NULL,
            borrow_date TEXT,
            due_date TEXT,
            return_date TEXT,
            fine INTEGER NOT NULL DEFAULT 0
          )''');
        await _seed(d);
      },
    );
  }

  Future<void> _seed(Database d) async {
    Future<int> user(String n, String u, String p, String role, String k, String nis) =>
        d.insert('users', {
          'name': n,
          'username': u,
          'password': hash(p),
          'role': role,
          'kelas': k,
          'nis': nis,
        });

    await user('Petugas Perpustakaan', 'petugas', 'petugas123', 'staff', '', '');
    final s1 = await user('Aisyah Putri', 'siswa', 'siswa123', 'member', 'XI IPA 2', '2024001');
    final s2 = await user('Raka Pratama', 'raka', 'raka123', 'member', 'X IPS 1', '2024002');

    const books = [
      ['Laskar Pelangi', 'Andrea Hirata', 'Bentang Pustaka', 'Novel', 4, 'A1'],
      ['Bumi Manusia', 'Pramoedya Ananta Toer', 'Lentera Dipantara', 'Novel', 3, 'A2'],
      ['Atomic Habits', 'James Clear', 'Gramedia', 'Pengembangan Diri', 5, 'B1'],
      ['Sapiens', 'Yuval Noah Harari', 'KPG', 'Sejarah', 2, 'C1'],
      ['Matematika Kelas XI', 'Kemendikbud', 'Pusat Perbukuan', 'Pelajaran', 8, 'D1'],
      ['Fisika Dasar', 'Halliday', 'Erlangga', 'Sains', 3, 'D2'],
      ['Filosofi Teras', 'Henry Manampiring', 'Kompas', 'Pengembangan Diri', 4, 'B2'],
      ['Dilan 1990', 'Pidi Baiq', 'Pastel Books', 'Novel', 3, 'A3'],
      ['Cantik Itu Luka', 'Eka Kurniawan', 'Gramedia', 'Novel', 2, 'A4'],
      ['Ensiklopedia Sains Anak', 'Tim Ensiklopedia', 'Mizan', 'Sains', 2, 'D3'],
    ];
    final ids = <int>[];
    for (final b in books) {
      ids.add(await d.insert('books', {
        'title': b[0],
        'author': b[1],
        'publisher': b[2],
        'category': b[3],
        'stock': b[4],
        'shelf': b[5],
      }));
    }

    final t = _today();
    String ago(int days) => t.subtract(Duration(days: days)).toIso8601String();

    // Riwayat contoh supaya laporan & buku terfavorit langsung terisi.
    await d.insert('loans', {
      'book_id': ids[0], 'user_id': s2, 'status': 'returned',
      'request_date': ago(20), 'borrow_date': ago(20), 'due_date': ago(13),
      'return_date': ago(15), 'fine': 0,
    });
    await d.insert('loans', {
      'book_id': ids[0], 'user_id': s1, 'status': 'returned',
      'request_date': ago(30), 'borrow_date': ago(30), 'due_date': ago(23),
      'return_date': ago(20), 'fine': 3 * kFinePerDay,
    });
    await d.insert('loans', {
      'book_id': ids[1], 'user_id': s1, 'status': 'returned',
      'request_date': ago(12), 'borrow_date': ago(12), 'due_date': ago(5),
      'return_date': ago(6), 'fine': 0,
    });
    // Pinjaman aktif yang sudah terlambat 3 hari.
    await d.insert('loans', {
      'book_id': ids[2], 'user_id': s2, 'status': 'borrowed',
      'request_date': ago(10), 'borrow_date': ago(10), 'due_date': ago(3),
      'fine': 0,
    });
    await d.rawUpdate('UPDATE books SET stock = stock - 1 WHERE id = ?', [ids[2]]);
  }

  // ───────────────────────── Auth & anggota ─────────────────────────

  Future<AppUser?> login(String username, String password) async {
    final d = await db;
    final r = await d.query('users',
        where: '(LOWER(username) = LOWER(?) OR LOWER(name) = LOWER(?)) AND password = ?',
        whereArgs: [username.trim(), username.trim(), hash(password)]);
    return r.isEmpty ? null : AppUser.fromMap(r.first);
  }

  Future<AppUser?> userById(int id) async {
    final d = await db;
    final r = await d.query('users', where: 'id = ?', whereArgs: [id]);
    return r.isEmpty ? null : AppUser.fromMap(r.first);
  }

  Future<List<AppUser>> members({String q = ''}) async {
    final d = await db;
    final r = await d.query(
      'users',
      where: q.isEmpty
          ? "role = 'member'"
          : "role = 'member' AND (name LIKE ? OR nis LIKE ? OR username LIKE ? OR kelas LIKE ?)",
      whereArgs: q.isEmpty ? null : List.filled(4, '%$q%'),
      orderBy: 'name COLLATE NOCASE',
    );
    return r.map(AppUser.fromMap).toList();
  }

  Future<void> saveMember(AppUser m, {String? password}) async {
    final d = await db;
    final dup = Sqflite.firstIntValue(await d.rawQuery(
        'SELECT COUNT(*) FROM users WHERE LOWER(username) = LOWER(?) AND id != ?',
        [m.name.trim(), m.id ?? -1]));
    if ((dup ?? 0) > 0) throw 'Nama sudah terdaftar';
    // Nama lengkap sekaligus dipakai sebagai username.
    final map = <String, Object?>{
      'name': m.name.trim(),
      'username': m.name.trim(),
      'kelas': m.kelas,
      'nis': m.nis,
      'role': 'member',
    };
    try {
      if (m.id == null) {
        map['password'] = hash((password == null || password.isEmpty) ? m.nis : password);
        await d.insert('users', map);
      } else {
        if (password != null && password.isNotEmpty) map['password'] = hash(password);
        await d.update('users', map, where: 'id = ?', whereArgs: [m.id]);
      }
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) throw 'Nama sudah terdaftar';
      rethrow;
    }
  }

  Future<void> deleteMember(int id) async {
    final d = await db;
    final active = Sqflite.firstIntValue(await d.rawQuery(
        "SELECT COUNT(*) FROM loans WHERE user_id = ? AND status IN ('requested','borrowed')",
        [id]));
    if ((active ?? 0) > 0) throw 'Anggota masih memiliki pinjaman aktif';
    await d.delete('loans', where: 'user_id = ?', whereArgs: [id]);
    await d.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // ───────────────────────────── Buku ─────────────────────────────

  Future<List<Book>> getBooks({String q = '', String? category}) async {
    final d = await db;
    final where = <String>[];
    final args = <Object?>[];
    if (q.isNotEmpty) {
      where.add('(title LIKE ? OR author LIKE ? OR publisher LIKE ?)');
      args.addAll(['%$q%', '%$q%', '%$q%']);
    }
    if (category != null) {
      where.add('category = ?');
      args.add(category);
    }
    final r = await d.query('books',
        where: where.isEmpty ? null : where.join(' AND '),
        whereArgs: args.isEmpty ? null : args,
        orderBy: 'title COLLATE NOCASE');
    return r.map(Book.fromMap).toList();
  }

  Future<List<String>> categories() async {
    final d = await db;
    final r = await d.rawQuery('SELECT DISTINCT category FROM books ORDER BY category');
    return r.map((e) => e['category'] as String).toList();
  }

  Future<void> saveBook(Book b) async {
    final d = await db;
    if (b.id == null) {
      await d.insert('books', b.toMap());
    } else {
      await d.update('books', b.toMap(), where: 'id = ?', whereArgs: [b.id]);
    }
  }

  Future<void> deleteBook(int id) async {
    final d = await db;
    final active = Sqflite.firstIntValue(await d.rawQuery(
        "SELECT COUNT(*) FROM loans WHERE book_id = ? AND status IN ('requested','borrowed')",
        [id]));
    if ((active ?? 0) > 0) throw 'Buku masih dipinjam / diminta anggota';
    await d.delete('loans', where: 'book_id = ?', whereArgs: [id]);
    await d.delete('books', where: 'id = ?', whereArgs: [id]);
  }

  // ─────────────────────────── Sirkulasi ───────────────────────────

  static const _loanSql = '''
    SELECT l.*, b.title AS book_title, b.author AS book_author,
           u.name AS user_name, u.kelas AS user_kelas
    FROM loans l
    JOIN books b ON b.id = l.book_id
    JOIN users u ON u.id = l.user_id''';

  Future<List<Loan>> loans({List<String>? status, int? userId}) async {
    final d = await db;
    final where = <String>[];
    final args = <Object?>[];
    if (status != null) {
      where.add('l.status IN (${List.filled(status.length, '?').join(',')})');
      args.addAll(status);
    }
    if (userId != null) {
      where.add('l.user_id = ?');
      args.add(userId);
    }
    final sql = '$_loanSql ${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'} ORDER BY l.id DESC';
    final r = await d.rawQuery(sql, args);
    return r.map(Loan.fromMap).toList();
  }

  /// Anggota mengajukan peminjaman / pemesanan buku.
  Future<int> requestLoan(int userId, int bookId) async {
    final d = await db;
    return d.transaction<int>((t) async {
      final b = await t.query('books', where: 'id = ?', whereArgs: [bookId]);
      if (b.isEmpty) throw 'Buku tidak ditemukan';
      if ((b.first['stock'] as int) <= 0) throw 'Stok buku habis';
      final dup = Sqflite.firstIntValue(await t.rawQuery(
          "SELECT COUNT(*) FROM loans WHERE user_id = ? AND book_id = ? AND status IN ('requested','borrowed')",
          [userId, bookId]));
      if ((dup ?? 0) > 0) throw 'Kamu sudah mengajukan / meminjam buku ini';
      final active = Sqflite.firstIntValue(await t.rawQuery(
          "SELECT COUNT(*) FROM loans WHERE user_id = ? AND status IN ('requested','borrowed')",
          [userId]));
      if ((active ?? 0) >= kMaxActive) throw 'Maksimal $kMaxActive buku sekaligus';
      return t.insert('loans', {
        'book_id': bookId,
        'user_id': userId,
        'status': 'requested',
        'request_date': DateTime.now().toIso8601String(),
        'fine': 0,
      });
    });
  }

  Future<void> cancelRequest(int loanId) async {
    final d = await db;
    await d.delete('loans', where: "id = ? AND status = 'requested'", whereArgs: [loanId]);
  }

  /// Petugas menyetujui permintaan → transaksi pinjam (stok berkurang).
  Future<void> approveLoan(int loanId) async {
    final d = await db;
    await d.transaction((t) async {
      final l = await t.query('loans', where: 'id = ?', whereArgs: [loanId]);
      if (l.isEmpty || l.first['status'] != 'requested') throw 'Permintaan tidak valid';
      final bookId = l.first['book_id'] as int;
      final b = await t.query('books', where: 'id = ?', whereArgs: [bookId]);
      if (b.isEmpty || (b.first['stock'] as int) <= 0) throw 'Stok buku habis';
      await t.rawUpdate('UPDATE books SET stock = stock - 1 WHERE id = ?', [bookId]);
      final today = _today();
      await t.update(
        'loans',
        {
          'status': 'borrowed',
          'borrow_date': DateTime.now().toIso8601String(),
          'due_date': today.add(const Duration(days: kLoanDays)).toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [loanId],
      );
    });
  }

  Future<void> rejectLoan(int loanId) async {
    final d = await db;
    await d.update(
      'loans',
      {'status': 'rejected', 'return_date': DateTime.now().toIso8601String()},
      where: "id = ? AND status = 'requested'",
      whereArgs: [loanId],
    );
  }

  /// Petugas mencatat peminjaman langsung di meja.
  Future<void> directBorrow(int userId, int bookId) async {
    final id = await requestLoan(userId, bookId);
    await approveLoan(id);
  }

  /// Pengembalian buku. Mengembalikan jumlah denda (Rp) yang dihitung otomatis.
  Future<int> returnLoan(int loanId) async {
    final d = await db;
    return d.transaction<int>((t) async {
      final l = await t.query('loans', where: 'id = ?', whereArgs: [loanId]);
      if (l.isEmpty || l.first['status'] != 'borrowed') throw 'Transaksi tidak valid';
      final due = DateTime.parse(l.first['due_date'] as String);
      final dueDay = DateTime(due.year, due.month, due.day);
      final late = _today().difference(dueDay).inDays;
      final fine = late > 0 ? late * kFinePerDay : 0;
      await t.update(
        'loans',
        {
          'status': 'returned',
          'return_date': DateTime.now().toIso8601String(),
          'fine': fine,
        },
        where: 'id = ?',
        whereArgs: [loanId],
      );
      await t.rawUpdate('UPDATE books SET stock = stock + 1 WHERE id = ?', [l.first['book_id']]);
      return fine;
    });
  }

  // ───────────────────────────── Laporan ─────────────────────────────

  Future<Map<String, int>> stats() async {
    final d = await db;
    Future<int> one(String sql, [List<Object?>? a]) async =>
        Sqflite.firstIntValue(await d.rawQuery(sql, a)) ?? 0;
    return {
      'titles': await one('SELECT COUNT(*) FROM books'),
      'stock': await one('SELECT COALESCE(SUM(stock),0) FROM books'),
      'members': await one("SELECT COUNT(*) FROM users WHERE role = 'member'"),
      'borrowed': await one("SELECT COUNT(*) FROM loans WHERE status = 'borrowed'"),
      'requested': await one("SELECT COUNT(*) FROM loans WHERE status = 'requested'"),
      'overdue': await one(
          "SELECT COUNT(*) FROM loans WHERE status = 'borrowed' AND due_date < ?",
          [_today().toIso8601String()]),
      'returned': await one("SELECT COUNT(*) FROM loans WHERE status = 'returned'"),
      'fines': await one('SELECT COALESCE(SUM(fine),0) FROM loans'),
    };
  }

  Future<List<Map<String, Object?>>> monthlyLoans() async {
    final d = await db;
    final r = await d.rawQuery('''
      SELECT substr(COALESCE(borrow_date, request_date), 1, 7) AS ym, COUNT(*) AS c
      FROM loans WHERE status IN ('borrowed','returned')
      GROUP BY ym ORDER BY ym DESC LIMIT 6''');
    return r.reversed.toList();
  }

  Future<List<Map<String, Object?>>> topBooks({int limit = 5}) async {
    final d = await db;
    return d.rawQuery('''
      SELECT b.title AS title, b.author AS author, b.category AS category, COUNT(*) AS c
      FROM loans l JOIN books b ON b.id = l.book_id
      WHERE l.status IN ('borrowed','returned')
      GROUP BY b.id ORDER BY c DESC, b.title LIMIT ?''', [limit]);
  }
}
