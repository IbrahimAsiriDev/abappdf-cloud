CLASS zcl_abappdf_gotenberg DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS render
      IMPORTING
        iv_html       TYPE string
        iv_css        TYPE string OPTIONAL
        iv_header     TYPE string OPTIONAL
        iv_footer     TYPE string OPTIONAL
        is_page       TYPE zcl_abappdf_renderer=>ty_page OPTIONAL
      RETURNING
        VALUE(rv_pdf) TYPE xstring
      RAISING
        zcx_abappdf.

  PRIVATE SECTION.
    CLASS-METHODS compose
      IMPORTING
        iv_html        TYPE string
        iv_css         TYPE string
        iv_page_css    TYPE string
      RETURNING
        VALUE(rv_html) TYPE string.

    CLASS-METHODS page_css
      IMPORTING
        is_page        TYPE zcl_abappdf_renderer=>ty_page
      EXPORTING
        ev_width       TYPE string
        ev_height      TYPE string
        ev_css         TYPE string.

    CLASS-METHODS append_file
      IMPORTING
        iv_boundary TYPE string
        iv_filename TYPE string
        iv_content  TYPE string
      CHANGING
        cv_body     TYPE string.

    CLASS-METHODS append_field
      IMPORTING
        iv_boundary TYPE string
        iv_name     TYPE string
        iv_value    TYPE string
      CHANGING
        cv_body     TYPE string.
ENDCLASS.



CLASS zcl_abappdf_gotenberg IMPLEMENTATION.

  METHOD render.
    DATA ls_page TYPE zcl_abappdf_renderer=>ty_page.
    DATA lv_width TYPE string.
    DATA lv_height TYPE string.
    DATA lv_css TYPE string.
    DATA lv_html TYPE string.
    DATA lv_body TYPE string.
    DATA lv_boundary TYPE string VALUE zcl_abappdf_config=>multipart_boundary.
    DATA lv_dest_name TYPE string.
    DATA lo_dest TYPE REF TO if_http_destination.
    DATA lo_client TYPE REF TO if_web_http_client.
    DATA lo_request TYPE REF TO if_web_http_request.
    DATA lo_response TYPE REF TO if_web_http_response.
    DATA lv_nl TYPE string.
    DATA lv_provider TYPE string VALUE 'CL_HTTP_DESTINATION_PROVIDER'.
    DATA lv_sig TYPE x LENGTH 4 VALUE zcl_abappdf_config=>pdf_signature.

    lv_dest_name = zcl_abappdf_forms=>get_config( zcl_abappdf_config=>param_gotenberg_destination ).
    SHIFT lv_dest_name LEFT DELETING LEADING space.
    IF lv_dest_name IS INITIAL.
      RAISE EXCEPTION TYPE zcx_abappdf EXPORTING textid = zcx_abappdf=>gotenberg_destination.
    ENDIF.
    ls_page = is_page.
    IF ls_page-page_size IS INITIAL.
      ls_page-page_size = zcl_abappdf_config=>page_a4.
      ls_page-orientation = zcl_abappdf_config=>orient_portrait.
    ENDIF.
    zcl_abappdf_renderer=>validate_page( ls_page ).
    page_css(
      EXPORTING is_page = ls_page
      IMPORTING ev_width = lv_width ev_height = lv_height ev_css = lv_css ).
    lv_html = compose( iv_html = iv_html iv_css = iv_css iv_page_css = lv_css ).
    lv_nl = cl_abap_char_utilities=>cr_lf.
    append_file(
      EXPORTING iv_boundary = lv_boundary iv_filename = 'index.html' iv_content = lv_html
      CHANGING cv_body = lv_body ).
    IF iv_header IS NOT INITIAL.
      append_file(
        EXPORTING iv_boundary = lv_boundary iv_filename = 'header.html'
                  iv_content = compose( iv_html = iv_header iv_css = '' iv_page_css = '' )
        CHANGING cv_body = lv_body ).
    ENDIF.
    IF iv_footer IS NOT INITIAL.
      append_file(
        EXPORTING iv_boundary = lv_boundary iv_filename = 'footer.html'
                  iv_content = compose( iv_html = iv_footer iv_css = '' iv_page_css = '' )
        CHANGING cv_body = lv_body ).
    ENDIF.
    append_field( EXPORTING iv_boundary = lv_boundary iv_name = 'paperWidth' iv_value = lv_width CHANGING cv_body = lv_body ).
    append_field( EXPORTING iv_boundary = lv_boundary iv_name = 'paperHeight' iv_value = lv_height CHANGING cv_body = lv_body ).
    append_field( EXPORTING iv_boundary = lv_boundary iv_name = 'marginTop' iv_value = |{ ls_page-margin_top }{ zcl_abappdf_config=>unit_mm }| CHANGING cv_body = lv_body ).
    append_field( EXPORTING iv_boundary = lv_boundary iv_name = 'marginBottom' iv_value = |{ ls_page-margin_bottom }{ zcl_abappdf_config=>unit_mm }| CHANGING cv_body = lv_body ).
    append_field( EXPORTING iv_boundary = lv_boundary iv_name = 'marginLeft' iv_value = |{ ls_page-margin_left }{ zcl_abappdf_config=>unit_mm }| CHANGING cv_body = lv_body ).
    append_field( EXPORTING iv_boundary = lv_boundary iv_name = 'marginRight' iv_value = |{ ls_page-margin_right }{ zcl_abappdf_config=>unit_mm }| CHANGING cv_body = lv_body ).
    append_field( EXPORTING iv_boundary = lv_boundary iv_name = 'printBackground' iv_value = 'true' CHANGING cv_body = lv_body ).
    append_field( EXPORTING iv_boundary = lv_boundary iv_name = 'preferCssPageSize' iv_value = 'true' CHANGING cv_body = lv_body ).
    append_field( EXPORTING iv_boundary = lv_boundary iv_name = 'emulatedMediaType' iv_value = 'print' CHANGING cv_body = lv_body ).
    lv_body = lv_body && '--' && lv_boundary && '--' && lv_nl.

    TRY.
        " Called dynamically so the class still compiles on releases
        " that ship without CL_HTTP_DESTINATION_PROVIDER (older on-premise).
        CALL METHOD (lv_provider)=>('CREATE_BY_CLOUD_DESTINATION')
          EXPORTING
            i_name             = lv_dest_name
          RECEIVING
            r_http_destination = lo_dest.
        lo_client = cl_web_http_client_manager=>create_by_http_destination( i_destination = lo_dest ).
        lo_request = lo_client->get_http_request( ).
        lo_request->set_uri_path( i_uri_path = zcl_abappdf_config=>gotenberg_path ).
        lo_request->set_header_field(
          i_name  = 'content-type'
          i_value = |multipart/form-data; boundary={ lv_boundary }| ).
        lo_request->set_binary( i_data = cl_abap_conv_codepage=>create_out( )->convert( lv_body ) ).
        lo_response = lo_client->execute( if_web_http_client=>post ).
        IF lo_response->get_status( )-code <> 200.
          DATA(lv_error) = lo_response->get_text( ).
          IF strlen( lv_error ) > 500.
            lv_error = substring( val = lv_error len = 500 ).
          ENDIF.
          RAISE EXCEPTION TYPE zcx_abappdf
            EXPORTING
              textid   = zcx_abappdf=>gotenberg_http
              msgv1    = CONV symsgv( lo_response->get_status( )-code )
              msgv2    = CONV symsgv( lv_error )
              longtext = |Gotenberg HTTP { lo_response->get_status( )-code }: { lv_error }|.
        ENDIF.
        rv_pdf = lo_response->get_binary( ).
      CATCH zcx_abappdf INTO DATA(lx_pdf).
        RAISE EXCEPTION lx_pdf.
      CATCH cx_root INTO DATA(lx_error).
        RAISE EXCEPTION TYPE zcx_abappdf
          EXPORTING
            textid   = zcx_abappdf=>gotenberg_failed
            previous = lx_error
            msgv1    = CONV symsgv( lx_error->get_text( ) )
            longtext = |Gotenberg call failed: { lx_error->get_text( ) }|.
    ENDTRY.
    IF xstrlen( rv_pdf ) < 5 OR rv_pdf(4) <> lv_sig.
      RAISE EXCEPTION TYPE zcx_abappdf EXPORTING textid = zcx_abappdf=>pdf_expected.
    ENDIF.
  ENDMETHOD.


  METHOD compose.
    DATA lv_style TYPE string.
    DATA lv_upper TYPE string.
    DATA lv_pos TYPE i.
    lv_style = '<style>' && iv_page_css && cl_abap_char_utilities=>newline && iv_css && '</style>'.
    lv_upper = to_upper( iv_html ).
    IF lv_upper NS '<HTML'.
      rv_html = '<!DOCTYPE html><html><head><meta charset="utf-8">' && lv_style &&
        '</head><body>' && iv_html && '</body></html>'.
      RETURN.
    ENDIF.
    lv_pos = find( val = lv_upper sub = '</HEAD>' ).
    IF lv_pos >= 0.
      rv_html = substring( val = iv_html len = lv_pos ) && lv_style && substring( val = iv_html off = lv_pos ).
      RETURN.
    ENDIF.
    rv_html = lv_style && iv_html.
  ENDMETHOD.


  METHOD page_css.
    DATA lv_size TYPE string.
    DATA lv_orient TYPE string.
    CASE to_upper( is_page-page_size ).
      WHEN zcl_abappdf_config=>page_a3.
        ev_width = zcl_abappdf_config=>gotenberg_a3_short.
        ev_height = zcl_abappdf_config=>gotenberg_a3_long.
        lv_size = zcl_abappdf_config=>page_a3.
      WHEN zcl_abappdf_config=>page_a5.
        ev_width = zcl_abappdf_config=>gotenberg_a5_short.
        ev_height = zcl_abappdf_config=>gotenberg_a5_long.
        lv_size = zcl_abappdf_config=>page_a5.
      WHEN zcl_abappdf_config=>page_letter.
        ev_width = zcl_abappdf_config=>gotenberg_letter_short.
        ev_height = zcl_abappdf_config=>gotenberg_letter_long.
        lv_size = zcl_abappdf_config=>css_letter.
      WHEN zcl_abappdf_config=>page_legal.
        ev_width = zcl_abappdf_config=>gotenberg_legal_short.
        ev_height = zcl_abappdf_config=>gotenberg_legal_long.
        lv_size = zcl_abappdf_config=>css_legal.
      WHEN OTHERS.
        ev_width = zcl_abappdf_config=>gotenberg_a4_short.
        ev_height = zcl_abappdf_config=>gotenberg_a4_long.
        lv_size = zcl_abappdf_config=>page_a4.
    ENDCASE.
    IF is_page-orientation = zcl_abappdf_config=>orient_landscape.
      DATA(lv_swap) = ev_width.
      ev_width = ev_height.
      ev_height = lv_swap.
      lv_orient = zcl_abappdf_config=>css_landscape.
    ELSE.
      lv_orient = zcl_abappdf_config=>css_portrait.
    ENDIF.
    ev_css = |@page \{ size: { lv_size } { lv_orient }; margin: { is_page-margin_top }{ zcl_abappdf_config=>unit_mm } | &&
      |{ is_page-margin_right }{ zcl_abappdf_config=>unit_mm } { is_page-margin_bottom }{ zcl_abappdf_config=>unit_mm } { is_page-margin_left }{ zcl_abappdf_config=>unit_mm }; \}|.
  ENDMETHOD.


  METHOD append_file.
    DATA lv_nl TYPE string.
    lv_nl = cl_abap_char_utilities=>cr_lf.
    cv_body = cv_body && '--' && iv_boundary && lv_nl &&
      |Content-Disposition: form-data; name="files"; filename="{ iv_filename }"{ lv_nl }| &&
      |Content-Type: text/html; charset=utf-8{ lv_nl }{ lv_nl }| &&
      iv_content && lv_nl.
  ENDMETHOD.


  METHOD append_field.
    DATA lv_nl TYPE string.
    lv_nl = cl_abap_char_utilities=>cr_lf.
    cv_body = cv_body && '--' && iv_boundary && lv_nl &&
      |Content-Disposition: form-data; name="{ iv_name }"{ lv_nl }{ lv_nl }| &&
      iv_value && lv_nl.
  ENDMETHOD.

ENDCLASS.
