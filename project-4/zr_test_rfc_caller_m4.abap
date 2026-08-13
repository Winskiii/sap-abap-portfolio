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
