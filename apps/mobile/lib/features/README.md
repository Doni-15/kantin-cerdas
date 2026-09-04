# Features

Folder ini untuk implementasi per fitur produk. Setiap fitur menjaga UI, state,
dan logika khusus fiturnya tetap berdekatan ketika implementasi tersebut sudah
dibutuhkan.

Fitur boleh memakai `core` dan `shared`, tetapi tidak boleh mengimpor `app` atau
bergantung langsung pada detail fitur lain. Pindahkan kontrak lintas fitur hanya
jika pemakaian nyata membuktikan bahwa kontrak tersebut memang bersama.
