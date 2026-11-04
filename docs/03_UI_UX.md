# UI/UX dan state

Pertahankan [design system](desain/SISTEM_DESAIN.md): Plus Jakarta Sans, aksen oranye, surface light/dark, token bersama dan navigasi role.

| Kondisi | Perilaku |
| --- | --- |
| Read awal | `KcSkeleton`/`KcLoadingSkeleton` sesuai bentuk daftar/detail/form/dashboard |
| Sukses kosong | Pesan kosong dan aksi relevan |
| Error/timeout | Pesan manusiawi dan coba lagi untuk read |
| Belum terhubung (`API_BASE_URL` kosong) | Layanan belum tersedia, tanpa sukses/data palsu pada entry normal |
| Submit | Cegah klik/dialog ganda, indikator berlangsung |
| Unknown | Recovery/periksa status, tanpa retry mutasi |
| Form berubah | Konfirmasi sebelum keluar/menimpa isian |
| Sesi berubah | Tutup dialog lama dan abaikan respons lama |
| Pagination | Pertahankan daftar saat load-more; muat ulang mulai halaman awal |
| Unggah/tampil gambar | `KcImagePickerField`, `KcImageSourceSheet`, dan `KcEntityImage` memvalidasi Magic Bytes JPG/PNG/WEBP <= 2 MB dan menolak URL/file berbahaya dengan fallback aman |

Skeleton mengikuti disableAnimations/accessibleNavigation dan TickerMode.valuesOf(context).enabled; satu label loading, placeholder tidak interaktif. Entry normal tanpa delay buatan; simulasi memakai latency untuk demonstrasi.

Asisten memakai batas 500 grapheme termasuk emoji, membuang state saat sesi tidak sah, dan mengikat konfirmasi hapus pada sesi/snapshot. Rekomendasi bukan jaminan bebas alergen.

Acceptance visual belum dinyatakan lulus: layar kecil/landscape, keyboard, text scale 200%, light/dark, screen reader, fokus, contrast, reduced motion, tombol kembali/deep link/pemulihan login. Dialog harus dapat discroll; input gagal dipertahankan; jangan tampilkan stack/token sebagai pesan pengguna. Lihat [skenario langsung](04_STATUS_DAN_PENGUJIAN.md).


Referensi tambahan: [PDF desain](desain/REFERENSI_UI_UX.pdf). PDF dipertahankan tanpa perubahan isi; jangan menganggapnya screenshot hasil build terbaru.
