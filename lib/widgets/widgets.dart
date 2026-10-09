import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

final rupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
String fmtDate(DateTime d) => DateFormat('d MMM yyyy', 'id_ID').format(d);

void toast(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        Icon(error ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            color: error ? AppColors.red : AppColors.yellow, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(msg)),
      ]),
    ));
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String ok = 'Ya',
  bool danger = false,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(message, style: const TextStyle(color: AppColors.muted, height: 1.4)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: const Text('Batal', style: TextStyle(color: AppColors.muted)),
        ),
        FilledButton(
          style: danger
              ? FilledButton.styleFrom(
                  backgroundColor: AppColors.red, foregroundColor: Colors.white)
              : null,
          onPressed: () => Navigator.pop(c, true),
          child: Text(ok),
        ),
      ],
    ),
  );
  return r ?? false;
}

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: 'Keluar',
        icon: const Icon(Icons.logout_rounded),
        onPressed: () async {
          final app = context.read<AppState>();
          final ok = await confirmDialog(context,
              title: 'Keluar?', message: 'Kamu akan keluar dari akun ini.', ok: 'Keluar');
          if (ok) app.logout();
        },
      );
}

class SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const SearchField({super.key, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) => TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search_rounded),
        ),
      );
}

/// Animasi masuk (fade + geser) berjenjang untuk item list.
class FadeSlide extends StatelessWidget {
  final Widget child;
  final int index;
  const FadeSlide({super.key, required this.child, this.index = 0});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 380 + index.clamp(0, 8) * 70),
        curve: Curves.easeOutCubic,
        builder: (c, v, ch) => Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, (1 - v) * 20), child: ch),
        ),
        child: child,
      );
}

class BookCover extends StatelessWidget {
  final String title, category;
  final double width, height;
  const BookCover({
    super.key,
    required this.title,
    required this.category,
    this.width = 56,
    this.height = 78,
  });

  static const _palettes = [
    [Color(0xFFFFC82C), Color(0xFFFF9F1C)],
    [Color(0xFF8E9AAF), Color(0xFF55607A)],
    [Color(0xFFF4A261), Color(0xFFE76F51)],
    [Color(0xFF9CD3B0), Color(0xFF4F9D7A)],
    [Color(0xFFB8A1E3), Color(0xFF7A5CC0)],
    [Color(0xFF7DD3FC), Color(0xFF3B82B6)],
  ];

  @override
  Widget build(BuildContext context) {
    final sum = category.codeUnits.fold<int>(0, (a, b) => a + b);
    final p = _palettes[sum % _palettes.length];
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: p,
          ),
        ),
        child: Stack(children: [
          Positioned(
            left: width * 0.14,
            top: 0,
            bottom: 0,
            child: Container(width: 3, color: Colors.black.withValues(alpha: 0.13)),
          ),
          Center(
            child: Text(
              title.isEmpty ? '?' : title[0].toUpperCase(),
              style: TextStyle(
                fontSize: width * 0.44,
                fontWeight: FontWeight.w900,
                color: AppColors.ink.withValues(alpha: 0.78),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class Pill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  const Pill(this.text, {super.key, this.color = AppColors.muted, this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(text,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      );
}

class StatusChip extends StatelessWidget {
  final Loan loan;
  const StatusChip(this.loan, {super.key});

  @override
  Widget build(BuildContext context) {
    switch (loan.status) {
      case 'requested':
        return const Pill('Menunggu', color: AppColors.yellow);
      case 'borrowed':
        return loan.overdue
            ? const Pill('Terlambat', color: AppColors.red)
            : const Pill('Dipinjam', color: AppColors.blue);
      case 'returned':
        return const Pill('Dikembalikan', color: AppColors.green);
      default:
        return const Pill('Ditolak', color: AppColors.red);
    }
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const EmptyState({super.key, required this.icon, required this.title, this.subtitle = ''});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.yellow.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 38, color: AppColors.yellow),
            ),
            const SizedBox(height: 18),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, height: 1.4)),
            ],
          ]),
        ),
      );
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.color = AppColors.yellow,
  });

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(value,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                ),
                Text(label,
                    style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
              ]),
            ],
          ),
        ),
      );
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
        child: Row(children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
                color: AppColors.yellow, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ),
          if (trailing != null) trailing!,
        ]),
      );
}

/// Kartu buku dipakai di sisi petugas (kelola) maupun anggota (katalog).
class BookTile extends StatelessWidget {
  final Book book;
  final Widget? trailing;
  final bool showShelf;
  const BookTile({super.key, required this.book, this.trailing, this.showShelf = true});

  @override
  Widget build(BuildContext context) {
    final out = book.stock <= 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          BookCover(title: book.title, category: book.category),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, height: 1.2)),
              const SizedBox(height: 3),
              Text(
                book.publisher.isEmpty ? book.author : '${book.author} • ${book.publisher}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 6, children: [
                Pill(book.category, color: AppColors.blue),
                if (showShelf && book.shelf.isNotEmpty)
                  Pill('Rak ${book.shelf}', icon: Icons.shelves),
                Pill(out ? 'Stok habis' : 'Stok ${book.stock}',
                    color: out ? AppColors.red : AppColors.green),
              ]),
            ]),
          ),
          if (trailing != null) ...[const SizedBox(width: 6), trailing!],
        ]),
      ),
    );
  }
}

/// Kartu transaksi pinjam, dipakai petugas & anggota.
class LoanCard extends StatelessWidget {
  final Loan loan;
  final bool showUser;
  final List<Widget>? actions;
  const LoanCard({super.key, required this.loan, this.showUser = false, this.actions});

  Widget? _duePill() {
    final dl = loan.daysLeft;
    if (dl == null) return null;
    if (dl < 0) {
      return Pill('Terlambat ${loan.lateDays} hari • ${rupiah.format(loan.currentFine)}',
          color: AppColors.red, icon: Icons.warning_amber_rounded);
    }
    if (dl == 0) {
      return const Pill('Jatuh tempo hari ini',
          color: AppColors.yellow, icon: Icons.schedule_rounded);
    }
    return Pill('Sisa $dl hari',
        color: dl <= 2 ? AppColors.yellow : AppColors.green, icon: Icons.schedule_rounded);
  }

  @override
  Widget build(BuildContext context) {
    final due = _duePill();
    final dateLine = switch (loan.status) {
      'requested' => 'Diajukan ${fmtDate(loan.requestDate)}',
      'borrowed' =>
        'Pinjam ${fmtDate(loan.borrowDate ?? loan.requestDate)} • Tempo ${fmtDate(loan.dueDate!)}',
      'returned' =>
        '${fmtDate(loan.borrowDate ?? loan.requestDate)} – ${fmtDate(loan.returnDate!)}',
      _ => 'Diajukan ${fmtDate(loan.requestDate)}',
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            BookCover(title: loan.bookTitle, category: loan.bookAuthor, width: 44, height: 62),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(loan.bookTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(
                  showUser
                      ? '${loan.userName}${loan.userKelas.isEmpty ? '' : ' • ${loan.userKelas}'}'
                      : loan.bookAuthor,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(dateLine, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
              ]),
            ),
            const SizedBox(width: 8),
            StatusChip(loan),
          ]),
          if (due != null) ...[const SizedBox(height: 12), due],
          if (loan.status == 'returned' && loan.fine > 0) ...[
            const SizedBox(height: 12),
            Pill('Denda ${rupiah.format(loan.fine)}',
                color: AppColors.red, icon: Icons.payments_outlined),
          ],
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                for (int i = 0; i < actions!.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(child: actions![i]),
                ],
              ],
            ),
          ],
        ]),
      ),
    );
  }
}
