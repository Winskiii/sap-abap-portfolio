REPORT zr_sales_join_m2.

TYPES: BEGIN OF ty_sales,
         order_no      TYPE zsd_ordhdr_m2-order_no,
         customer_name TYPE zsd_ordhdr_m2-customer_name,
         order_date    TYPE zsd_ordhdr_m2-order_date,
         item_no       TYPE zsd_orditem_m2-item_no,
         material_desc TYPE zsd_orditem_m2-material_desc,
         quantity      TYPE zsd_orditem_m2-quantity,
         price         TYPE zsd_orditem_m2-price,
         currency      TYPE zsd_orditem_m2-currency,
       END OF ty_sales.

DATA: gt_sales TYPE STANDARD TABLE OF ty_sales,
      gr_alv   TYPE REF TO cl_salv_table.

START-OF-SELECTION.

  SELECT h~order_no, h~customer_name, h~order_date,
         i~item_no, i~material_desc, i~quantity, i~price, i~currency
    FROM zsd_ordhdr_m2 AS h
    INNER JOIN zsd_orditem_m2 AS i
      ON h~order_no = i~order_no
    INTO TABLE @gt_sales
    ORDER BY h~order_no, i~item_no.

  IF sy-subrc <> 0.
    MESSAGE 'Data tidak ditemukan.' TYPE 'I'.
    RETURN.
  ENDIF.

  TRY.
      cl_salv_table=>factory(
        IMPORTING r_salv_table = gr_alv
        CHANGING  t_table      = gt_sales ).

      gr_alv->get_functions( )->set_all( abap_true ).
      gr_alv->get_columns( )->set_optimize( abap_true ).
      gr_alv->get_display_settings( )->set_list_header(
        'Sales Order Analysis - JOIN Version' ).
      gr_alv->display( ).

    CATCH cx_salv_msg INTO DATA(lx_msg).
      MESSAGE lx_msg->get_text( ) TYPE 'E'.
  ENDTRY.
