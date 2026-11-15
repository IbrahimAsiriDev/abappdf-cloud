CLASS zcl_abappdf_http DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_http_service_extension.

  PRIVATE SECTION.
    TYPES ty_parts TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    METHODS dispatch
      IMPORTING
        request  TYPE REF TO if_web_http_request
        response TYPE REF TO if_web_http_response
      RAISING
        zcx_abappdf.

    METHODS allow_origin
      IMPORTING
        request          TYPE REF TO if_web_http_request
        response         TYPE REF TO if_web_http_response
      RETURNING
        VALUE(rv_blocked) TYPE abap_bool.

    METHODS origin_ok
      IMPORTING
        iv_origin      TYPE string
        request        TYPE REF TO if_web_http_request
      RETURNING
        VALUE(rv_yes) TYPE abap_bool.

    METHODS path_parts
      IMPORTING
        request        TYPE REF TO if_web_http_request
      RETURNING
        VALUE(rt_parts) TYPE ty_parts.

    METHODS json_error
      IMPORTING
        response TYPE REF TO if_web_http_response
        iv_code  TYPE i
        iv_text  TYPE string.

    METHODS json_ok
      IMPORTING
        response TYPE REF TO if_web_http_response
        iv_json  TYPE string
        iv_code  TYPE i DEFAULT 200.

    METHODS form_json
      IMPORTING
        is_form        TYPE zcl_abappdf_forms=>ty_form
      RETURNING
        VALUE(rv_json) TYPE string.

    METHODS template_json
      IMPORTING
        is_form            TYPE zcl_abappdf_forms=>ty_form
        is_template        TYPE zcl_abappdf_forms=>ty_template OPTIONAL
        iv_has_template    TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(rv_json)     TYPE string.

    METHODS read_body
      IMPORTING
        request        TYPE REF TO if_web_http_request
      RETURNING
        VALUE(rv_body) TYPE string.

    METHODS body_node
      IMPORTING
        request        TYPE REF TO if_web_http_request
      RETURNING
        VALUE(rr_node) TYPE REF TO data
      RAISING
        zcx_abappdf.

    METHODS json_int
      IMPORTING
        iv_text    TYPE string
      RETURNING
        VALUE(rv_int) TYPE i
      RAISING
        zcx_abappdf.

    METHODS part
      IMPORTING
        it_parts       TYPE ty_parts
        iv_index       TYPE i
      RETURNING
        VALUE(rv_part) TYPE string.

    METHODS query_param
      IMPORTING
        request         TYPE REF TO if_web_http_request
        iv_name         TYPE string
      RETURNING
        VALUE(rv_value) TYPE string.
    METHODS designer_html
      IMPORTING
        request        TYPE REF TO if_web_http_request
      RETURNING
        VALUE(rv_html) TYPE string.

    METHODS html_escape
      IMPORTING
        iv_text        TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.

    METHODS render_request
      IMPORTING
        request        TYPE REF TO if_web_http_request
        iv_form_id     TYPE string
      RETURNING
        VALUE(rv_pdf)  TYPE xstring
      RAISING
        zcx_abappdf.

    METHODS print_pdf
      IMPORTING
        iv_doc        TYPE string
      RETURNING
        VALUE(rv_pdf) TYPE xstring
      RAISING
        zcx_abappdf.

    METHODS csrf_token
      RETURNING
        VALUE(rv_token) TYPE string.
ENDCLASS.



CLASS zcl_abappdf_http IMPLEMENTATION.

  METHOD if_http_service_extension~handle_request.
    IF allow_origin( request = request response = response ) = abap_true.
      json_error( response = response iv_code = 403 iv_text = 'Origin is not allowed' ).
      RETURN.
    ENDIF.
    IF to_upper( request->get_method( ) ) = 'OPTIONS'.
      response->set_status( i_code = 204 i_reason = 'No Content' ).
      RETURN.
    ENDIF.
    "Changing requests must send the token from an earlier GET in header x-csrf-token.
    "A browser sends this custom header cross-site only after a CORS preflight, and
    "allow_origin answers the preflight only for allowed origins.
    IF to_upper( request->get_method( ) ) <> 'GET' AND to_upper( request->get_method( ) ) <> 'HEAD'
        AND request->get_header_field( i_name = 'x-csrf-token' ) <> csrf_token( ).
      json_error( response = response iv_code = 403 iv_text = 'CSRF token is missing or invalid' ).
      RETURN.
    ENDIF.
    TRY.
        dispatch( request = request response = response ).
      CATCH zcx_abappdf INTO DATA(lx_pdf).
        DATA(lv_text) = lx_pdf->get_text( ).
        IF lx_pdf->longtext IS NOT INITIAL.
          lv_text = lx_pdf->longtext.
        ENDIF.
        DATA(lv_code) = 400.
        IF lv_text CS 'does not exist' OR lv_text CS 'has no template'.
          lv_code = 404.
        ELSEIF lv_text CS 'already exists'.
          lv_code = 409.
        ELSEIF lv_text CS 'Gotenberg' OR lv_text CS 'destination'.
          lv_code = 500.
        ENDIF.
        json_error( response = response iv_code = lv_code iv_text = lv_text ).
    ENDTRY.
  ENDMETHOD.


  METHOD dispatch.
    DATA lt_parts TYPE ty_parts.
    DATA lv_method TYPE string.
    DATA ls_form TYPE zcl_abappdf_forms=>ty_form.
    DATA ls_template TYPE zcl_abappdf_forms=>ty_template.
    DATA lr_node TYPE REF TO data.
    DATA lr_page TYPE REF TO data.

    lv_method = to_upper( request->get_method( ) ).
    lt_parts = path_parts( request ).
    IF to_lower( part( it_parts = lt_parts iv_index = 1 ) ) = 'print'
        AND ( lv_method = 'GET' OR lv_method = 'HEAD' ).
      DATA(lv_doc) = to_upper( part( it_parts = lt_parts iv_index = 2 ) ).
      IF strlen( lv_doc ) > 10.
        lv_doc = substring( val = lv_doc len = 10 ).
      ENDIF.
      response->set_status( 200 ).
      response->set_header_field(
        i_name  = 'content-type'
        i_value = zcl_abappdf_config=>mime_pdf ).
      response->set_header_field(
        i_name  = 'content-disposition'
        i_value = |inline; filename="{ lv_doc }.pdf"| ).
      IF lv_method = 'GET'.
        response->set_binary( print_pdf( lv_doc ) ).
      ENDIF.
      RETURN.
    ENDIF.
    IF to_lower( part( it_parts = lt_parts iv_index = 1 ) ) = 'data'
        AND lv_method = 'GET'.
      json_ok(
        response = response
        iv_json  = zcl_abappdf_data=>read(
          iv_source = to_upper( part( it_parts = lt_parts iv_index = 2 ) )
          iv_key    = to_upper( part( it_parts = lt_parts iv_index = 3 ) ) ) ).
      RETURN.
    ENDIF.
    IF to_lower( part( it_parts = lt_parts iv_index = 1 ) ) = 'transports'
        AND lines( lt_parts ) = 1
        AND lv_method = 'GET'.
      json_ok( response = response iv_json = zcl_abappdf_tr=>requests_json( ) ).
      RETURN.
    ENDIF.
    IF to_lower( part( it_parts = lt_parts iv_index = 1 ) ) <> 'forms'.
      "Same role as lcl_pdf_app=>show: the service root is the designer page.
      "/forms stays the JSON API that replaces sapevent.
      IF lv_method = 'GET' OR lv_method = 'HEAD'.
        response->set_status( 200 ).
        response->set_header_field(
          i_name  = 'content-type'
          i_value = 'text/html; charset=utf-8' ).
        response->set_header_field(
          i_name  = 'cache-control'
          i_value = 'no-store' ).
        IF lv_method = 'GET'.
          response->set_text( designer_html( request ) ).
        ENDIF.
        RETURN.
      ENDIF.
      json_error( response = response iv_code = 404 iv_text = 'Unknown path' ).
      RETURN.
    ENDIF.

    IF lines( lt_parts ) = 1.
      CASE lv_method.
        WHEN 'GET'.
          DATA(lv_json) = '['.
          DATA(lv_sep) = ''.
          LOOP AT zcl_abappdf_forms=>list_forms( ) INTO ls_form.
            lv_json = lv_json && lv_sep && form_json( ls_form ).
            lv_sep = ','.
          ENDLOOP.
          json_ok( response = response iv_json = lv_json && ']' ).
        WHEN 'POST'.
          lr_node = body_node( request ).
          zcl_abappdf_forms=>create_form(
            iv_form_id     = zcl_abappdf_json=>text_of( zcl_abappdf_json=>member( ir_node = lr_node iv_name = 'id' ) )
            iv_description = zcl_abappdf_json=>text_of( zcl_abappdf_json=>member( ir_node = lr_node iv_name = 'description' ) )
            iv_package     = zcl_abappdf_json=>text_of( zcl_abappdf_json=>member( ir_node = lr_node iv_name = 'package' ) ) ).
          ls_form = zcl_abappdf_forms=>read_form(
            zcl_abappdf_json=>text_of( zcl_abappdf_json=>member( ir_node = lr_node iv_name = 'id' ) ) ).
          json_ok( response = response iv_json = form_json( ls_form ) iv_code = 201 ).
        WHEN OTHERS.
          json_error( response = response iv_code = 405 iv_text = 'Method is not allowed' ).
      ENDCASE.
      RETURN.
    ENDIF.

    DATA(lv_id) = part( it_parts = lt_parts iv_index = 2 ).
    IF lines( lt_parts ) = 2.
      CASE lv_method.
        WHEN 'GET'.
          ls_form = zcl_abappdf_forms=>read_form( lv_id ).
          TRY.
              ls_template = zcl_abappdf_forms=>read_active( lv_id ).
              json_ok( response = response iv_json = template_json(
                is_form = ls_form is_template = ls_template iv_has_template = abap_true ) ).
            CATCH zcx_abappdf INTO DATA(lx_empty).
              IF lx_empty->get_text( ) CS 'has no template'.
                json_ok( response = response iv_json = template_json( ls_form ) ).
              ELSE.
                RAISE EXCEPTION lx_empty.
              ENDIF.
          ENDTRY.
        WHEN 'PATCH'.
          ls_form = zcl_abappdf_forms=>read_form( lv_id ).
          lr_node = body_node( request ).
          DATA(lv_desc) = ls_form-description.
          DATA(lv_pkg) = ls_form-package_name.
          DATA(lv_new) = ls_form-form_id.
          IF zcl_abappdf_json=>member( ir_node = lr_node iv_name = 'description' ) IS BOUND.
            lv_desc = zcl_abappdf_json=>text_of( zcl_abappdf_json=>member( ir_node = lr_node iv_name = 'description' ) ).
          ENDIF.
          IF zcl_abappdf_json=>member( ir_node = lr_node iv_name = 'package' ) IS BOUND.
            lv_pkg = zcl_abappdf_json=>text_of( zcl_abappdf_json=>member( ir_node = lr_node iv_name = 'package' ) ).
          ENDIF.
          IF zcl_abappdf_json=>member( ir_node = lr_node iv_name = 'id' ) IS BOUND.
            lv_new = zcl_abappdf_json=>text_of( zcl_abappdf_json=>member( ir_node = lr_node iv_name = 'id' ) ).
          ENDIF.
          zcl_abappdf_forms=>update_form(
            iv_form_id     = lv_id
            iv_new_id      = lv_new
            iv_description = lv_desc
            iv_package     = lv_pkg ).
          json_ok( response = response iv_json = form_json( zcl_abappdf_forms=>read_form( lv_new ) ) ).
        WHEN 'DELETE'.
          zcl_abappdf_forms=>delete_form( lv_id ).
          response->set_status( i_code = 204 i_reason = 'No Content' ).
        WHEN OTHERS.
          json_error( response = response iv_code = 405 iv_text = 'Method is not allowed' ).
      ENDCASE.
      RETURN.
    ENDIF.

    DATA(lv_tail) = to_lower( part( it_parts = lt_parts iv_index = 3 ) ).
    IF lv_tail = 'transport' AND lines( lt_parts ) = 3 AND lv_method = 'POST'.
      lr_node = body_node( request ).
      DATA(lv_tr_create) = abap_false.
      IF zcl_abappdf_json=>kind( zcl_abappdf_json=>member( ir_node = lr_node iv_name = 'create' ) ) = 'B'
          AND zcl_abappdf_json=>text_of( zcl_abappdf_json=>member( ir_node = lr_node iv_name = 'create' ) ) = 'true'.
        lv_tr_create = abap_true.
      ENDIF.
      zcl_abappdf_tr=>record_form(
        iv_form_id = lv_id
        iv_request = zcl_abappdf_json=>text_of( zcl_abappdf_json=>member( ir_node = lr_node iv_name = 'request' ) )
        iv_create  = lv_tr_create ).
      json_ok( response = response iv_json = form_json( zcl_abappdf_forms=>read_form( lv_id ) ) ).
      RETURN.
    ENDIF.

    IF lv_tail = 'versions' AND lines( lt_parts ) = 3 AND lv_method = 'GET'.
      lv_json = '['.
      lv_sep = ''.
      LOOP AT zcl_abappdf_forms=>list_versions( lv_id ) INTO DATA(ls_version).
        lv_json = lv_json && lv_sep && |\{"version":{ ls_version-version },"changedBy":"{ zcl_abappdf_json=>escape( ls_version-changed_by ) }","changedAt":"{ zcl_abappdf_json=>escape( ls_version-changed_at ) }"\}|.
        lv_sep = ','.
      ENDLOOP.
      json_ok( response = response iv_json = lv_json && ']' ).
      RETURN.
    ENDIF.

    IF lv_tail = 'versions' AND lines( lt_parts ) = 4 AND lv_method = 'GET'.
      DATA(lv_ver_text) = part( it_parts = lt_parts iv_index = 4 ).
      IF lv_ver_text CN '0123456789' OR lv_ver_text IS INITIAL.
        RAISE EXCEPTION TYPE zcx_abappdf EXPORTING textid = zcx_abappdf=>version_missing msgv1 = CONV symsgv( lv_ver_text ).
      ENDIF.
      ls_template = zcl_abappdf_forms=>read_version(
        iv_form_id = lv_id
        iv_version = CONV i( lv_ver_text ) ).
      ls_form = zcl_abappdf_forms=>read_form( lv_id ).
      json_ok( response = response iv_json = template_json(
        is_form = ls_form is_template = ls_template iv_has_template = abap_true ) ).
      RETURN.
    ENDIF.

    IF lv_tail = 'versions' AND lines( lt_parts ) = 3 AND lv_method = 'POST'.
      lr_node = body_node( request ).
      lr_page = zcl_abappdf_json=>member( ir_node = lr_node iv_name = 'page' ).
      CLEAR ls_template.
      ls_template-form_id = lv_id.
      ls_template-html = zcl_abappdf_json=>text_of( zcl_abappdf_json=>member( ir_node = lr_node iv_name = 'html' ) ).
      ls_template-css = zcl_abappdf_json=>text_of( zcl_abappdf_json=>member( ir_node = lr_node iv_name = 'css' ) ).
      ls_template-header = zcl_abappdf_json=>text_of( zcl_abappdf_json=>member( ir_node = lr_node iv_name = 'header' ) ).
      ls_template-footer = zcl_abappdf_json=>text_of( zcl_abappdf_json=>member( ir_node = lr_node iv_name = 'footer' ) ).
      ls_template-sample = zcl_abappdf_json=>text_of( zcl_abappdf_json=>member( ir_node = lr_node iv_name = 'sample' ) ).
      ls_template-page_size = zcl_abappdf_json=>text_of( zcl_abappdf_json=>member( ir_node = lr_page iv_name = 'size' ) ).
      ls_template-orientation = zcl_abappdf_json=>text_of( zcl_abappdf_json=>member( ir_node = lr_page iv_name = 'orientation' ) ).
      ls_template-margin_top = json_int( zcl_abappdf_json=>text_of( zcl_abappdf_json=>member( ir_node = lr_page iv_name = 'marginTop' ) ) ).
      ls_template-margin_right = json_int( zcl_abappdf_json=>text_of( zcl_abappdf_json=>member( ir_node = lr_page iv_name = 'marginRight' ) ) ).
      ls_template-margin_bottom = json_int( zcl_abappdf_json=>text_of( zcl_abappdf_json=>member( ir_node = lr_page iv_name = 'marginBottom' ) ) ).
      ls_template-margin_left = json_int( zcl_abappdf_json=>text_of( zcl_abappdf_json=>member( ir_node = lr_page iv_name = 'marginLeft' ) ) ).
      DATA(lv_version) = zcl_abappdf_forms=>save_version( ls_template ).
      json_ok( response = response iv_json = |\{"version":{ lv_version }\}| iv_code = 201 ).
      RETURN.
    ENDIF.

    IF lv_tail = 'render' AND lines( lt_parts ) = 3 AND lv_method = 'POST'.
      DATA(lv_pdf) = render_request( request = request iv_form_id = lv_id ).
      response->set_status( i_code = 200 i_reason = 'OK' ).
      response->set_header_field( i_name = 'content-type' i_value = zcl_abappdf_config=>mime_pdf ).
      response->set_header_field(
        i_name  = 'content-disposition'
        i_value = |inline; filename="{ lv_id }.pdf"| ).
      response->set_binary( i_data = lv_pdf ).
      RETURN.
    ENDIF.

    json_error( response = response iv_code = 404 iv_text = 'Unknown path' ).
  ENDMETHOD.


  METHOD allow_origin.
    DATA(lv_origin) = request->get_header_field( i_name = 'origin' ).
    DATA(lv_fetch) = to_lower( request->get_header_field( i_name = 'x-csrf-token' ) ).
    IF lv_origin IS NOT INITIAL AND origin_ok( iv_origin = lv_origin request = request ) = abap_false.
      rv_blocked = abap_true.
      RETURN.
    ENDIF.
    IF lv_origin IS NOT INITIAL.
      response->set_header_field( i_name = 'access-control-allow-origin' i_value = lv_origin ).
      response->set_header_field( i_name = 'access-control-allow-credentials' i_value = 'true' ).
      response->set_header_field( i_name = 'access-control-allow-methods' i_value = 'GET, POST, PATCH, DELETE, OPTIONS' ).
      response->set_header_field( i_name = 'access-control-allow-headers' i_value = 'content-type, x-csrf-token, accept' ).
      response->set_header_field( i_name = 'access-control-expose-headers' i_value = 'x-csrf-token, content-disposition' ).
      response->set_header_field( i_name = 'vary' i_value = 'Origin' ).
    ENDIF.
    IF lv_fetch = 'fetch' OR to_upper( request->get_method( ) ) = 'GET'.
      response->set_header_field(
        i_name  = 'x-csrf-token'
        i_value = csrf_token( ) ).
    ENDIF.
  ENDMETHOD.


  METHOD csrf_token.
    rv_token = cl_abap_context_info=>get_user_technical_name( ) && '-abappdf'.
  ENDMETHOD.


  METHOD origin_ok.
    DATA lv_origin TYPE string.
    DATA lv_host TYPE string.
    DATA lv_host_port TYPE string.
    DATA lv_extra TYPE string.
    DATA lv_at TYPE i.
    lv_origin = to_lower( iv_origin ).
    "A page served by this handler fetches /forms from the same host.
    lv_host = to_lower( request->get_header_field( i_name = 'x-forwarded-host' ) ).
    IF lv_host IS INITIAL.
      lv_host = to_lower( request->get_header_field( i_name = 'host' ) ).
    ENDIF.
    lv_at = find( val = lv_host sub = ',' ).
    IF lv_at >= 0.
      lv_host = substring( val = lv_host len = lv_at ).
    ENDIF.
    lv_host = condense( lv_host ).
    "The browser sends the port in Origin when it is not the default one
    "(https://host:50001 on premise), so compare with and without the port.
    lv_host_port = lv_host.
    IF lv_host IS NOT INITIAL AND lv_host(1) <> '['.
      lv_at = find( val = lv_host sub = ':' ).
      IF lv_at >= 0.
        lv_host = substring( val = lv_host len = lv_at ).
      ENDIF.
    ENDIF.
    IF lv_host IS NOT INITIAL
        AND ( lv_origin = |https://{ lv_host }| OR lv_origin = |http://{ lv_host }|
           OR lv_origin = |https://{ lv_host_port }| OR lv_origin = |http://{ lv_host_port }| ).
      rv_yes = abap_true.
      RETURN.
    ENDIF.
    IF lv_origin = 'http://127.0.0.1' OR lv_origin = 'http://localhost'
        OR lv_origin = 'https://127.0.0.1' OR lv_origin = 'https://localhost'
        OR lv_origin CP 'http://127.0.0.1:*' OR lv_origin CP 'http://localhost:*'
        OR lv_origin CP 'https://127.0.0.1:*' OR lv_origin CP 'https://localhost:*'
        OR lv_origin CP 'http://[::1]:*' OR lv_origin CP 'https://[::1]:*'.
      rv_yes = abap_true.
      RETURN.
    ENDIF.
    lv_extra = to_lower( zcl_abappdf_forms=>get_config( zcl_abappdf_config=>param_cors_origin ) ).
    IF lv_extra IS NOT INITIAL AND lv_origin = lv_extra.
      rv_yes = abap_true.
    ENDIF.
  ENDMETHOD.


  METHOD path_parts.
    DATA lv_path TYPE string.
    DATA lv_at TYPE i.
    DATA lv_forms TYPE i.
    "ABAP Cloud may put the service-relative path in ~path_info and the
    "full ICF path in ~path or ~request_uri. An empty root still means the designer.
    lv_path = request->get_header_field( i_name = '~path_info' ).
    IF lv_path IS INITIAL OR lv_path = '/'.
      lv_path = request->get_header_field( i_name = '~path' ).
    ENDIF.
    IF lv_path IS INITIAL OR lv_path = '/'.
      lv_path = request->get_header_field( i_name = '~request_uri' ).
    ENDIF.
    lv_at = find( val = lv_path sub = '?' ).
    IF lv_at >= 0.
      lv_path = substring( val = lv_path len = lv_at ).
    ENDIF.
    lv_forms = find( val = to_lower( lv_path ) sub = '/forms' ).
    IF lv_forms < 0.
      lv_forms = find( val = to_lower( lv_path ) sub = '/print' ).
    ENDIF.
    IF lv_forms < 0.
      lv_forms = find( val = to_lower( lv_path ) sub = '/data' ).
    ENDIF.
    IF lv_forms >= 0.
      lv_path = substring( val = lv_path off = lv_forms ).
    ENDIF.
    SPLIT lv_path AT '/' INTO TABLE rt_parts.
    DELETE rt_parts WHERE table_line IS INITIAL.
    LOOP AT rt_parts ASSIGNING FIELD-SYMBOL(<part>).
      <part> = cl_web_http_utility=>unescape_url( <part> ).
    ENDLOOP.
  ENDMETHOD.


  METHOD json_error.
    DATA lv_reason TYPE string.
    CASE iv_code.
      WHEN 404. lv_reason = 'Not Found'.
      WHEN 405. lv_reason = 'Method Not Allowed'.
      WHEN 409. lv_reason = 'Conflict'.
      WHEN 403. lv_reason = 'Forbidden'.
      WHEN OTHERS. lv_reason = 'Bad Request'.
    ENDCASE.
    response->set_status( i_code = iv_code i_reason = lv_reason ).
    response->set_header_field( i_name = 'content-type' i_value = 'application/json; charset=utf-8' ).
    response->set_text( |\{"message":"{ zcl_abappdf_json=>escape( iv_text ) }"\}| ).
  ENDMETHOD.


  METHOD json_ok.
    DATA lv_reason TYPE string.
    IF iv_code = 201.
      lv_reason = 'Created'.
    ELSE.
      lv_reason = 'OK'.
    ENDIF.
    response->set_status( i_code = iv_code i_reason = lv_reason ).
    response->set_header_field( i_name = 'content-type' i_value = 'application/json; charset=utf-8' ).
    response->set_text( iv_json ).
  ENDMETHOD.


  METHOD form_json.
    rv_json = |\{"id":"{ zcl_abappdf_json=>escape( is_form-form_id ) }"| &&
      |,"description":"{ zcl_abappdf_json=>escape( is_form-description ) }"| &&
      |,"package":"{ zcl_abappdf_json=>escape( is_form-package_name ) }"| &&
      |,"version":{ is_form-version }| &&
      |,"changedAt":"{ zcl_abappdf_json=>escape( is_form-changed_at ) }"| &&
      |,"saved":true,"transport":"{ zcl_abappdf_json=>escape( is_form-transport ) }"\}|.
  ENDMETHOD.


  METHOD template_json.
    DATA lv_size TYPE string.
    DATA lv_orient TYPE string.
    DATA lv_top TYPE i.
    DATA lv_right TYPE i.
    DATA lv_bottom TYPE i.
    DATA lv_left TYPE i.
    DATA lv_html TYPE string.
    DATA lv_css TYPE string.
    DATA lv_header TYPE string.
    DATA lv_footer TYPE string.
    DATA lv_sample TYPE string.
    DATA lv_version TYPE i.
    IF iv_has_template = abap_true.
      lv_size = is_template-page_size.
      lv_orient = is_template-orientation.
      lv_top = is_template-margin_top.
      lv_right = is_template-margin_right.
      lv_bottom = is_template-margin_bottom.
      lv_left = is_template-margin_left.
      lv_html = is_template-html.
      lv_css = is_template-css.
      lv_header = is_template-header.
      lv_footer = is_template-footer.
      lv_sample = is_template-sample.
      lv_version = is_template-version.
    ELSE.
      lv_size = zcl_abappdf_config=>page_a4.
      lv_orient = zcl_abappdf_config=>orient_portrait.
      lv_top = zcl_abappdf_config=>default_margin_top.
      lv_right = zcl_abappdf_config=>default_margin_right.
      lv_bottom = zcl_abappdf_config=>default_margin_bottom.
      lv_left = zcl_abappdf_config=>default_margin_left.
      lv_sample = '{}'.
    ENDIF.
    rv_json = |\{"id":"{ zcl_abappdf_json=>escape( is_form-form_id ) }"| &&
      |,"description":"{ zcl_abappdf_json=>escape( is_form-description ) }"| &&
      |,"package":"{ zcl_abappdf_json=>escape( is_form-package_name ) }"| &&
      |,"version":{ lv_version }| &&
      |,"changedAt":"{ zcl_abappdf_json=>escape( is_form-changed_at ) }"| &&
      |,"html":"{ zcl_abappdf_json=>escape( lv_html ) }"| &&
      |,"css":"{ zcl_abappdf_json=>escape( lv_css ) }"| &&
      |,"header":"{ zcl_abappdf_json=>escape( lv_header ) }"| &&
      |,"footer":"{ zcl_abappdf_json=>escape( lv_footer ) }"| &&
      |,"transport":"{ zcl_abappdf_json=>escape( is_form-transport ) }"| &&
      |,"sample":"{ zcl_abappdf_json=>escape( lv_sample ) }"| &&
      |,"page":\{"size":"{ zcl_abappdf_json=>escape( lv_size ) }","orientation":"{ zcl_abappdf_json=>escape( lv_orient ) }"| &&
      |,"marginTop":{ lv_top },"marginRight":{ lv_right },"marginBottom":{ lv_bottom },"marginLeft":{ lv_left }\}| &&
      |\}|.
  ENDMETHOD.


  METHOD read_body.
    rv_body = request->get_text( ).
  ENDMETHOD.


  METHOD body_node.
    DATA(lv_body) = read_body( request ).
    IF lv_body IS INITIAL.
      RAISE EXCEPTION TYPE zcx_abappdf EXPORTING textid = zcx_abappdf=>json_body_required.
    ENDIF.
    rr_node = zcl_abappdf_json=>parse( lv_body ).
    IF zcl_abappdf_json=>kind( rr_node ) <> 'O'.
      RAISE EXCEPTION TYPE zcx_abappdf EXPORTING textid = zcx_abappdf=>json_body_object.
    ENDIF.
  ENDMETHOD.


  METHOD json_int.
    DATA lv_text TYPE string.
    lv_text = iv_text.
    CONDENSE lv_text NO-GAPS.
    IF lv_text IS INITIAL.
      RETURN.
    ENDIF.
    IF lv_text CN '0123456789' OR strlen( lv_text ) > 4.
      RAISE EXCEPTION TYPE zcx_abappdf EXPORTING textid = zcx_abappdf=>margin_whole msgv1 = CONV symsgv( zcl_abappdf_config=>margin_max_mm ).
    ENDIF.
    rv_int = lv_text.
  ENDMETHOD.


  METHOD part.
    READ TABLE it_parts INDEX iv_index INTO rv_part.
  ENDMETHOD.


  METHOD query_param.
    DATA lv_uri TYPE string.
    DATA lv_query TYPE string.
    DATA lv_q TYPE i.
    DATA lt_pairs TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    DATA lv_pair TYPE string.
    DATA lv_name TYPE string.
    DATA lv_value TYPE string.

    lv_uri = request->get_header_field( '~request_uri' ).
    lv_q = find( val = lv_uri sub = '?' ).
    IF lv_q < 0.
      RETURN.
    ENDIF.
    lv_query = substring( val = lv_uri off = lv_q + 1 ).
    SPLIT lv_query AT '&' INTO TABLE lt_pairs.
    LOOP AT lt_pairs INTO lv_pair.
      SPLIT lv_pair AT '=' INTO lv_name lv_value.
      IF to_lower( lv_name ) = to_lower( iv_name ).
        rv_value = lv_value.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD designer_html.
    DATA lt_forms TYPE zcl_abappdf_forms=>ty_forms.
    DATA ls_form TYPE zcl_abappdf_forms=>ty_form.
    DATA ls_tpl TYPE zcl_abappdf_forms=>ty_template.
    DATA lv_forms TYPE string.
    DATA lv_sep TYPE string.
    DATA lv_rows TYPE string.
    DATA lv_id TYPE string.
    DATA lv_pkg TYPE string.
    DATA lv_ctx TYPE string.
    DATA lv_open TYPE string.
    DATA lv_view TYPE string VALUE 'false'.
    DATA lv_page TYPE string.
    DATA lv_html TYPE string.
    DATA lv_css TYPE string.
    DATA lv_header TYPE string.
    DATA lv_footer TYPE string.
    DATA lv_sample TYPE string VALUE '{}'.
    DATA lv_form_id TYPE string.
    DATA lv_desc TYPE string.
    DATA lv_form_pkg TYPE string VALUE zcl_abappdf_config=>local_package.
    DATA lv_version TYPE string.
    DATA lv_orient TYPE string.

    "A fresh install opens with the demo form ZPDF_TRAVEL in the list.
    zcl_abappdf_demo=>seed_once( ).
    rv_html = zcl_abappdf_ui=>html( ).
    REPLACE ALL OCCURRENCES OF 'data-abappdf-runtime="browser"' IN rv_html WITH 'data-abappdf-runtime="cloud"'.
    REPLACE ALL OCCURRENCES OF 'data-abappdf-runtime="sap"' IN rv_html WITH 'data-abappdf-runtime="cloud"'.

    lt_forms = zcl_abappdf_forms=>list_forms( ).
    lv_forms = '['.
    LOOP AT lt_forms INTO ls_form.
      lv_forms = lv_forms && lv_sep && form_json( ls_form ).
      lv_sep = ','.
      lv_id = html_escape( ls_form-form_id ).
      lv_pkg = html_escape( ls_form-package_name ).
      IF lv_pkg IS INITIAL.
        lv_pkg = zcl_abappdf_config=>local_package.
      ENDIF.
      lv_rows = lv_rows && '<tr><td></td><td><span class="link" data-act="edit" data-id="'.
      lv_rows = lv_rows && lv_id && '">' && lv_id && '</span></td><td><span class="pkg">'.
      lv_rows = lv_rows && lv_pkg && '</span></td><td></td><td>' && |{ ls_form-version }|.
      lv_rows = lv_rows && '</td><td>' && html_escape( ls_form-changed_at ) && '</td><td>'.
      lv_rows = lv_rows && '<span class="link" data-act="edit" data-id="' && lv_id && '">Edit</span>'.
      lv_rows = lv_rows && '</td></tr>'.
    ENDLOOP.
    lv_forms = lv_forms && ']'.

    lv_page = |\{"size":"{ zcl_abappdf_config=>page_a4 }","orientation":"{ zcl_abappdf_config=>orient_portrait }"| &&
      |,"marginTop":{ zcl_abappdf_config=>default_margin_top },"marginRight":{ zcl_abappdf_config=>default_margin_right }| &&
      |,"marginBottom":{ zcl_abappdf_config=>default_margin_bottom },"marginLeft":{ zcl_abappdf_config=>default_margin_left }\}|.
    lv_open = to_upper( query_param( request = request iv_name = 'open' ) ).
    IF query_param( request = request iv_name = 'view' ) = '1'.
      lv_view = 'true'.
    ENDIF.
    IF lv_open IS NOT INITIAL.
      TRY.
          ls_form = zcl_abappdf_forms=>read_form( lv_open ).
          lv_form_id = ls_form-form_id.
          lv_desc = ls_form-description.
          lv_form_pkg = ls_form-package_name.
          IF lv_form_pkg IS INITIAL.
            lv_form_pkg = zcl_abappdf_config=>local_package.
          ENDIF.
          lv_version = |{ ls_form-version }|.
          TRY.
              ls_tpl = zcl_abappdf_forms=>read_active( lv_open ).
              lv_html = ls_tpl-html.
              lv_css = ls_tpl-css.
              lv_header = ls_tpl-header.
              lv_footer = ls_tpl-footer.
              lv_sample = ls_tpl-sample.
              IF lv_sample IS INITIAL.
                lv_sample = '{}'.
              ENDIF.
              lv_version = |{ ls_tpl-version }|.
              IF ls_tpl-page_size IS INITIAL.
                ls_tpl-page_size = zcl_abappdf_config=>page_a4.
              ENDIF.
              IF ls_tpl-orientation IS INITIAL.
                ls_tpl-orientation = zcl_abappdf_config=>orient_portrait.
              ENDIF.
              lv_orient = ls_tpl-orientation.
              lv_page = |\{"size":"{ zcl_abappdf_json=>escape( ls_tpl-page_size ) }"| &&
                |,"orientation":"{ zcl_abappdf_json=>escape( lv_orient ) }"| &&
                |,"marginTop":{ ls_tpl-margin_top },"marginRight":{ ls_tpl-margin_right }| &&
                |,"marginBottom":{ ls_tpl-margin_bottom },"marginLeft":{ ls_tpl-margin_left }\}|.
            CATCH zcx_abappdf.
          ENDTRY.
        CATCH zcx_abappdf.
          CLEAR lv_form_id.
          lv_view = 'false'.
      ENDTRY.
    ENDIF.

    lv_ctx = |\{"formId":"{ zcl_abappdf_json=>escape( lv_form_id ) }"| &&
      |,"description":"{ zcl_abappdf_json=>escape( lv_desc ) }"| &&
      |,"package":"{ zcl_abappdf_json=>escape( lv_form_pkg ) }"| &&
      |,"ddic":"","version":"{ zcl_abappdf_json=>escape( lv_version ) }"| &&
      |,"message":"","engine":"ok","viewOnly":{ lv_view }| &&
      |,"page":{ lv_page }| &&
      |,"html":"{ zcl_abappdf_json=>escape( lv_html ) }"| &&
      |,"css":"{ zcl_abappdf_json=>escape( lv_css ) }"| &&
      |,"header":"{ zcl_abappdf_json=>escape( lv_header ) }"| &&
      |,"footer":"{ zcl_abappdf_json=>escape( lv_footer ) }"| &&
      |,"sample":"{ zcl_abappdf_json=>escape( lv_sample ) }"| &&
      |,"store":"TABLE","forms":{ lv_forms },"fields":[],"previewPdf":""\}|.
    REPLACE ALL OCCURRENCES OF '<' IN lv_ctx WITH '\u003c'.
    REPLACE FIRST OCCURRENCE OF '<tbody id="formBody"></tbody>' IN rv_html
      WITH |<tbody id="formBody">{ lv_rows }</tbody>|.
    REPLACE FIRST OCCURRENCE OF 'var ABAPPDF_CONTEXT = null;' IN rv_html
      WITH |var ABAPPDF_CONTEXT = { lv_ctx };|.
  ENDMETHOD.


  METHOD html_escape.
    rv_text = iv_text.
    REPLACE ALL OCCURRENCES OF '&' IN rv_text WITH '&amp;'.
    REPLACE ALL OCCURRENCES OF '<' IN rv_text WITH '&lt;'.
    REPLACE ALL OCCURRENCES OF '>' IN rv_text WITH '&gt;'.
    REPLACE ALL OCCURRENCES OF '"' IN rv_text WITH '&quot;'.
  ENDMETHOD.


  METHOD render_request.
    DATA lr_node TYPE REF TO data.
    DATA lr_page TYPE REF TO data.
    DATA lr_data TYPE REF TO data.
    DATA ls_page TYPE zcl_abappdf_renderer=>ty_page.
    DATA lv_sample TYPE string.
    FIELD-SYMBOLS <data> TYPE any.

    DATA(lv_body) = read_body( request ).
    IF lv_body IS INITIAL.
      RAISE EXCEPTION TYPE zcx_abappdf EXPORTING textid = zcx_abappdf=>data_json_required.
    ENDIF.
    TRY.
        lr_node = zcl_abappdf_json=>parse( lv_body ).
      CATCH zcx_abappdf.
        RAISE EXCEPTION TYPE zcx_abappdf EXPORTING textid = zcx_abappdf=>data_json_invalid.
    ENDTRY.
    IF zcl_abappdf_json=>kind( lr_node ) <> 'O'.
      RAISE EXCEPTION TYPE zcx_abappdf EXPORTING textid = zcx_abappdf=>data_json_object.
    ENDIF.

    IF to_lower( zcl_abappdf_json=>text_of(
         zcl_abappdf_json=>member( ir_node = lr_node iv_name = 'mode' ) ) ) = 'draft'.
      lr_page = zcl_abappdf_json=>member( ir_node = lr_node iv_name = 'page' ).
      IF lr_page IS BOUND.
        ls_page-page_size = zcl_abappdf_json=>text_of(
          zcl_abappdf_json=>member( ir_node = lr_page iv_name = 'size' ) ).
        ls_page-orientation = zcl_abappdf_json=>text_of(
          zcl_abappdf_json=>member( ir_node = lr_page iv_name = 'orientation' ) ).
        ls_page-margin_top = json_int( zcl_abappdf_json=>text_of(
          zcl_abappdf_json=>member( ir_node = lr_page iv_name = 'marginTop' ) ) ).
        ls_page-margin_right = json_int( zcl_abappdf_json=>text_of(
          zcl_abappdf_json=>member( ir_node = lr_page iv_name = 'marginRight' ) ) ).
        ls_page-margin_bottom = json_int( zcl_abappdf_json=>text_of(
          zcl_abappdf_json=>member( ir_node = lr_page iv_name = 'marginBottom' ) ) ).
        ls_page-margin_left = json_int( zcl_abappdf_json=>text_of(
          zcl_abappdf_json=>member( ir_node = lr_page iv_name = 'marginLeft' ) ) ).
      ENDIF.
      IF ls_page-page_size IS INITIAL.
        ls_page-page_size = zcl_abappdf_config=>page_a4.
      ENDIF.
      IF ls_page-orientation IS INITIAL.
        ls_page-orientation = zcl_abappdf_config=>orient_portrait.
      ENDIF.
      lv_sample = zcl_abappdf_json=>text_of(
        zcl_abappdf_json=>member( ir_node = lr_node iv_name = 'sample' ) ).
      IF lv_sample IS INITIAL.
        lv_sample = '{}'.
      ENDIF.
      lv_sample = zcl_abappdf_data=>resolve( lv_sample ).
      TRY.
          lr_data = zcl_abappdf_json=>to_abap( lv_sample ).
        CATCH zcx_abappdf.
          RAISE EXCEPTION TYPE zcx_abappdf EXPORTING textid = zcx_abappdf=>data_json_invalid.
      ENDTRY.
      ASSIGN lr_data->* TO <data>.
      rv_pdf = zcl_abappdf_api=>render_parts(
        iv_html   = zcl_abappdf_json=>text_of( zcl_abappdf_json=>member( ir_node = lr_node iv_name = 'html' ) )
        iv_css    = zcl_abappdf_json=>text_of( zcl_abappdf_json=>member( ir_node = lr_node iv_name = 'css' ) )
        iv_header = zcl_abappdf_json=>text_of( zcl_abappdf_json=>member( ir_node = lr_node iv_name = 'header' ) )
        iv_footer = zcl_abappdf_json=>text_of( zcl_abappdf_json=>member( ir_node = lr_node iv_name = 'footer' ) )
        is_page   = ls_page
        is_data   = <data> ).
      RETURN.
    ENDIF.

    lr_data = zcl_abappdf_json=>to_abap( lv_body ).
    ASSIGN lr_data->* TO <data>.
    rv_pdf = zcl_abappdf_api=>render_pdf(
      iv_form_id = CONV string( iv_form_id )
      is_data    = <data> ).
  ENDMETHOD.


  METHOD print_pdf.
    DATA lv_id TYPE /dmo/travel-travel_id.

    lv_id = iv_doc.
    rv_pdf = zcl_abappdf_rap=>print( lv_id ).
  ENDMETHOD.

ENDCLASS.
