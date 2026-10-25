import 'package:pm_p4_4243250006/model.dart';
import 'package:pm_p4_4243250006/perpustakaan.dart';

Future<void> main() async {
  print('==========================================');
  print('       SISTEM PERPUSTAKAAN FMIPA');
  print('==========================================');

  final perpus = Perpustakaan('Perpustakaan FMIPA');

  // Listener untuk menampilkan log aktivitas.
  final langganan = perpus.log.listen((pesan) => print('[LOG] $pesan'));

  // Menambahkan koleksi perpustakaan.
  perpus
    ..tambah(Buku('B01', 'Dasar-Dasar Dart', 'A. Siregar'))
    ..tambah(Majalah('M01', 'Majalah Teknologi', 112))
    ..tambah(
      EBook(
        'E01',
        'Flutter in Action',
        'Eric Windmill',
        'https://contoh.id/e01',
      ),
    )
    ..tambah(Skripsi('S01', 'Sistem Informasi Akademik', 'Mahasiswa FMIPA'));

  // Tantangan 3: menampilkan koleksi menggunakan pattern matching.
  print('\n========== DAFTAR KOLEKSI ==========');

  for (final k in perpus.semuaKoleksi) {
    print('${ikon(k)} ${k.info()}');
  }

  // Data anggota.
  final butet = Anggota('A01', 'Butet', maksPinjam: 1);

  final ucok = Anggota('A02', 'Ucok');

  print('\n========== PEMINJAMAN ==========');

  // Pengujian peminjaman berhasil.
  final p1 = await perpus.pinjam(butet, 'B01', tanggal: DateTime(2026, 10, 1));

  print('Jatuh tempo: ${p1.jatuhTempo}');

  // Menguji tiga kegagalan peminjaman pada modul.
  for (final (anggota, kode) in [
    (ucok, 'B01'),
    (butet, 'M01'),
    (ucok, 'X99'),
  ]) {
    try {
      await perpus.pinjam(anggota, kode);
    } on PeminjamanGagal catch (e) {
      print(e);
    }
  }

  // Tantangan 2: mencoba meminjam Skripsi.
  print('\n========== UJI PEMINJAMAN SKRIPSI ==========');

  try {
    await perpus.pinjam(ucok, 'S01');
  } on PeminjamanGagal catch (e) {
    print(e);
  }

  print('\n========== PENGEMBALIAN ==========');

  // Pengembalian buku dengan keterlambatan tiga hari.
  final denda = perpus.kembalikan(p1, tanggal: DateTime(2026, 10, 18));

  print('Denda: Rp$denda');

  print('Tersedia: ${perpus.koleksiTersedia.map((k) => k.judul).join(', ')}');

  // Menutup Stream dan membatalkan langganan.
  await perpus.tutup();
  await langganan.cancel();

  print('\n==========================================');
  print('          PROGRAM SELESAI');
  print('==========================================');
}
