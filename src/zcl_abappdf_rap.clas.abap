CLASS zcl_abappdf_rap DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS print
      IMPORTING
        iv_travel_id  TYPE /dmo/travel-travel_id
      RETURNING
        VALUE(rv_pdf) TYPE xstring
      RAISING
        zcx_abappdf.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_booking,
        booking_id    TYPE string,
        carrier_id    TYPE string,
        connection_id TYPE string,
        flight_date   TYPE string,
        flight_price  TYPE string,
      END OF ty_booking,
      BEGIN OF ty_doc,
        travel_id     TYPE string,
        agency_id     TYPE string,
        customer_id   TYPE string,
        begin_date    TYPE string,
        end_date      TYPE string,
        description   TYPE string,
        status        TYPE string,
        booking_fee   TYPE string,
        total_price   TYPE string,
        currency_code TYPE string,
        bookings      TYPE STANDARD TABLE OF ty_booking WITH EMPTY KEY,
      END OF ty_doc.
ENDCLASS.



CLASS zcl_abappdf_rap IMPLEMENTATION.

  METHOD print.
    DATA ls_doc TYPE ty_doc.
    DATA ls_item TYPE ty_booking.
    DATA ls_travel TYPE /dmo/travel.
    DATA lt_booking TYPE STANDARD TABLE OF /dmo/booking WITH EMPTY KEY.

    SELECT SINGLE * FROM /dmo/travel
      WHERE travel_id = @iv_travel_id
      INTO @ls_travel.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_abappdf
        EXPORTING textid = zcx_abappdf=>travel_missing.
    ENDIF.

    SELECT * FROM /dmo/booking
      WHERE travel_id = @ls_travel-travel_id
      ORDER BY booking_id
      INTO TABLE @lt_booking.

    ls_doc-travel_id = |{ ls_travel-travel_id }|.
    ls_doc-agency_id = |{ ls_travel-agency_id }|.
    ls_doc-customer_id = |{ ls_travel-customer_id }|.
    ls_doc-begin_date = |{ ls_travel-begin_date DATE = ISO }|.
    ls_doc-end_date = |{ ls_travel-end_date DATE = ISO }|.
    ls_doc-description = |{ ls_travel-description }|.
    ls_doc-status = |{ ls_travel-status }|.
    ls_doc-booking_fee = |{ ls_travel-booking_fee DECIMALS = 2 }|.
    ls_doc-total_price = |{ ls_travel-total_price DECIMALS = 2 }|.
    ls_doc-currency_code = |{ ls_travel-currency_code }|.
    CONDENSE: ls_doc-travel_id, ls_doc-agency_id, ls_doc-customer_id,
              ls_doc-description, ls_doc-status, ls_doc-currency_code.

    LOOP AT lt_booking INTO DATA(ls_book).
      CLEAR ls_item.
      ls_item-booking_id = |{ ls_book-booking_id }|.
      ls_item-carrier_id = |{ ls_book-carrier_id }|.
      ls_item-connection_id = |{ ls_book-connection_id }|.
      ls_item-flight_date = |{ ls_book-flight_date DATE = ISO }|.
      ls_item-flight_price = |{ ls_book-flight_price DECIMALS = 2 }|.
      CONDENSE: ls_item-booking_id, ls_item-carrier_id, ls_item-connection_id.
      APPEND ls_item TO ls_doc-bookings.
    ENDLOOP.

    "Users who log on in Arabic get the right-to-left demo form.
    DATA(lv_form) = zcl_abappdf_config=>demo_form_id.
    TRY.
        IF cl_abap_context_info=>get_user_language_abap_format( ) = 'A'.
          lv_form = zcl_abappdf_config=>demo_form_id_ar.
        ENDIF.
      CATCH cx_root.
    ENDTRY.
    TRY.
        zcl_abappdf_forms=>read_active( lv_form ).
      CATCH zcx_abappdf.
        "Fresh install: the demo form is not in the form store yet. Print with the
        "built-in copy; a RAP action must not write the form store itself.
        DATA(ls_template) = zcl_abappdf_demo=>template_of( lv_form ).
        rv_pdf = zcl_abappdf_api=>render_parts(
          iv_html   = ls_template-html
          iv_css    = ls_template-css
          iv_header = ls_template-header
          iv_footer = ls_template-footer
          is_page   = CORRESPONDING #( ls_template )
          is_data   = ls_doc ).
        RETURN.
    ENDTRY.
    rv_pdf = zcl_abappdf_api=>render_pdf(
      iv_form_id = lv_form
      is_data    = ls_doc ).
  ENDMETHOD.

ENDCLASS.
