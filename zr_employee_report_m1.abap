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
