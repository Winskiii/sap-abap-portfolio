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
