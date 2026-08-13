# Mini Project 1–3 SAP ABAP — Kode Lengkap & Langkah Detail

> Catatan penting di awal: kode di bawah ini sudah saya susun mengikuti sintaks ABAP standar (kompatibel ABAP 7.40+ / on-premise maupun BTP ABAP Environment) dan sudah saya cek logikanya baris per baris. Tapi karena saya tidak punya akses ke sistem SAP nyata untuk mengeksekusinya, **saya tidak bisa 100% menjamin "tanpa error"** — di SAP, error sering muncul dari hal-hal yang sifatnya environment-specific (nama objek yang bentrok, otorisasi, package, transport request, versi sistem). Yang bisa saya jamin: struktur, sintaks, dan logikanya sudah benar sesuai standar ABAP. Di bagian akhir tiap project saya kasih "Kemungkinan Error & Solusinya" supaya kalau ada masalah pas kamu jalankan, kamu tinggal cocokkan.

---

# 🔧 Prasyarat Sebelum Mulai

Karena BTP Trial kamu bermasalah, ini alternatif akses sistem SAP untuk latihan:

| Opsi | Keterangan |
|---|---|
| **A. Coba lagi BTP Trial nanti** | Masalah pendaftaran BTP trial cukup sering terjadi karena region/kapasitas. Coba ganti region saat signup (misal pilih US East/Europe Frankfurt), atau coba di jam yang berbeda. |
| **B. ABAP Platform Trial via Docker (self-hosted)** | SAP menyediakan image Docker berisi sistem ABAP trial (server NPL) yang bisa dijalankan di VM (GCP/AWS/lokal dengan RAM besar) tanpa perlu approval BTP. Cocok kalau kamu sudah familiar Docker/Cloud VM. |
| **C. Minta akses sandbox** | Beberapa komunitas/forum SAP Indonesia (grup Telegram/Facebook "SAP ABAP Indonesia") kadang share akses sandbox bersama untuk belajar. |

Untuk sekarang, **kode di bawah bisa kamu simpan dulu**, dan begitu akses sistem sudah ada, tinggal copy-paste ke ADT (New ABAP Program / New Database Table) di project Eclipse kamu.

---

# 📁 MINI PROJECT 1 — Employee Report Generator (ALV Report)

## Tujuan
Menunjukkan kemampuan: Data Dictionary, Internal Table, ALV Grid, Selection Screen — semua poin dasar yang diminta di JD.

## Langkah 1 — Buat Database Table di ADT

Di Eclipse ADT: klik kanan project → **New → Other ABAP Repository Object → Dictionary → Database Table**

Nama: `ZEMPLOYEE_M1` (prefix Z wajib untuk custom object)

Isi definisi tabel (buka source-based editor di ADT, paste ini):

```abap
@EndUserText.label : 'Employee Master - Mini Project 1'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zemployee_m1 {
  key client      : mandt not null;
  key emp_no      : char10 not null;
  emp_name        : char40;
  department      : char20;
  salary          : abap.dec(10,2);
  hire_date       : abap.dats;
}
```

Simpan → Activate (Ctrl+F3).

> Kalau ADT kamu belum support DDL source langsung untuk tabel (tergantung backend), buat via klasik: SE11 → Database Table → isi field manual (MANDT, EMP_NO, EMP_NAME, DEPARTMENT, SALARY, HIRE_DATE) dengan tipe data yang sama.

## Langkah 2 — Isi Data Testing (opsional, via SE16/SE16N)

Masukkan 5–10 baris data dummy pegawai manual lewat SE16N → Create Entries, supaya report ada isinya.

## Langkah 3 — Buat Program ABAP (ALV Report)

New → ABAP Program, nama: `ZR_EMPLOYEE_REPORT_M1`

```abap
REPORT zr_employee_report_m1.

TABLES: zemployee_m1.

"---------------------------------------------------------
" Selection Screen
"---------------------------------------------------------
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  SELECT-OPTIONS: s_dept FOR zemployee_m1-department,
                   s_sal  FOR zemployee_m1-salary.
SELECTION-SCREEN END OF BLOCK b1.

"---------------------------------------------------------
" Data Declaration
"---------------------------------------------------------
TYPES: BEGIN OF ty_employee,
         emp_no     TYPE zemployee_m1-emp_no,
         emp_name   TYPE zemployee_m1-emp_name,
         department TYPE zemployee_m1-department,
         salary     TYPE zemployee_m1-salary,
         hire_date  TYPE zemployee_m1-hire_date,
       END OF ty_employee.

DATA: gt_employee TYPE STANDARD TABLE OF ty_employee,
      gr_alv      TYPE REF TO cl_salv_table,
      gr_columns  TYPE REF TO cl_salv_columns_table,
      gr_column   TYPE REF TO cl_salv_column_table.

"---------------------------------------------------------
" START-OF-SELECTION
"---------------------------------------------------------
START-OF-SELECTION.

  SELECT emp_no, emp_name, department, salary, hire_date
    FROM zemployee_m1
    WHERE department IN @s_dept
      AND salary     IN @s_sal
    INTO TABLE @gt_employee.

  IF sy-subrc <> 0.
    MESSAGE 'Tidak ada data ditemukan untuk kriteria tersebut.' TYPE 'I'.
    RETURN.
  ENDIF.

  PERFORM display_alv.

"---------------------------------------------------------
" FORM: Tampilkan ALV
"---------------------------------------------------------
FORM display_alv.

  TRY.
      cl_salv_table=>factory(
        IMPORTING
          r_salv_table = gr_alv
        CHANGING
          t_table      = gt_employee ).

      " Aktifkan fitur standar ALV
      gr_alv->get_functions( )->set_all( abap_true ).

      " Sorting kolom
      gr_alv->get_columns( )->set_optimize( abap_true ).

      " Judul kolom custom (contoh untuk salary)
      gr_columns = gr_alv->get_columns( ).
      gr_column ?= gr_columns->get_column( 'SALARY' ).
      gr_column->set_short_text( 'Gaji' ).
      gr_column->set_medium_text( 'Gaji (IDR)' ).

      " Judul report
      gr_alv->get_display_settings( )->set_list_header(
        'Laporan Data Pegawai - Mini Project 1' ).

      gr_alv->display( ).

    CATCH cx_salv_msg INTO DATA(lx_msg).
      MESSAGE lx_msg->get_text( ) TYPE 'E'.
  ENDTRY.

ENDFORM.
```

**Text Symbol** yang perlu dibuat (Properties → Text Symbols di ADT): `001` = "Kriteria Pencarian"

## Langkah 4 — Test Run
Jalankan program (F8), isi filter department/salary (boleh kosong = tampilkan semua), lihat hasil ALV.

## Kemungkinan Error & Solusinya
| Error | Penyebab | Solusi |
|---|---|---|
| `Field ZEMPLOYEE_M1-DEPARTMENT is unknown` | Tabel belum di-activate atau nama field beda | Pastikan Activate tabel dulu sebelum bikin program |
| `TABLE_INVALID_INDEX` / dump saat display ALV | `gt_employee` kosong tapi tetap dipanggil `cl_salv_table=>factory` | Sudah di-handle lewat pengecekan `sy-subrc <> 0` di atas |
| Warning "unused variable" | Umum kalau ada deklarasi tak terpakai | Bukan error fatal, aman diabaikan atau hapus variabel yang tak dipakai |

📌 **Poin CV:** *"Membangun ABAP report dengan ALV Grid (cl_salv_table), selection screen dinamis, dan filtering data menggunakan Open SQL modern (ABAP 7.40+)."*

---

# 📁 MINI PROJECT 2 — Sales Data Analysis (Multi-table + Performance Tuning)

## Tujuan
Menunjukkan: relasi antar tabel, JOIN vs nested SELECT, performance tuning (poin penting di JD: "Knowledgeable in SQL Trace, SAP Run time analysis").

## Langkah 1 — Buat 2 Tabel

**Tabel Header** — `ZSD_ORDHDR_M2`
```abap
@EndUserText.label : 'Sales Order Header - Mini Project 2'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zsd_ordhdr_m2 {
  key client     : mandt not null;
  key order_no   : char10 not null;
  customer_name  : char40;
  order_date     : abap.dats;
  currency       : abap.cuky;
}
```

**Tabel Item** — `ZSD_ORDITEM_M2`
```abap
@EndUserText.label : 'Sales Order Item - Mini Project 2'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zsd_orditem_m2 {
  key client     : mandt not null;
  key order_no   : char10 not null;
  key item_no    : char5 not null;
  material_desc  : char40;
  quantity       : abap.dec(9,2);
  price          : abap.dec(10,2) with currency currency;
  currency       : abap.cuky;
}
```

Isi 3–5 order header, masing-masing 2–3 item, via SE16N.

## Langkah 2 — Program Versi "Tidak Efisien" (Nested SELECT)

Buat program `ZR_SALES_NESTED_M2` — ini contoh **anti-pattern** yang sengaja dibuat untuk dibandingkan (dan ditunjukkan saat interview kamu paham kenapa ini buruk):

```abap
REPORT zr_sales_nested_m2.

DATA: gt_header TYPE STANDARD TABLE OF zsd_ordhdr_m2,
      gt_result TYPE STANDARD TABLE OF zsd_orditem_m2.

START-OF-SELECTION.

  SELECT * FROM zsd_ordhdr_m2 INTO TABLE @gt_header.

  " ANTI-PATTERN: SELECT di dalam LOOP -> menyebabkan banyak roundtrip DB
  LOOP AT gt_header INTO DATA(ls_header).
    SELECT * FROM zsd_orditem_m2
      INTO TABLE @DATA(lt_item)
      WHERE order_no = @ls_header-order_no.

    APPEND LINES OF lt_item TO gt_result.
  ENDLOOP.

  cl_demo_output=>display( gt_result ).
```

## Langkah 3 — Program Versi "Efisien" (JOIN)

Buat program `ZR_SALES_JOIN_M2` — versi yang benar dan performant:

```abap
REPORT zr_sales_join_m2.

TYPES: BEGIN OF ty_sales,
         order_no      TYPE zsd_ordhdr_m2-order_no,
         customer_name TYPE zsd_ordhdr_m2-customer_name,
         order_date    TYPE zsd_ordhdr_m2-order_date,
         item_no       TYPE zsd_orditem_m2-item_no,
         material_desc TYPE zsd_orditem_m2-material_desc,
         quantity      TYPE zsd_orditem_m2-quantity,
         price         TYPE zsd_orditem_m2-price,
         currency      TYPE zsd_orditem_m2-currency,
       END OF ty_sales.

DATA: gt_sales TYPE STANDARD TABLE OF ty_sales,
      gr_alv   TYPE REF TO cl_salv_table.

START-OF-SELECTION.

  SELECT h~order_no, h~customer_name, h~order_date,
         i~item_no, i~material_desc, i~quantity, i~price, i~currency
    FROM zsd_ordhdr_m2 AS h
    INNER JOIN zsd_orditem_m2 AS i
      ON h~order_no = i~order_no
    INTO TABLE @gt_sales
    ORDER BY h~order_no, i~item_no.

  IF sy-subrc <> 0.
    MESSAGE 'Data tidak ditemukan.' TYPE 'I'.
    RETURN.
  ENDIF.

  TRY.
      cl_salv_table=>factory(
        IMPORTING r_salv_table = gr_alv
        CHANGING  t_table      = gt_sales ).

      gr_alv->get_functions( )->set_all( abap_true ).
      gr_alv->get_columns( )->set_optimize( abap_true ).
      gr_alv->get_display_settings( )->set_list_header(
        'Sales Order Analysis - JOIN Version' ).
      gr_alv->display( ).

    CATCH cx_salv_msg INTO DATA(lx_msg).
      MESSAGE lx_msg->get_text( ) TYPE 'E'.
  ENDTRY.
```

## Langkah 4 — Lakukan Performance Tuning (bukti nyata untuk CV)

1. Jalankan **SQL Trace** — transaksi `ST05` (atau lewat ADT: klik kanan project → Profiling Tools bila tersedia)
2. Aktifkan trace, jalankan `ZR_SALES_NESTED_M2`, matikan trace, lihat hasil (jumlah `SELECT` statement ke database)
3. Ulangi untuk `ZR_SALES_JOIN_M2`
4. **Screenshot perbandingan jumlah DB call & response time** antara kedua versi — ini bukti konkret skill performance tuning yang bisa dilampirkan di portfolio.

Contoh hasil yang biasanya kamu dapat: versi nested SELECT menghasilkan N+1 query (1 query header + N query item), sedangkan versi JOIN hanya 1 query — response time jauh lebih rendah pada data besar.

## Kemungkinan Error & Solusinya
| Error | Penyebab | Solusi |
|---|---|---|
| `SQL error: unknown table` | Belum aktivasi salah satu tabel | Cek kedua tabel sudah "Active" (hijau) di ADT |
| Hasil JOIN kosong padahal data ada | Field `order_no` di kedua tabel beda tipe/panjang | Pastikan `order_no` sama persis CHAR10 di kedua tabel |
| `cl_demo_output` tidak dikenali di sistem versi lama | Class ini hanya ada di sistem tertentu | Ganti dengan `cl_salv_table` seperti di versi JOIN, atau `WRITE:` sederhana |

📌 **Poin CV:** *"Melakukan analisis dan optimasi performa ABAP report menggunakan SQL Trace (ST05), membandingkan nested SELECT vs INNER JOIN untuk mengurangi database roundtrip."*

---

# 📁 MINI PROJECT 3 — Dialog Programming: Employee Data Entry Screen

## Tujuan
Menunjukkan kemampuan **Module Pool / Dialog Programming** — poin utama pertama di JD requirement kamu.

> Catatan: Dialog Programming murni berbasis GUI Screen Painter (SE51) yang didesain visual, bukan pure text-code seperti report. Di bawah saya berikan **seluruh source code** (flow logic + ABAP module) yang perlu kamu ketik/paste, plus struktur field screen yang harus kamu buat manual di Screen Painter.

## Langkah 1 — Buat Program Module Pool

New → ABAP Program → centang **"With TOP Include"**, tipe: **Module Pool** (di ADT: New → Program, lalu di Properties ubah Program Type jadi "M - Module Pool"), nama: `SAPMZEMP_ENTRY_M3`

**Top Include (`SAPMZEMP_ENTRY_M3_TOP`):**
```abap
PROGRAM sapmzemp_entry_m3.

TABLES: zemployee_m1.

DATA: ok_code   TYPE sy-ucomm,
      gv_msg    TYPE string,
      gv_mode   TYPE c LENGTH 1 VALUE 'C'.  " C = Create, U = Update, D = Delete
```

## Langkah 2 — Buat Screen 100 (Screen Painter)

Di ADT/SE51, buat **Screen 0100**, layout field sederhana (drag field dari tabel `ZEMPLOYEE_M1` ke screen):
- `ZEMPLOYEE_M1-EMP_NO` (input)
- `ZEMPLOYEE_M1-EMP_NAME` (input)
- `ZEMPLOYEE_M1-DEPARTMENT` (input)
- `ZEMPLOYEE_M1-SALARY` (input)
- `ZEMPLOYEE_M1-HIRE_DATE` (input)
- Tombol/PF-Status dengan fungsi: `SAVE`, `DELETE`, `BACK`, `EXIT`

**Flow Logic Screen 0100:**
```abap
PROCESS BEFORE OUTPUT.
  MODULE status_0100.

PROCESS AFTER INPUT.
  MODULE user_command_0100.
```

## Langkah 3 — Modul PBO (Process Before Output)

Buat include `SAPMZEMP_ENTRY_M3_O01`:
```abap
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'STATUS_0100'.
  SET TITLEBAR 'TITLE_0100'.
ENDMODULE.
```

(PF-Status `STATUS_0100` perlu dibuat lewat menu GUI Status di ADT/SE51 dengan fungsi: SAVE, DELETE, BACK, EXIT)

## Langkah 4 — Modul PAI (Process After Input)

Buat include `SAPMZEMP_ENTRY_M3_I01`:
```abap
MODULE user_command_0100 INPUT.

  CASE ok_code.

    WHEN 'SAVE'.
      PERFORM save_employee.

    WHEN 'DELETE'.
      PERFORM delete_employee.

    WHEN 'BACK' OR 'EXIT'.
      LEAVE PROGRAM.

  ENDCASE.

  CLEAR ok_code.

ENDMODULE.

"-----------------------------------------------------------
FORM save_employee.

  IF zemployee_m1-emp_no IS INITIAL.
    MESSAGE 'Employee Number wajib diisi.' TYPE 'E'.
    RETURN.
  ENDIF.

  " Cek apakah data sudah ada (Update) atau belum (Insert)
  SELECT SINGLE @abap_true FROM zemployee_m1
    WHERE emp_no = @zemployee_m1-emp_no
    INTO @DATA(lv_exists).

  IF lv_exists = abap_true.
    UPDATE zemployee_m1 SET emp_name   = zemployee_m1-emp_name,
                             department = zemployee_m1-department,
                             salary     = zemployee_m1-salary,
                             hire_date  = zemployee_m1-hire_date
                       WHERE emp_no = zemployee_m1-emp_no.
    MESSAGE 'Data pegawai berhasil di-update.' TYPE 'S'.
  ELSE.
    INSERT INTO zemployee_m1 VALUES zemployee_m1.
    MESSAGE 'Data pegawai baru berhasil disimpan.' TYPE 'S'.
  ENDIF.

  COMMIT WORK.

ENDFORM.

"-----------------------------------------------------------
FORM delete_employee.

  IF zemployee_m1-emp_no IS INITIAL.
    MESSAGE 'Employee Number wajib diisi untuk delete.' TYPE 'E'.
    RETURN.
  ENDIF.

  DELETE FROM zemployee_m1 WHERE emp_no = zemployee_m1-emp_no.

  IF sy-subrc = 0.
    MESSAGE 'Data pegawai berhasil dihapus.' TYPE 'S'.
    CLEAR zemployee_m1.
  ELSE.
    MESSAGE 'Data tidak ditemukan.' TYPE 'E'.
  ENDIF.

  COMMIT WORK.

ENDFORM.
```

## Langkah 5 — Buat Transaction Code (opsional tapi nilai plus)

Transaksi `SE93` → buat T-Code `ZEMP_ENTRY_M3` yang memanggil program `SAPMZEMP_ENTRY_M3` screen `0100`. Ini menunjukkan kamu paham cara "membungkus" program jadi transaksi siap pakai — poin plus di interview.

## (Lanjutan Opsional) Cetak "Slip Data" Sederhana — Pengganti Smart Forms untuk Latihan Cepat

Sebelum masuk Smart Forms penuh (butuh transaksi `SMARTFORMS`, agak berat untuk latihan awal), kamu bisa buat dulu print-preview sederhana pakai `WRITE` sebagai simulasi:

```abap
REPORT zr_employee_slip_m3.

PARAMETERS: p_empno TYPE zemployee_m1-emp_no OBLIGATORY.

START-OF-SELECTION.

  SELECT SINGLE * FROM zemployee_m1
    WHERE emp_no = @p_empno
    INTO @DATA(ls_emp).

  IF sy-subrc <> 0.
    MESSAGE 'Data pegawai tidak ditemukan.' TYPE 'E'.
    RETURN.
  ENDIF.

  WRITE: / '========================================='.
  WRITE: / '           SLIP DATA PEGAWAI              '.
  WRITE: / '========================================='.
  WRITE: / 'Employee No  :', ls_emp-emp_no.
  WRITE: / 'Nama         :', ls_emp-emp_name.
  WRITE: / 'Departemen   :', ls_emp-department.
  WRITE: / 'Gaji         :', ls_emp-salary CURRENCY 'IDR'.
  WRITE: / 'Tgl Masuk    :', ls_emp-hire_date.
  WRITE: / '========================================='.
```

*(Versi Smart Forms sesungguhnya akan kita buat di project lanjutan/mini project 4, karena butuh desain visual via transaksi SMARTFORMS yang perlu tutorial screenshot-by-screenshot terpisah.)*

## Kemungkinan Error & Solusinya
| Error | Penyebab | Solusi |
|---|---|---|
| `Screen 0100 does not exist` | Screen belum dibuat/di-generate di Screen Painter | Buat dulu screen-nya lewat SE51/ADT Screen Painter sebelum aktivasi program |
| `Field ZEMPLOYEE_M1-EMP_NO is not an input field` | Field di screen belum diset attribute "Input" | Di Screen Painter, centang atribut Input pada tiap field |
| `PF-Status STATUS_0100 not found` | GUI Status belum dibuat | Buat via menu Goto → PF-Status di Screen Painter/ADT, tambahkan fungsi SAVE/DELETE/BACK/EXIT |
| `MESSAGE` type E tapi program tidak stop | Behavior normal ABAP: MESSAGE type E di dalam PAI otomatis kembali ke screen | Ini bukan bug, memang begitu perilakunya |

📌 **Poin CV:** *"Mengembangkan Module Pool Program (Dialog Programming) untuk create/update/delete data master, termasuk PF-Status, flow logic PBO/PAI, dan custom Transaction Code."*

---

# Ringkasan yang Bisa Langsung Ditulis di CV Setelah 3 Project Ini

> **SAP ABAP Development (Self-Project / Portfolio)**
> Mengembangkan 3 mini-project ABAP end-to-end menggunakan Eclipse ADT: (1) ALV Report dengan Data Dictionary custom dan selection screen dinamis; (2) analisis performa report multi-tabel menggunakan SQL Trace, membandingkan pendekatan nested SELECT vs INNER JOIN; (3) Module Pool Program (Dialog Programming) untuk operasi CRUD data master pegawai lengkap dengan custom Transaction Code.

---

## Langkah Selanjutnya
1. Begitu akses sistem SAP sudah ada (BTP trial jalan / docker / sandbox komunitas), copy-paste tiap blok kode sesuai urutan di atas.
2. Kalau nanti ada error spesifik pas eksekusi (bukan dari kode ini tapi dari environment), kirim screenshot error-nya ke saya — saya bantu debug langsung.
3. Setelah 3 project ini jalan, kita lanjut ke **Mini Project 4 (BDC/RFC/BAPI)** dan **Smart Forms sungguhan** sesuai roadmap awal.
