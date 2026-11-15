CLASS zcl_abappdf_travel DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_abappdf_data.

    CLASS-METHODS build
      IMPORTING
        iv_key         TYPE string
      EXPORTING
        ev_id          TYPE string
      RETURNING
        VALUE(rv_json) TYPE string
      RAISING
        zcx_abappdf.

  PRIVATE SECTION.
    CLASS-METHODS plain
      IMPORTING
        iv_text        TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.
ENDCLASS.



CLASS zcl_abappdf_travel IMPLEMENTATION.

  METHOD zif_abappdf_data~read.
    rv_json = build( iv_key ).
  ENDMETHOD.


  METHOD build.
    DATA ls_travel TYPE /dmo/travel.
    DATA lt_booking TYPE STANDARD TABLE OF /dmo/booking WITH EMPTY KEY.
    DATA lv_key TYPE string.
    DATA lv_id TYPE /dmo/travel-travel_id.
    DATA lv_items TYPE string.
    DATA lv_sep TYPE string.
    DATA lv_found TYPE abap_bool.

    lv_key = iv_key.
    CONDENSE lv_key NO-GAPS.
    IF lv_key CN '0123456789'.
      CLEAR lv_key.
    ENDIF.
    IF strlen( lv_key ) > 8.
      lv_key = substring( val = lv_key off = strlen( lv_key ) - 8 len = 8 ).
    ENDIF.
    IF lv_key IS NOT INITIAL.
      lv_id = lv_key.
      SELECT SINGLE * FROM /dmo/travel
        WHERE travel_id = @lv_id
        INTO @ls_travel.
      IF sy-subrc = 0.
        lv_found = abap_true.
      ENDIF.
    ENDIF.

    IF lv_found = abap_false.
      SELECT * FROM /dmo/travel
        ORDER BY travel_id
        INTO TABLE @DATA(lt_travel)
        UP TO 1 ROWS.
      IF lt_travel IS INITIAL.
        RAISE EXCEPTION TYPE zcx_abappdf
          EXPORTING textid = zcx_abappdf=>travel_missing.
      ENDIF.
      ls_travel = lt_travel[ 1 ].
    ENDIF.

    SELECT * FROM /dmo/booking
      WHERE travel_id = @ls_travel-travel_id
      ORDER BY booking_id
      INTO TABLE @lt_booking.

    LOOP AT lt_booking INTO DATA(ls_book).
      lv_items = lv_items && lv_sep &&
        |\{"BOOKING_ID":"{ zcl_abappdf_json=>escape( plain( CONV string( ls_book-booking_id ) ) ) }"| &&
        |,"CARRIER_ID":"{ zcl_abappdf_json=>escape( plain( CONV string( ls_book-carrier_id ) ) ) }"| &&
        |,"CONNECTION_ID":"{ zcl_abappdf_json=>escape( plain( CONV string( ls_book-connection_id ) ) ) }"| &&
        |,"FLIGHT_DATE":"{ zcl_abappdf_json=>escape( |{ ls_book-flight_date DATE = ISO }| ) }"| &&
        |,"FLIGHT_PRICE":"{ zcl_abappdf_json=>escape( |{ ls_book-flight_price DECIMALS = 2 }| ) }"\}|.
      lv_sep = ','.
    ENDLOOP.

    ev_id = |{ ls_travel-travel_id }|.
    CONDENSE ev_id.
    rv_json =
      |\{"TRAVEL_ID":"{ zcl_abappdf_json=>escape( plain( CONV string( ls_travel-travel_id ) ) ) }"| &&
      |,"AGENCY_ID":"{ zcl_abappdf_json=>escape( plain( CONV string( ls_travel-agency_id ) ) ) }"| &&
      |,"CUSTOMER_ID":"{ zcl_abappdf_json=>escape( plain( CONV string( ls_travel-customer_id ) ) ) }"| &&
      |,"BEGIN_DATE":"{ zcl_abappdf_json=>escape( |{ ls_travel-begin_date DATE = ISO }| ) }"| &&
      |,"END_DATE":"{ zcl_abappdf_json=>escape( |{ ls_travel-end_date DATE = ISO }| ) }"| &&
      |,"DESCRIPTION":"{ zcl_abappdf_json=>escape( plain( CONV string( ls_travel-description ) ) ) }"| &&
      |,"STATUS":"{ zcl_abappdf_json=>escape( plain( CONV string( ls_travel-status ) ) ) }"| &&
      |,"BOOKING_FEE":"{ zcl_abappdf_json=>escape( |{ ls_travel-booking_fee DECIMALS = 2 }| ) }"| &&
      |,"TOTAL_PRICE":"{ zcl_abappdf_json=>escape( |{ ls_travel-total_price DECIMALS = 2 }| ) }"| &&
      |,"CURRENCY_CODE":"{ zcl_abappdf_json=>escape( plain( CONV string( ls_travel-currency_code ) ) ) }"| &&
      |,"BOOKINGS":[{ lv_items }]\}|.
  ENDMETHOD.


  METHOD plain.
    rv_text = iv_text.
    CONDENSE rv_text.
  ENDMETHOD.

ENDCLASS.
