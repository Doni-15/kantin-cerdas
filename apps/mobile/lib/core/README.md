# Core

Folder ini untuk fondasi teknis yang benar-benar dipakai lintas fitur, misalnya
tipe error atau konfigurasi aplikasi yang tidak bergantung pada UI produk.

Kode di `core` tidak boleh mengimpor `app`, `features`, atau `shared`. Tambahkan
implementasi hanya ketika ada kebutuhan nyata; jangan membuat abstraksi kosong.
