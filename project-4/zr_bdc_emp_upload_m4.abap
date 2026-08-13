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
