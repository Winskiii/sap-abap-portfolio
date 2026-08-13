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
