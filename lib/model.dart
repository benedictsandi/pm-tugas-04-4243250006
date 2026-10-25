sealed class Koleksi {
  final String kode;
  final String judul;

  bool _dipinjam = false;

  Koleksi(this.kode, this.judul);

  int get lamaPinjam;

  bool get tersedia => !_dipinjam;

  String info() => '[$kode] $judul';

  // Method publik agar field privat tidak diakses dari library lain.
  void tandaiDipinjam() {
    if (_dipinjam) {
      throw StateError('Koleksi sudah dipinjam.');
    }
    _dipinjam = true;
  }

  void tandaiDikembalikan() {
    if (!_dipinjam) {
      throw StateError('Koleksi belum dipinjam.');
    }
    _dipinjam = false;
  }
}

// Mixin untuk koleksi yang dapat diunduh.
mixin BisaDiunduh {
  String get url;

  String unduh() => 'Mengunduh dari $url ...';
}

// Subclass Buku.
class Buku extends Koleksi {
  final String penulis;

  Buku(super.kode, super.judul, this.penulis);

  @override
  int get lamaPinjam => 14;

  @override
  String info() => '${super.info()} oleh $penulis';
}

// Subclass Majalah.
class Majalah extends Koleksi {
  final int edisi;

  Majalah(super.kode, super.judul, this.edisi);

  @override
  int get lamaPinjam => 7;

  @override
  String info() => '${super.info()} edisi $edisi';
}

// Subclass EBook, mewarisi Buku dan menggunakan mixin.
class EBook extends Buku with BisaDiunduh {
  @override
  final String url;

  EBook(super.kode, super.judul, super.penulis, this.url);

  @override
  int get lamaPinjam => 30;
}

// Tantangan 2: Skripsi hanya boleh dibaca di tempat.
class Skripsi extends Koleksi {
  final String penulis;

  Skripsi(super.kode, super.judul, this.penulis);

  @override
  int get lamaPinjam => 0;

  @override
  String info() => '${super.info()} oleh $penulis (Baca di tempat)';
}

// Tantangan 3: pattern matching pada sealed class.
// EBook ditulis sebelum Buku karena EBook merupakan turunan Buku.
String ikon(Koleksi k) => switch (k) {
  EBook() => '📱',
  Buku() => '📘',
  Majalah() => '📰',
  Skripsi() => '🎓',
};

// Data anggota perpustakaan.
class Anggota {
  final String id;
  final String nama;
  final int maksPinjam;

  Anggota(this.id, this.nama, {this.maksPinjam = 2});
}

// Model transaksi peminjaman.
class Peminjaman {
  final Anggota anggota;
  final Koleksi koleksi;
  final DateTime tanggal;

  Peminjaman(this.anggota, this.koleksi, this.tanggal);

  DateTime get jatuhTempo => tanggal.add(Duration(days: koleksi.lamaPinjam));

  int dendaPada(DateTime kembali) {
    final telat = kembali.difference(jatuhTempo).inDays;

    return telat > 0 ? telat * 1000 : 0;
  }
}

// Exception khusus kegagalan peminjaman.
class PeminjamanGagal implements Exception {
  final String alasan;

  PeminjamanGagal(this.alasan);

  @override
  String toString() => 'Peminjaman gagal: $alasan';
}
