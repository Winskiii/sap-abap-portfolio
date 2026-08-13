PROGRAM sapmzemp_entry_m3.

TABLES: zemployee_m1.

DATA: ok_code   TYPE sy-ucomm,
      gv_msg    TYPE string,
      gv_mode   TYPE c LENGTH 1 VALUE 'C'.  " C = Create, U = Update, D = Delete
