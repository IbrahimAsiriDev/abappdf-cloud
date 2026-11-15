CLASS zcl_abappdf_invoice DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_abappdf_data.

  PRIVATE SECTION.
    METHODS plain
      IMPORTING
        iv_text        TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.
ENDCLASS.



CLASS zcl_abappdf_invoice IMPLEMENTATION.

  METHOD zif_abappdf_data~read.
    DATA ls_doc TYPE zabappdf_doc.
    DATA lt_item TYPE STANDARD TABLE OF zabappdf_item WITH EMPTY KEY.
    DATA lv_key TYPE zabappdf_doc-doc_id.
    DATA lv_items TYPE string.
    DATA lv_sep TYPE string.

    lv_key = to_upper( iv_key ).
    IF lv_key IS INITIAL.
      lv_key = '10000001'.
    ENDIF.
    IF strlen( lv_key ) > 10.
      lv_key = substring( val = lv_key len = 10 ).
    ENDIF.

    SELECT SINGLE * FROM zabappdf_doc
      WHERE doc_id = @lv_key
      INTO @ls_doc.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_abappdf
        EXPORTING textid = zcx_abappdf=>document_missing msgv1 = CONV symsgv( lv_key ).
    ENDIF.

    SELECT * FROM zabappdf_item
      WHERE doc_id = @lv_key
      ORDER BY item_no
      INTO TABLE @lt_item.

    LOOP AT lt_item INTO DATA(ls_item).
      lv_items = lv_items && lv_sep &&
        |\{"MATERIAL":"{ zcl_abappdf_json=>escape( plain( CONV string( ls_item-material ) ) ) }"| &&
        |,"DESCRIPTION":"{ zcl_abappdf_json=>escape( plain( CONV string( ls_item-description ) ) ) }"| &&
        |,"QTY":"{ zcl_abappdf_json=>escape( plain( CONV string( ls_item-qty ) ) ) }"| &&
        |,"PRICE":"{ zcl_abappdf_json=>escape( plain( CONV string( ls_item-price ) ) ) }"| &&
        |,"AMOUNT":"{ zcl_abappdf_json=>escape( plain( CONV string( ls_item-amount ) ) ) }"\}|.
      lv_sep = ','.
    ENDLOOP.

    rv_json =
      |\{"INVOICE_NO":"{ zcl_abappdf_json=>escape( plain( CONV string( ls_doc-invoice_no ) ) ) }"| &&
      |,"INVOICE_DATE":"{ zcl_abappdf_json=>escape( plain( CONV string( ls_doc-invoice_date ) ) ) }"| &&
      |,"CUSTOMER":"{ zcl_abappdf_json=>escape( plain( CONV string( ls_doc-customer ) ) ) }"| &&
      |,"CURRENCY":"{ zcl_abappdf_json=>escape( plain( CONV string( ls_doc-currency ) ) ) }"| &&
      |,"ITEMS":[{ lv_items }]\}|.
  ENDMETHOD.


  METHOD plain.
    rv_text = iv_text.
    CONDENSE rv_text.
  ENDMETHOD.

ENDCLASS.
