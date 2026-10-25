import 'dart:async';

import 'model.dart';

class Perpustakaan {
  final String nama;

  final List<Koleksi> _koleksi = [];
  final List<Peminjaman> _aktif = [];

  final StreamController<String> _log = StreamController<String>.broadcast();

  Perpustakaan(this.nama);

  // Stream untuk menampilkan aktivitas perpustakaan.
  Stream<String> get log => _log.stream;

  // Getter agar daftar koleksi dapat dibaca tanpa mengubah List asli.
  List<Koleksi> get semuaKoleksi => List.unmodifiable(_koleksi);

  List<Koleksi> get koleksiTersedia =>
      _koleksi.where((k) => k.tersedia).toList();

  void tambah(Koleksi k) {
    _koleksi.add(k);
    _log.add('Koleksi baru: ${k.judul}');
  }

  // Peminjaman dilakukan secara asynchronous.
  Future<Peminjaman> pinjam(Anggota a, String kode, {DateTime? tanggal}) async {
    // Simulasi pengecekan server.
    await Future.delayed(const Duration(milliseconds: 300));

    final k = _koleksi.where((x) => x.kode == kode).firstOrNull;

    // Memeriksa apakah kode tersedia.
    if (k == null) {
      throw PeminjamanGagal('kode $kode tidak ditemukan');
    }

    // Tantangan 2: Skripsi tidak boleh dipinjam.
    if (k is Skripsi) {
      throw PeminjamanGagal('"${k.judul}" hanya boleh dibaca di tempat');
    }

    // Memeriksa apakah koleksi sedang dipinjam.
    if (!k.tersedia) {
      throw PeminjamanGagal('"${k.judul}" sedang dipinjam');
    }

    // Memeriksa batas jumlah pinjaman anggota.
    final jumlah = _aktif.where((p) => p.anggota.id == a.id).length;

    if (jumlah >= a.maksPinjam) {
      throw PeminjamanGagal('${a.nama} sudah mencapai batas $jumlah pinjaman');
    }

    // Tantangan 1: mengubah status melalui method publik.
    k.tandaiDipinjam();

    final p = Peminjaman(a, k, tanggal ?? DateTime.now());

    _aktif.add(p);

    _log.add('${a.nama} meminjam "${k.judul}"');

    return p;
  }

  int kembalikan(Peminjaman p, {DateTime? tanggal}) {
    // Memastikan peminjaman masih tercatat aktif.
    if (!_aktif.contains(p)) {
      throw PeminjamanGagal(
        'data peminjaman tidak aktif atau sudah dikembalikan',
      );
    }

    final denda = p.dendaPada(tanggal ?? DateTime.now());

    // Menggunakan method publik, bukan _dipinjam secara langsung.
    p.koleksi.tandaiDikembalikan();

    _aktif.remove(p);

    _log.add('${p.anggota.nama} mengembalikan "${p.koleksi.judul}"');

    return denda;
  }

  Future<void> tutup() => _log.close();
}
