# Instruksi hemat konteks untuk AI pelaksana / Codex

**Tujuan:** Implementasi layar UI Kantin Cerdas dengan kepatuhan desain, tanpa menebak bisnis/backend. Jangan menyalin keseluruhan ZIP ini ke prompt satu tugas.

## Prompt template

```text
TUGAS: Implementasikan hanya <UI-ID> pada proyek Kantin Cerdas.
BACA: 00_MULAI_DI_SINI.md, shared/01_STATUS_DAN_SUMBER.md,
shared/03_DESIGN_SYSTEM.md, shared/04_NAVIGASI.md,
shared/06_STATES_LOADING_ERROR.md, <file-layar>.
Jika layar melibatkan pesanan: baca shared/07_STATUS_PESANAN.md.
Jika memerlukan data/backend: baca spesifikasi bisnis LOCKED terbaru
sesuai ID rujukan dari YAML file layar serta kontrak API aktual.
JANGAN: ubah UI LOCKED lain; buat endpoint/schema/enum baru tanpa sumber;
anggap DRAFT telah disetujui; beri akses role berdasarkan UI; pakai data dummy produksi.
KERJAKAN: telaah kode/theme existing → implementasi minimal → lint/analyze/test
→ laporkan perubahan file, hasil uji, dan blocker. Jangan menyembunyikan kegagalan.
```

## Jika belum diminta coding

Hanya bahas dan revisi dokumen. Jangan membuat codebase baru atau melakukan commit.

## Format laporan AI setelah bekerja

- UI-ID dan status desain yang dipakai
- File sumber yang dibaca + bukti token tema
- Berkas yang diubah
- Perilaku sukses/empty/error + guard backend
- `flutter analyze`, test UI/widget dan integrasi (status nyata, bukan klaim)
- Hal yang belum dapat diuji/diputuskan

## Aturan STOP

Jika ada konflik source (misalnya identity linking Auth), laporan blocker dan bedakan antara rekomendasi, keputusan bisnis, dan hasil uji. Untuk perubahan visual layar LOCKED, minta persetujuan sebelum mengubahnya.
