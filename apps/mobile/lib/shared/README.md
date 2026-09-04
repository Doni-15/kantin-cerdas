# Shared

Folder ini untuk komponen UI atau utilitas yang telah dipakai oleh lebih dari
satu fitur dan tidak membawa aturan bisnis fitur tertentu.

Kode di `shared` boleh memakai `core`, tetapi tidak boleh mengimpor `app` atau
`features`. Jangan memindahkan kode ke sini hanya karena mungkin akan digunakan
ulang pada masa depan.
