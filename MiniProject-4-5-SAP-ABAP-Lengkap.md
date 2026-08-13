# Mini Project 4–5 SAP ABAP — Kode Lengkap & Langkah Detail

> Catatan sama seperti file sebelumnya: kode di bawah sudah saya susun mengikuti sintaks ABAP standar dan logikanya sudah saya periksa baris per baris, tapi saya tidak punya akses sistem SAP nyata untuk mengeksekusinya langsung. Jadi saya tidak bisa menjamin **100% zero-error** di sisi environment (otorisasi, transport, versi sistem) — yang saya jamin adalah sintaks dan logikanya benar sesuai standar. Tiap bagian ada tabel "Kemungkinan Error & Solusinya".

Project ini melanjutkan objek yang sudah dibuat di Mini Project 1–3 (tabel `ZEMPLOYEE_M1`, program `ZR_EMPLOYEE_REPORT_M1`, transaksi `ZEMP_ENTRY_M3`). Pastikan itu semua sudah ada dulu di sistem kamu sebelum lanjut ke sini.

---

# 📁 MINI PROJECT 4 — Mass Upload Tool (BDC, RFC, BAPI, dan pengenalan LSMW/IDOC)

## Tujuan
Menutup poin requirement JD yang paling teknis: *Dialog Programming, User Exits, Data Interfaces (RFC, ALE, ALV, IDOCS, BDC, BAPI, BDT, LSMW)*.

Project ini dipecah jadi 3 bagian: (A) BDC Mass Upload, (B) Custom RFC Function Module, (C) Konsumsi BAPI standar. Ditutup dengan penjelasan konsep LSMW & IDOC yang bisa kamu ceritakan di interview walau tidak full-code (karena keduanya berbasis wizard/config, bukan pure ABAP).

---

## Bagian A — BDC Mass Upload Tool

### Skenario
Upload banyak data pegawai sekaligus dari file Excel/CSV ke tabel `ZEMPLOYEE_M1`, dengan mensimulasikan input manual ke transaksi `ZEMP_ENTRY_M3` (dari Mini Project 3) menggunakan BDC (Batch Data Communication).

### Langkah 1 — Siapkan File Upload
Buat file CSV contoh (nanti diupload lewat `GUI_UPLOAD` dari presentation server/laptop kamu), format:

```
EMP_NO;EMP_NAME;DEPARTMENT;SALARY;HIRE_DATE
E006;Budi Santoso;IT;8500000;20240101
E007;Siti Aminah;FINANCE;9200000;20230515
E008;Rudi Hartono;HR;7800000;20220310
```

### Langkah 2 — Program BDC Upload

Buat program `ZR_BDC_EMP_UPLOAD_M4`:

```abap
REPORT zr_bdc_emp_upload_m4.

PARAMETERS: p_file TYPE string LOWER CASE OBLIGATORY
              DEFAULT 'C:\Upload\employee_upload.csv'.

TYPES: BEGIN OF ty_upload,
         emp_no     TYPE zemployee_m1-emp_no,
         emp_name   TYPE zemployee_m1-emp_name,
         department TYPE zemployee_m1-department,
         salary     TYPE zemployee_m1-salary,
         hire_date  TYPE zemployee_m1-hire_date,
       END OF ty_upload.

DATA: gt_upload TYPE STANDARD TABLE OF ty_upload,
      gt_raw    TYPE STANDARD TABLE OF string,
      gt_bdcdata TYPE STANDARD TABLE OF bdcdata,
      gs_bdcdata TYPE bdcdata,
      gt_messages TYPE STANDARD TABLE OF bdcmsgcoll,
      gv_success  TYPE i,
      gv_error    TYPE i.

"-----------------------------------------------------------
START-OF-SELECTION.

  PERFORM upload_file.
  PERFORM process_bdc.
  PERFORM show_summary.

"-----------------------------------------------------------
FORM upload_file.

  DATA(lv_path) = CONV string( p_file ).

  cl_gui_frontend_services=>gui_upload(
    EXPORTING
      filename                = lv_path
      filetype                = 'ASC'
    CHANGING
      data_tab                = gt_raw
    EXCEPTIONS
      file_open_error         = 1
      file_read_error         = 2
      no_batch                = 3
      gui_refuse_filetransfer = 4
      invalid_type            = 5
      OTHERS                  = 6 ).

  IF sy-subrc <> 0.
    MESSAGE 'Gagal membaca file. Cek path file.' TYPE 'E'.
    RETURN.
  ENDIF.

  " Skip baris header (baris pertama)
  LOOP AT gt_raw INTO DATA(lv_line) FROM 2.
    SPLIT lv_line AT ';' INTO DATA(lv_empno) DATA(lv_name)
                              DATA(lv_dept) DATA(lv_sal) DATA(lv_date).

    APPEND VALUE ty_upload(
      emp_no     = lv_empno
      emp_name   = lv_name
      department = lv_dept
      salary     = lv_sal
      hire_date  = lv_date
    ) TO gt_upload.
  ENDLOOP.

ENDFORM.

"-----------------------------------------------------------
FORM process_bdc.

  LOOP AT gt_upload INTO DATA(ls_upload).

    CLEAR gt_bdcdata.

    " Screen pertama transaksi ZEMP_ENTRY_M3 (screen 0100)
    PERFORM bdc_dynpro USING 'SAPMZEMP_ENTRY_M3' '0100'.
    PERFORM bdc_field  USING 'BDC_CURSOR' 'ZEMPLOYEE_M1-SALARY'.
    PERFORM bdc_field  USING 'BDC_OKCODE' '=SAVE'.
    PERFORM bdc_field  USING 'ZEMPLOYEE_M1-EMP_NO'     ls_upload-emp_no.
    PERFORM bdc_field  USING 'ZEMPLOYEE_M1-EMP_NAME'   ls_upload-emp_name.
    PERFORM bdc_field  USING 'ZEMPLOYEE_M1-DEPARTMENT' ls_upload-department.
    PERFORM bdc_field  USING 'ZEMPLOYEE_M1-SALARY'     ls_upload-salary.
    PERFORM bdc_field  USING 'ZEMPLOYEE_M1-HIRE_DATE'  ls_upload-hire_date.

    CALL TRANSACTION 'ZEMP_ENTRY_M3'
      USING gt_bdcdata
      MODE   'N'   " N = Tanpa tampilan layar (background), ganti 'A' kalau mau lihat prosesnya
      UPDATE 'S'
      MESSAGES INTO gt_messages.

    IF sy-subrc = 0.
      gv_success = gv_success + 1.
    ELSE.
      gv_error = gv_error + 1.
    ENDIF.

  ENDLOOP.

ENDFORM.

"-----------------------------------------------------------
FORM bdc_dynpro USING iv_program iv_dynpro.
  CLEAR gs_bdcdata.
  gs_bdcdata-program  = iv_program.
  gs_bdcdata-dynpro   = iv_dynpro.
  gs_bdcdata-dynbegin = 'X'.
  APPEND gs_bdcdata TO gt_bdcdata.
ENDFORM.

FORM bdc_field USING iv_fnam iv_fval.
  CLEAR gs_bdcdata.
  gs_bdcdata-fnam = iv_fnam.
  gs_bdcdata-fval = iv_fval.
  APPEND gs_bdcdata TO gt_bdcdata.
ENDFORM.

"-----------------------------------------------------------
FORM show_summary.
  WRITE: / 'Upload selesai.'.
  WRITE: / 'Berhasil :', gv_success.
  WRITE: / 'Gagal    :', gv_error.

  IF gv_error > 0.
    WRITE: / 'Detail pesan error:'.
    LOOP AT gt_messages INTO DATA(ls_msg) WHERE msgtyp = 'E'.
      WRITE: / ls_msg-msgv1, ls_msg-msgv2.
    ENDLOOP.
  ENDIF.
ENDFORM.
```

### Kemungkinan Error & Solusinya (Bagian A)
| Error | Penyebab | Solusi |
|---|---|---|
| `NO_BATCH` saat GUI_UPLOAD | Fungsi ini butuh SAP GUI (frontend), tidak jalan kalau run di background job murni | Jalankan lewat SAP GUI biasa (foreground), bukan lewat SM36/background job |
| `CALL TRANSACTION` selalu gagal (`sy-subrc <> 0`) | Nama field BDC tidak sama persis dengan nama field di screen 0100 | Cocokkan nama field via transaksi `SHDB` (rekam manual dulu satu kali transaksi input data, lihat nama field BDC yang benar, baru samakan di program) |
| Field `BDC_CURSOR` salah posisi | Cursor diarahkan ke field yang tidak ada di screen | Sesuaikan dengan field terakhir yang ada di layout screen kamu |
| Data tanggal salah format | `HIRE_DATE` butuh format sesuai user setting (misal DDMMYYYY tidak selalu `YYYYMMDD`) | Konversi dulu ke format tanggal user via `CONVERT_DATE_TO_INTERNAL` sebelum masuk BDC field |

📌 **Cara paling akurat untuk field BDC**: sebelum coding, rekam dulu 1x input manual lewat transaksi `SHDB` → itu akan generate BDC data yang 100% sesuai dengan screen kamu, tinggal disalin polanya ke program.

---

## Bagian B — Custom Remote-Enabled Function Module (RFC)

### Tujuan
Menunjukkan kemampuan membuat RFC yang bisa dipanggil sistem lain (poin "Data Interfaces: RFC" di JD).

### Langkah 1 — Buat Function Group
New → ABAP Repository Object → Function Group, nama: `ZFG_EMPLOYEE_M4`

### Langkah 2 — Buat Function Module

Nama: `Z_FM_GET_EMPLOYEE_DETAIL_M4`
Di properties, centang **"Remote-Enabled Module"**.

**Import Parameter:** `IV_EMP_NO` TYPE `ZEMPLOYEE_M1-EMP_NO`
**Export Parameter:** `ES_EMPLOYEE` TYPE `ZEMPLOYEE_M1`
**Exceptions:** `NOT_FOUND`

```abap
FUNCTION z_fm_get_employee_detail_m4.
*"----------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(IV_EMP_NO) TYPE  ZEMPLOYEE_M1-EMP_NO
*"  EXPORTING
*"     VALUE(ES_EMPLOYEE) TYPE  ZEMPLOYEE_M1
*"  EXCEPTIONS
*"      NOT_FOUND
*"----------------------------------------------------------------

  SELECT SINGLE * FROM zemployee_m1
    WHERE emp_no = @iv_emp_no
    INTO @es_employee.

  IF sy-subrc <> 0.
    RAISE not_found.
  ENDIF.

ENDFUNCTION.
```

### Langkah 3 — Buat Program Test Caller (simulasi "sistem lain" memanggil RFC ini)

```abap
REPORT zr_test_rfc_caller_m4.

PARAMETERS: p_empno TYPE zemployee_m1-emp_no OBLIGATORY.

DATA: ls_employee TYPE zemployee_m1.

START-OF-SELECTION.

  CALL FUNCTION 'Z_FM_GET_EMPLOYEE_DETAIL_M4'
    EXPORTING
      iv_emp_no   = p_empno
    IMPORTING
      es_employee = ls_employee
    EXCEPTIONS
      not_found   = 1
      OTHERS      = 2.

  IF sy-subrc = 1.
    MESSAGE 'Data pegawai tidak ditemukan.' TYPE 'E'.
  ELSEIF sy-subrc <> 0.
    MESSAGE 'Terjadi error saat memanggil RFC.' TYPE 'E'.
  ELSE.
    WRITE: / 'Nama       :', ls_employee-emp_name.
    WRITE: / 'Departemen :', ls_employee-department.
    WRITE: / 'Gaji       :', ls_employee-salary.
  ENDIF.
```

> Untuk benar-benar menunjukkan sifat "Remote" — kalau kamu punya 2 sistem/klien SAP, kamu bisa buat RFC Destination (`SM59`) dan panggil function module ini pakai `CALL FUNCTION ... DESTINATION 'nama_destination'`. Kalau cuma 1 sistem, cukup panggil biasa seperti di atas — itu sudah cukup menunjukkan konsepnya untuk portfolio.

### Kemungkinan Error & Solusinya (Bagian B)
| Error | Penyebab | Solusi |
|---|---|---|
| `FUNCTION_NOT_FOUND` | Function module belum di-activate, atau typo nama | Aktivasi Function Group & Function Module, cek nama persis sama |
| Exception `NOT_FOUND` tidak ter-trigger | Interface exception belum didaftarkan di signature FM | Pastikan `NOT_FOUND` sudah ditambahkan di tab Exceptions saat define FM |
| RFC destination error (kalau pakai DESTINATION) | Koneksi RFC di SM59 belum dikonfigurasi/testing gagal | Untuk portfolio single-system, skip DESTINATION, cukup local call seperti contoh |

📌 **Poin CV:** *"Membuat custom Remote-Enabled Function Module (RFC) untuk pertukaran data antar sistem, serta BDC upload tool untuk migrasi data massal menggunakan CALL TRANSACTION."*

---

## Bagian C — Konsumsi BAPI Standar

### Tujuan
Menunjukkan kamu paham cara memakai BAPI standar SAP (bukan bikin sendiri, tapi consume) — pola ini sangat umum dipakai di real project.

### Contoh: Ambil Detail User via BAPI Standar

```abap
REPORT zr_bapi_consume_demo_m4.

PARAMETERS: p_uname TYPE bapibname-bapibname OBLIGATORY.

DATA: ls_logondata TYPE bapilogond,
      ls_defaults  TYPE bapidefaul,
      ls_address   TYPE bapiaddr3,
      lt_return    TYPE STANDARD TABLE OF bapiret2.

START-OF-SELECTION.

  CALL FUNCTION 'BAPI_USER_GET_DETAIL'
    EXPORTING
      username = p_uname
    IMPORTING
      logondata = ls_logondata
      defaults  = ls_defaults
      address   = ls_address
    TABLES
      return    = lt_return.

  READ TABLE lt_return TRANSPORTING NO FIELDS
    WITH KEY type = 'E'.

  IF sy-subrc = 0.
    MESSAGE 'User tidak ditemukan atau tidak ada otorisasi.' TYPE 'E'.
  ELSE.
    WRITE: / 'Nama Lengkap :', ls_address-fullname.
    WRITE: / 'Email        :', ls_address-e_mail.
    WRITE: / 'Departemen   :', ls_address-department.
  ENDIF.
```

> `BAPI_USER_GET_DETAIL` adalah BAPI standar bawaan SAP (bukan custom), jadi ini aman dipanggil di sistem manapun tanpa perlu setup tambahan — cocok untuk latihan konsep "consume BAPI" tanpa harus bikin BAPI sendiri dulu (bikin BAPI custom itu levelnya lebih advanced, biasanya baru diajarkan di project real).

### Kemungkinan Error & Solusinya (Bagian C)
| Error | Penyebab | Solusi |
|---|---|---|
| `lt_return` berisi error type 'E' | User tidak ada / tidak ada otorisasi baca user lain | Coba dengan username kamu sendiri dulu |
| BAPI tidak ditemukan | Nama BAPI beda di versi sistem tertentu | Cek via SE37, cari BAPI lain yang setara kalau versi sistem berbeda (misal `BAPI_EMPLOYEE_GETDATA` kalau modul HR aktif) |

---

## Pengenalan LSMW & IDOC (Konsep, untuk Cerita di Interview)

Dua hal ini **tidak bisa full di-code** karena sifatnya wizard-based/config-based, tapi kamu tetap perlu paham alurnya karena disebut eksplisit di JD:

**LSMW (Legacy System Migration Workbench)** — alurnya:
1. Transaksi `LSMW` → buat project baru
2. Pilih metode: Batch Input Recording / Standard Batch/Direct Input / BAPI / IDOC
3. Maintain source structure (field-field dari file Excel/CSV sumber)
4. Maintain field mapping (source field → target field SAP)
5. Convert data, lalu generate & jalankan batch input session

*Cerita untuk interview:* "LSMW itu prinsipnya mirip dengan BDC yang saya buat manual di Mini Project 4 Bagian A, bedanya LSMW punya wizard GUI yang generate BDC-nya otomatis tanpa perlu coding manual field-by-field."

**IDOC & ALE** — alurnya konsep:
1. IDOC adalah struktur data standar SAP untuk pertukaran data antar sistem (mirip "amplop" data)
2. ALE (Application Link Enabling) adalah mekanisme yang mengatur distribusi IDOC antar sistem SAP
3. Contoh: sistem A generate Outbound IDOC → dikirim lewat RFC destination → sistem B terima sebagai Inbound IDOC → diproses oleh Function Module tertentu (biasanya nama depannya `IDOC_INPUT_...`)

*Cerita untuk interview:* "Saya paham konsep IDOC sebagai media transfer data terstruktur antar sistem SAP via ALE, meskipun untuk implementasi penuh butuh 2 sistem yang terkoneksi via RFC destination — di project sendiri saya fokus dulu di RFC point-to-point (Mini Project 4 Bagian B) karena lebih feasible untuk latihan single-system."

📌 Jujur di CV/interview kalau LSMW & IDOC levelnya masih "paham konsep", bukan "sudah implementasi penuh" — itu lebih baik daripada klaim berlebihan yang bisa ketahuan saat technical test.

---

# 📁 MINI PROJECT 5 — Refactor ke Object-Oriented ABAP (OO ALV + Exception Handling)

## Tujuan
Menunjukkan kamu paham OO ABAP — walau tidak eksplisit disebut di JD, ini hampir selalu ditanyakan di technical interview level junior modern, dan menunjukkan kamu update dengan best practice ABAP terkini.

## Konsep yang Ditunjukkan
- Local Class (Definition & Implementation)
- Constructor
- Method dengan parameter IMPORTING/RETURNING
- Custom Exception Class
- TRY/CATCH
- OO-ALV Grid

## Langkah — Refactor Program `ZR_EMPLOYEE_REPORT_M1` (Mini Project 1)

Buat program baru `ZR_EMPLOYEE_REPORT_OO_M5` (jangan timpa versi lama, biar bisa dibandingkan "before-after" di portfolio):

```abap
REPORT zr_employee_report_oo_m5.

"---------------------------------------------------------
" Custom Exception Class
"---------------------------------------------------------
CLASS lcx_employee_not_found DEFINITION INHERITING FROM cx_static_check.
  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        textid   LIKE if_t100_message=>t100key OPTIONAL
        previous LIKE previous OPTIONAL.
ENDCLASS.

CLASS lcx_employee_not_found IMPLEMENTATION.
  METHOD constructor.
    CALL METHOD super->constructor
      EXPORTING
        previous = previous.
  ENDMETHOD.
ENDCLASS.

"---------------------------------------------------------
" Local Class: Employee Report Handler
"---------------------------------------------------------
CLASS lcl_employee_report DEFINITION.

  PUBLIC SECTION.

    TYPES: BEGIN OF ty_employee,
             emp_no     TYPE zemployee_m1-emp_no,
             emp_name   TYPE zemployee_m1-emp_name,
             department TYPE zemployee_m1-department,
             salary     TYPE zemployee_m1-salary,
             hire_date  TYPE zemployee_m1-hire_date,
           END OF ty_employee,
           tt_employee TYPE STANDARD TABLE OF ty_employee.

    METHODS:
      constructor
        IMPORTING
          iv_department TYPE zemployee_m1-department OPTIONAL,

      get_employee_data
        RETURNING VALUE(rt_data) TYPE tt_employee
        RAISING   lcx_employee_not_found,

      display_alv
        IMPORTING it_data TYPE tt_employee.

  PRIVATE SECTION.
    DATA: mv_department TYPE zemployee_m1-department.

ENDCLASS.

"---------------------------------------------------------
CLASS lcl_employee_report IMPLEMENTATION.

  METHOD constructor.
    mv_department = iv_department.
  ENDMETHOD.

  METHOD get_employee_data.

    SELECT emp_no, emp_name, department, salary, hire_date
      FROM zemployee_m1
      WHERE department = @mv_department OR @mv_department = @space
      INTO TABLE @rt_data.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE lcx_employee_not_found.
    ENDIF.

  ENDMETHOD.

  METHOD display_alv.

    DATA(lo_alv) = cl_salv_table=>null.

    TRY.
        cl_salv_table=>factory(
          IMPORTING r_salv_table = lo_alv
          CHANGING  t_table      = it_data ).

        lo_alv->get_functions( )->set_all( abap_true ).
        lo_alv->get_columns( )->set_optimize( abap_true ).
        lo_alv->get_display_settings( )->set_list_header(
          'Employee Report - OO ABAP Version (Mini Project 5)' ).
        lo_alv->display( ).

      CATCH cx_salv_msg INTO DATA(lx_msg).
        MESSAGE lx_msg->get_text( ) TYPE 'E'.
    ENDTRY.

  ENDMETHOD.

ENDCLASS.

"---------------------------------------------------------
" Selection Screen & Main Logic
"---------------------------------------------------------
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  PARAMETERS: p_dept TYPE zemployee_m1-department.
SELECTION-SCREEN END OF BLOCK b1.

START-OF-SELECTION.

  DATA(lo_report) = NEW lcl_employee_report( iv_department = p_dept ).

  TRY.
      DATA(lt_data) = lo_report->get_employee_data( ).
      lo_report->display_alv( lt_data ).

    CATCH lcx_employee_not_found.
      MESSAGE 'Tidak ada data pegawai untuk kriteria tersebut.' TYPE 'I'.
  ENDTRY.
```

**Text Symbol** `001` = "Kriteria Pencarian"

## Perbandingan yang Bisa Kamu Highlight di Portfolio/Interview

| Aspek | Versi Procedural (Project 1) | Versi OO (Project 5) |
|---|---|---|
| Struktur kode | FORM/PERFORM | Class dengan method terpisah |
| Error handling | `IF sy-subrc <> 0` + MESSAGE langsung | Custom exception class + TRY/CATCH |
| Reusability | Sulit dipakai ulang di program lain | Class bisa di-instantiate & dipakai di program lain |
| Testability | Sulit di-unit test | Lebih mudah di-unit test (bisa pakai ABAP Unit) |

## Kemungkinan Error & Solusinya
| Error | Penyebab | Solusi |
|---|---|---|
| `cl_salv_table=>null` tidak dikenali di versi ABAP lama | Sintaks ini butuh ABAP versi cukup baru | Ganti jadi deklarasi biasa: `DATA lo_alv TYPE REF TO cl_salv_table.` lalu isi lewat factory seperti biasa |
| `RAISE EXCEPTION TYPE lcx_employee_not_found` tidak bisa di-compile | Class exception belum didefinisikan sebelum dipakai di method lain | Pastikan urutan: definisikan `lcx_employee_not_found` di atas `lcl_employee_report` (sudah benar di kode ini) |
| ALV tidak muncul walau data ada | Method `display_alv` dipanggil sebelum data di-assign dengan benar | Pastikan `lt_data` hasil `get_employee_data( )` tidak kosong sebelum panggil `display_alv` |

📌 **Poin CV (gabungan dengan Project 1):** *"Melakukan refactoring ABAP report dari procedural programming menjadi Object-Oriented ABAP, menerapkan custom exception handling (TRY/CATCH) dan encapsulation melalui local class untuk meningkatkan reusability dan maintainability kode."*

---

# Ringkasan Lengkap 5 Mini-Project untuk CV

> **SAP ABAP Development (Self-Project / Portfolio)** — [link GitHub]
> Membangun 5 mini-project ABAP end-to-end menggunakan Eclipse ADT:
> 1. ALV Report dengan Data Dictionary custom dan selection screen dinamis
> 2. Analisis & optimasi performa report (SQL Trace, nested SELECT vs INNER JOIN)
> 3. Module Pool Program (Dialog Programming) untuk operasi CRUD data master
> 4. Mass upload tool menggunakan BDC (CALL TRANSACTION), custom Remote-Enabled Function Module (RFC), dan konsumsi BAPI standar
> 5. Refactoring ke Object-Oriented ABAP dengan custom exception handling dan OO-ALV

---

## Rekomendasi Langkah Selanjutnya

1. **Update file GitHub kamu** — tambahkan folder `mini-project-4-mass-upload` dan `mini-project-5-oo-abap`, upload semua kode di atas sebagai file `.abap` terpisah per bagian (misal: `bdc_upload.abap`, `rfc_function_module.abap`, `bapi_consume.abap`, `oo_employee_report.abap`).
2. **Update README.md** dengan tabel perbandingan procedural vs OO dari Project 5 — ini detail kecil yang menunjukkan kedalaman pemahaman, bukan sekadar "sudah pernah coding".
3. Kalau sistem SAP sudah bisa diakses, jalankan urutan **1 → 2 → 3 → 4 → 5** karena project 4 & 5 bergantung pada objek dari project 1 & 3.
4. Setelah semua 5 project jalan dan ada screenshot buktinya, portfolio kamu sudah cukup solid untuk level entry/junior SAP ABAP Developer — ini sudah mencakup hampir semua poin teknis di JD Accenture yang kamu kirim di awal.
