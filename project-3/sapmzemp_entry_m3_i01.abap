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
