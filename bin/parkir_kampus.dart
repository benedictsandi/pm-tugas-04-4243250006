import 'dart:async';

// ==========================================
// MODEL KENDARAAN
// ==========================================

abstract class Kendaraan {
  final String plat;
  final DateTime waktuMasuk;

  Kendaraan(this.plat, this.waktuMasuk);

  String get jenis;
  int get tarifPerJam;

  // Durasi parkir dibulatkan ke atas,
  // dengan biaya minimal satu jam.
  int biaya(DateTime keluar) {
    final durasi = keluar.difference(waktuMasuk);

    if (durasi.isNegative) {
      throw ArgumentError('Waktu keluar tidak boleh sebelum waktu masuk.');
    }

    const satuJam = Duration(hours: 1);

    final jam =
        (durasi.inMicroseconds + satuJam.inMicroseconds - 1) ~/
        satuJam.inMicroseconds;

    final jamDitagih = jam < 1 ? 1 : jam;

    return jamDitagih * tarifPerJam;
  }
}

// Jenis kendaraan pertama.
class Motor extends Kendaraan {
  Motor(super.plat, super.waktuMasuk);

  @override
  String get jenis => 'Motor';

  @override
  int get tarifPerJam => 3000;
}

// Jenis kendaraan kedua.
class Mobil extends Kendaraan {
  Mobil(super.plat, super.waktuMasuk);

  @override
  String get jenis => 'Mobil';

  @override
  int get tarifPerJam => 5000;
}

// Jenis kendaraan ketiga.
class Truk extends Kendaraan {
  Truk(super.plat, super.waktuMasuk);

  @override
  String get jenis => 'Truk';

  @override
  int get tarifPerJam => 8000;
}

// Mixin untuk diskon pelanggan member.
mixin Berlangganan on Kendaraan {
  int terapkanDiskon(int biayaAwal) {
    return biayaAwal ~/ 2;
  }
}

// Mobil member dengan diskon 50%.
class MobilMember extends Mobil with Berlangganan {
  MobilMember(super.plat, super.waktuMasuk);

  @override
  String get jenis => 'Mobil (member)';

  @override
  int biaya(DateTime keluar) {
    final biayaAwal = super.biaya(keluar);
    return terapkanDiskon(biayaAwal);
  }
}

// ==========================================
// EXCEPTION KHUSUS
// ==========================================

class ParkirPenuh implements Exception {
  final int kapasitas;

  ParkirPenuh(this.kapasitas);

  @override
  String toString() => 'Parkiran penuh (kapasitas $kapasitas)';
}

// ==========================================
// LAYANAN PARKIRAN
// ==========================================

class Parkiran {
  final int kapasitas;

  // Data kendaraan tidak dapat diakses
  // langsung dari luar library.
  final Map<String, Kendaraan> _kendaraan = {};

  int _pendapatan = 0;

  final StreamController<String> _log = StreamController<String>.broadcast();

  Parkiran(this.kapasitas) {
    if (kapasitas <= 0) {
      throw ArgumentError('Kapasitas harus lebih dari nol.');
    }
  }

  int get sisa => kapasitas - _kendaraan.length;

  int get pendapatan => _pendapatan;

  Stream<String> get log => _log.stream;

  // Simulasi palang otomatis ketika masuk.
  Future<void> masuk(Kendaraan kendaraan) async {
    if (sisa <= 0) {
      throw ParkirPenuh(kapasitas);
    }

    if (_kendaraan.containsKey(kendaraan.plat)) {
      throw StateError('Plat ${kendaraan.plat} sudah terdaftar.');
    }

    // Simulasi waktu membuka palang.
    await Future.delayed(const Duration(milliseconds: 300));

    _kendaraan[kendaraan.plat] = kendaraan;

    _log.add(
      'MASUK ${kendaraan.jenis} ${kendaraan.plat} '
      '(sisa $sisa)',
    );
  }

  // Simulasi palang otomatis ketika keluar.
  Future<int> keluar(Kendaraan kendaraan, DateTime waktuKeluar) async {
    final tercatat = _kendaraan[kendaraan.plat];

    if (!identical(tercatat, kendaraan)) {
      throw StateError('Kendaraan ${kendaraan.plat} tidak terdaftar.');
    }

    // Hitung biaya sebelum mengubah data parkir.
    final biaya = kendaraan.biaya(waktuKeluar);

    await Future.delayed(const Duration(milliseconds: 300));

    _kendaraan.remove(kendaraan.plat);
    _pendapatan += biaya;

    _log.add(
      'KELUAR ${kendaraan.jenis} ${kendaraan.plat} '
      'bayar Rp$biaya',
    );

    return biaya;
  }

  Future<void> tutup() => _log.close();
}

// ==========================================
// PROGRAM UTAMA
// ==========================================

Future<void> main() async {
  print('==========================================');
  print('         SISTEM PARKIR KAMPUS FMIPA');
  print('==========================================');

  final parkiran = Parkiran(3);

  // Listener Stream untuk aktivitas pos jaga.
  final langganan = parkiran.log.listen((pesan) => print('[LOG] $pesan'));

  // Waktu dibuat tetap agar pengujian
  // menghasilkan perhitungan yang konsisten.
  final waktu = DateTime(2026, 10, 1, 8);

  // Polymorphism: berbagai jenis kendaraan
  // disimpan dalam satu List<Kendaraan>.
  final List<Kendaraan> kendaraan = [
    Motor('BK 1234 AB', waktu),
    Mobil('BK 88 UN', waktu),
    MobilMember('BK 7 MIPA', waktu),
    Truk('BK 9999 TR', waktu),
  ];

  print('\n--- KENDARAAN MASUK ---');

  for (final k in kendaraan) {
    try {
      await parkiran.masuk(k);
    } on ParkirPenuh catch (e) {
      print('Ditolak: $e');
    }
  }

  print('\n--- KENDARAAN KELUAR ---');

  // Motor: 1 jam 30 menit -> ditagih 2 jam.
  await parkiran.keluar(kendaraan[0], DateTime(2026, 10, 1, 9, 30));

  // Mobil: 3 jam.
  await parkiran.keluar(kendaraan[1], DateTime(2026, 10, 1, 11));

  // Mobil member: 3 jam dengan diskon 50%.
  await parkiran.keluar(kendaraan[2], DateTime(2026, 10, 1, 11));

  print('\n--- RINGKASAN PARKIR ---');
  print('Kapasitas  : ${parkiran.kapasitas}');
  print('Sisa tempat: ${parkiran.sisa}');
  print('Pendapatan: Rp${parkiran.pendapatan}');

  await parkiran.tutup();
  await langganan.cancel();

  print('==========================================');
  print('              SELESAI');
  print('==========================================');
}
