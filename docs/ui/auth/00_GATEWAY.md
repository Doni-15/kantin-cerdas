# Gateway ke spesifikasi Authentication lama (dipertahankan)

> Paket `Kantin_Cerdas_UI_Authentication_Per_Layar.zip` telah dibuka dan **isi 9 file aslinya disalin tanpa mengubah kontennya**. Baca `00_README_MULAI_DI_SINI.md` di folder ini sebelum layar Auth.

## Status desain

- `02_LOGIN_UI_AUTH_001.md`: **UI-AUTH-001 FINAL · LOCKED**.
- Registrasi Langkah 1/2, Verifikasi Email, Lupa/Reset Password, dan matriks state: **DRAFT / visual pernah disukai**, belum di-LOCK secara eksplisit.
- Jangan keliru menganggap status bisnis AUTH-001 s.d. AUTH-005A yang LOCKED berarti semua UI Auth juga LOCKED.

## Aturan bisnis terbaru yang harus dibaca terpisah

- `04_Authentication_Business_Specification_v1.0(1).md` berisi AUTH-001 sampai AUTH-005A: registrasi Customer, verifikasi email sekali sebelum dapat memesan, 2 langkah termasuk foto wajib, login Google, reset link, sesi akun, perubahan profil aman.
- **Keputusan berlaku:** [KC-AUTH-AMEND-2026-11-20-01](../../../development/Kantin_Cerdas_AUTH_005A_Amendment_Final/AMENDEMEN_AUTH_005_005A_2026-11-20.md) mengizinkan linking otomatis bawaan Supabase. UI mengikuti status dari Shelf. Rilis Google menunggu A1–A4.
- Supabase Auth login perlu pemeriksaan profil/role/status berdasarkan user ID dari token sah; jangan dipercaya dari email string.
- Logo asli dan font perlu dicek di repo; `theme.zip` tidak menyertakan aset font/logo.

## Cara implementasi satu layar

Baca `../00_MULAI_DI_SINI.md`, `../shared/03_DESIGN_SYSTEM.md`, lalu `auth/02_LOGIN_UI_AUTH_001.md` (atau layar lainnya) dan `auth/08_STATE_NAVIGASI_PENGUJIAN.md`.

**Jangan mengubah file Auth lama tanpa permintaan pengguna.** Jika business guard terbaru memerlukan koreksi, gunakan catatan ini dan laporkan UI yang akan terpengaruh sebelum edit.
