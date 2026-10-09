const kFinePerDay = 1000; // denda per hari keterlambatan (Rp)
const kLoanDays = 7; // lama peminjaman (hari)
const kMaxActive = 3; // maksimal buku aktif per anggota

class AppUser {
  final int? id;
  final String name, username, role, kelas, nis;

  const AppUser({
    this.id,
    required this.name,
    required this.username,
    this.role = 'member',
    this.kelas = '',
    this.nis = '',
  });

  bool get isStaff => role == 'staff';

  factory AppUser.fromMap(Map<String, Object?> m) => AppUser(
        id: m['id'] as int?,
        name: m['name'] as String,
        username: m['username'] as String,
        role: m['role'] as String,
        kelas: (m['kelas'] as String?) ?? '',
        nis: (m['nis'] as String?) ?? '',
      );
}

class Book {
  final int? id;
  final String title, author, publisher, category, shelf;
  final int stock;

  const Book({
    this.id,
    required this.title,
    required this.author,
    required this.publisher,
    required this.category,
    required this.stock,
    required this.shelf,
  });

  factory Book.fromMap(Map<String, Object?> m) => Book(
        id: m['id'] as int?,
        title: m['title'] as String,
        author: m['author'] as String,
        publisher: (m['publisher'] as String?) ?? '',
        category: m['category'] as String,
        stock: (m['stock'] as int?) ?? 0,
        shelf: (m['shelf'] as String?) ?? '',
      );

  Map<String, Object?> toMap() => {
        'title': title,
        'author': author,
        'publisher': publisher,
        'category': category,
        'stock': stock,
        'shelf': shelf,
      };
}

class Loan {
  final int id, bookId, userId;
  final String status; // requested | borrowed | returned | rejected
  final DateTime requestDate;
  final DateTime? borrowDate, dueDate, returnDate;
  final int fine;
  final String bookTitle, bookAuthor, userName, userKelas;

  const Loan({
    required this.id,
    required this.bookId,
    required this.userId,
    required this.status,
    required this.requestDate,
    this.borrowDate,
    this.dueDate,
    this.returnDate,
    this.fine = 0,
    required this.bookTitle,
    required this.bookAuthor,
    required this.userName,
    required this.userKelas,
  });

  factory Loan.fromMap(Map<String, Object?> m) {
    DateTime? p(Object? v) => v == null ? null : DateTime.parse(v as String);
    return Loan(
      id: m['id'] as int,
      bookId: m['book_id'] as int,
      userId: m['user_id'] as int,
      status: m['status'] as String,
      requestDate: DateTime.parse(m['request_date'] as String),
      borrowDate: p(m['borrow_date']),
      dueDate: p(m['due_date']),
      returnDate: p(m['return_date']),
      fine: (m['fine'] as int?) ?? 0,
      bookTitle: m['book_title'] as String,
      bookAuthor: (m['book_author'] as String?) ?? '',
      userName: m['user_name'] as String,
      userKelas: (m['user_kelas'] as String?) ?? '',
    );
  }

  /// Sisa hari sampai jatuh tempo (negatif = terlambat). Hanya untuk status borrowed.
  int? get daysLeft {
    if (status != 'borrowed' || dueDate == null) return null;
    final t = DateTime.now();
    final today = DateTime(t.year, t.month, t.day);
    final d = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return d.difference(today).inDays;
  }

  bool get overdue => (daysLeft ?? 0) < 0;
  int get lateDays => overdue ? -daysLeft! : 0;
  int get currentFine => lateDays * kFinePerDay;
}
