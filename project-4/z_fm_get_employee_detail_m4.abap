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
