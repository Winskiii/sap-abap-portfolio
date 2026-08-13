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
