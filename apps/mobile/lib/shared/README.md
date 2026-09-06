# Shared

Folder ini berisi fondasi desain aplikasi pada `design_system`, serta
komponen UI atau utilitas yang telah dipakai oleh lebih dari satu fitur
dan tidak membawa aturan bisnis fitur tertentu. Fondasi desain dapat
dipakai oleh `app`, `features`, dan komponen `shared`; perakitan tema
aplikasi tetap berada di `app/theme`.

Kode di `shared` boleh memakai `core`, tetapi tidak boleh mengimpor `app` atau
`features`. Jangan memindahkan kode ke sini hanya karena mungkin akan digunakan
ulang pada masa depan.
