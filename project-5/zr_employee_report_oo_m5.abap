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
