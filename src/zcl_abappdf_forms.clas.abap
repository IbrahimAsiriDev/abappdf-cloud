CLASS zcl_abappdf_forms DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_form,
        form_id      TYPE string,
        description  TYPE string,
        package_name TYPE string,
        transport    TYPE string,
        version      TYPE i,
        changed_at   TYPE string,
      END OF ty_form,
      ty_forms TYPE STANDARD TABLE OF ty_form WITH EMPTY KEY,
      BEGIN OF ty_version,
        version    TYPE i,
        changed_by TYPE string,
        changed_at TYPE string,
      END OF ty_version,
      ty_versions TYPE STANDARD TABLE OF ty_version WITH EMPTY KEY,
      BEGIN OF ty_template,
        form_id       TYPE string,
        version       TYPE i,
        html          TYPE string,
        css           TYPE string,
        header        TYPE string,
        footer        TYPE string,
        page_size     TYPE string,
        orientation   TYPE c LENGTH 1,
        margin_top    TYPE i,
        margin_right  TYPE i,
        margin_bottom TYPE i,
        margin_left   TYPE i,
        sample        TYPE string,
        changed_by    TYPE string,
        changed_at    TYPE string,
      END OF ty_template.

    CLASS-METHODS create_form
      IMPORTING
        iv_form_id     TYPE string
        iv_description TYPE string OPTIONAL
        iv_package     TYPE string OPTIONAL
      RAISING
        zcx_abappdf.

    CLASS-METHODS read_form
      IMPORTING
        iv_form_id     TYPE string
      RETURNING
        VALUE(rs_form) TYPE ty_form
      RAISING
        zcx_abappdf.

    CLASS-METHODS set_transport
      IMPORTING
        iv_form_id TYPE string
        iv_request TYPE string
      RAISING
        zcx_abappdf.

    CLASS-METHODS update_form
      IMPORTING
        iv_form_id     TYPE string
        iv_new_id      TYPE string OPTIONAL
        iv_description TYPE string OPTIONAL
        iv_package     TYPE string OPTIONAL
      RAISING
        zcx_abappdf.

    CLASS-METHODS delete_form
      IMPORTING
        iv_form_id TYPE string
      RAISING
        zcx_abappdf.

    CLASS-METHODS list_forms
      RETURNING
        VALUE(rt_forms) TYPE ty_forms.

    CLASS-METHODS save_version
      IMPORTING
        is_template       TYPE ty_template
      RETURNING
        VALUE(rv_version) TYPE i
      RAISING
        zcx_abappdf.

    CLASS-METHODS read_active
      IMPORTING
        iv_form_id         TYPE string
      RETURNING
        VALUE(rs_template) TYPE ty_template
      RAISING
        zcx_abappdf.

    CLASS-METHODS read_version
      IMPORTING
        iv_form_id         TYPE string
        iv_version         TYPE i
      RETURNING
        VALUE(rs_template) TYPE ty_template
      RAISING
        zcx_abappdf.

    CLASS-METHODS list_versions
      IMPORTING
        iv_form_id         TYPE string
      RETURNING
        VALUE(rt_versions) TYPE ty_versions
      RAISING
        zcx_abappdf.

    CLASS-METHODS get_config
      IMPORTING
        iv_param        TYPE string
      RETURNING
        VALUE(rv_value) TYPE string.

    CLASS-METHODS set_config
      IMPORTING
        iv_param TYPE string
        iv_value TYPE string
      RAISING
        zcx_abappdf.

    CLASS-METHODS use_gotenberg
      RETURNING
        VALUE(rv_yes) TYPE abap_bool.

    CLASS-METHODS normalize_id
      IMPORTING
        iv_form_id        TYPE string
      RETURNING
        VALUE(rv_form_id) TYPE zabappdf_forms-form_id
      RAISING
        zcx_abappdf.

  PRIVATE SECTION.
    CLASS-METHODS current_user
      RETURNING
        VALUE(rv_user) TYPE zabappdf_forms-created_by.

    CLASS-METHODS now
      RETURNING
        VALUE(rv_ts) TYPE utclong.

    CLASS-METHODS ts_iso
      IMPORTING
        iv_ts          TYPE utclong
      RETURNING
        VALUE(rv_text) TYPE string.

    CLASS-METHODS version_number
      IMPORTING
        iv_version   TYPE zabappdf_tmpl-version
      RETURNING
        VALUE(rv_no) TYPE i.

    CLASS-METHODS map_template
      IMPORTING
        is_row             TYPE zabappdf_tmpl
      RETURNING
        VALUE(rs_template) TYPE ty_template.

    CLASS-METHODS prepare_template
      CHANGING
        cs_template TYPE ty_template
      RAISING
        zcx_abappdf.

    CLASS-METHODS request_of
      IMPORTING
        iv_form_id         TYPE string
      RETURNING
        VALUE(rv_request) TYPE string.

    CLASS-METHODS cut
      IMPORTING
        iv_text        TYPE string
        iv_length      TYPE i
      RETURNING
        VALUE(rv_text) TYPE string
      RAISING
        zcx_abappdf.
ENDCLASS.



CLASS zcl_abappdf_forms IMPLEMENTATION.

  METHOD create_form.
    DATA ls_form TYPE zabappdf_forms.
    DATA(lv_id) = normalize_id( iv_form_id ).
    SELECT SINGLE form_id FROM zabappdf_forms WHERE form_id = @lv_id INTO @DATA(lv_exists).
    IF sy-subrc = 0.
      RAISE EXCEPTION TYPE zcx_abappdf EXPORTING textid = zcx_abappdf=>form_exists msgv1 = CONV symsgv( lv_id ).
    ENDIF.
    ls_form-form_id = lv_id.
    ls_form-description = cut( iv_text = iv_description iv_length = zcl_abappdf_config=>description_length ).
    IF ls_form-description IS INITIAL.
      ls_form-description = lv_id.
    ENDIF.
    ls_form-package_name = cut( iv_text = iv_package iv_length = zcl_abappdf_config=>package_length ).
    IF ls_form-package_name IS INITIAL.
      ls_form-package_name = zcl_abappdf_config=>local_package.
    ENDIF.
    ls_form-created_by = current_user( ).
    ls_form-changed_by = ls_form-created_by.
    ls_form-created_at = now( ).
    ls_form-changed_at = ls_form-created_at.
    INSERT zabappdf_forms FROM @ls_form.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_abappdf EXPORTING textid = zcx_abappdf=>form_insert_failed msgv1 = CONV symsgv( lv_id ).
    ENDIF.
  ENDMETHOD.


  METHOD read_form.
    DATA(lv_id) = normalize_id( iv_form_id ).
    SELECT SINGLE FROM zabappdf_forms
      FIELDS form_id, description, package_name, changed_at
      WHERE form_id = @lv_id
      INTO @DATA(ls_row).
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_abappdf EXPORTING textid = zcx_abappdf=>form_missing msgv1 = CONV symsgv( lv_id ).
    ENDIF.
    rs_form-form_id = ls_row-form_id.
    rs_form-description = ls_row-description.
    rs_form-package_name = ls_row-package_name.
    rs_form-transport = request_of( CONV string( lv_id ) ).
    rs_form-changed_at = ts_iso( ls_row-changed_at ).
    SELECT SINGLE version FROM zabappdf_tmpl
      WHERE form_id = @lv_id AND is_active = 'X'
      INTO @DATA(lv_version).
    IF sy-subrc = 0.
      rs_form-version = version_number( lv_version ).
    ENDIF.
  ENDMETHOD.


  METHOD set_transport.
    DATA lv_request TYPE string.
    DATA(lv_id) = normalize_id( iv_form_id ).
    read_form( CONV string( lv_id ) ).
    lv_request = to_upper( iv_request ).
    CONDENSE lv_request NO-GAPS.
    IF strlen( lv_request ) > 20.
      lv_request = substring( val = lv_request len = 20 ).
    ENDIF.
    IF lv_request IS INITIAL
        OR lv_request CN 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'.
      RAISE EXCEPTION TYPE zcx_abappdf EXPORTING textid = zcx_abappdf=>request_chars.
    ENDIF.
    IF lv_id = zcl_abappdf_config=>param_pdf_engine OR lv_id = zcl_abappdf_config=>param_http_timeout.
      RAISE EXCEPTION TYPE zcx_abappdf EXPORTING textid = zcx_abappdf=>form_not_recordable msgv1 = CONV symsgv( lv_id ).
    ENDIF.
    set_config( iv_param = CONV string( lv_id ) iv_value = lv_request ).
  ENDMETHOD.


  METHOD update_form.
    DATA lt_tmpl TYPE STANDARD TABLE OF zabappdf_tmpl WITH EMPTY KEY.
    DATA ls_form TYPE zabappdf_forms.
    DATA ls_tmpl TYPE zabappdf_tmpl.
    DATA(lv_id) = normalize_id( iv_form_id ).
    SELECT SINGLE * FROM zabappdf_forms WHERE form_id = @lv_id INTO @ls_form.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_abappdf EXPORTING textid = zcx_abappdf=>form_missing msgv1 = CONV symsgv( lv_id ).
    ENDIF.
    IF iv_description IS SUPPLIED.
      ls_form-description = cut( iv_text = iv_description iv_length = zcl_abappdf_config=>description_length ).
      IF ls_form-description IS INITIAL.
        ls_form-description = lv_id.
      ENDIF.
    ENDIF.
    IF iv_package IS SUPPLIED.
      ls_form-package_name = cut( iv_text = iv_package iv_length = zcl_abappdf_config=>package_length ).
      IF ls_form-package_name IS INITIAL.
        ls_form-package_name = zcl_abappdf_config=>local_package.
      ENDIF.
    ENDIF.
    ls_form-changed_by = current_user( ).
    ls_form-changed_at = now( ).
    IF iv_new_id IS SUPPLIED AND iv_new_id IS NOT INITIAL.
      DATA(lv_new) = normalize_id( iv_new_id ).
    ELSE.
      lv_new = lv_id.
    ENDIF.
    IF lv_new <> lv_id.
      SELECT SINGLE form_id FROM zabappdf_forms WHERE form_id = @lv_new INTO @DATA(lv_taken).
      IF sy-subrc = 0.
        RAISE EXCEPTION TYPE zcx_abappdf EXPORTING textid = zcx_abappdf=>form_exists msgv1 = CONV symsgv( lv_new ).
      ENDIF.
      SELECT * FROM zabappdf_tmpl WHERE form_id = @lv_id INTO TABLE @lt_tmpl.
      DELETE FROM zabappdf_tmpl WHERE form_id = @lv_id.
      DELETE FROM zabappdf_forms WHERE form_id = @lv_id.
      ls_form-form_id = lv_new.
      INSERT zabappdf_forms FROM @ls_form.
      LOOP AT lt_tmpl INTO ls_tmpl.
        ls_tmpl-form_id = lv_new.
        INSERT zabappdf_tmpl FROM @ls_tmpl.
      ENDLOOP.
      RETURN.
    ENDIF.
    UPDATE zabappdf_forms
      SET description = @ls_form-description,
          package_name = @ls_form-package_name,
          changed_by = @ls_form-changed_by,
          changed_at = @ls_form-changed_at
      WHERE form_id = @lv_id.
  ENDMETHOD.


  METHOD delete_form.
    DATA(lv_id) = normalize_id( iv_form_id ).
    read_form( CONV string( lv_id ) ).
    DELETE FROM zabappdf_tmpl WHERE form_id = @lv_id.
    DELETE FROM zabappdf_forms WHERE form_id = @lv_id.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_abappdf EXPORTING textid = zcx_abappdf=>form_delete_failed msgv1 = CONV symsgv( lv_id ).
    ENDIF.
  ENDMETHOD.


  METHOD list_forms.
    SELECT FROM zabappdf_forms AS form
      LEFT OUTER JOIN zabappdf_tmpl AS tmpl
        ON tmpl~form_id = form~form_id AND tmpl~is_active = 'X'
      FIELDS form~form_id, form~description, form~package_name, form~changed_at, tmpl~version
      ORDER BY form~form_id
      INTO TABLE @DATA(lt_rows).
    LOOP AT lt_rows INTO DATA(ls_row).
      APPEND VALUE #(
        form_id = ls_row-form_id
        description = ls_row-description
        package_name = ls_row-package_name
        transport = request_of( CONV string( ls_row-form_id ) )
        version = version_number( ls_row-version )
        changed_at = ts_iso( ls_row-changed_at ) ) TO rt_forms.
    ENDLOOP.
  ENDMETHOD.


  METHOD save_version.
    DATA ls_row TYPE zabappdf_tmpl.
    DATA ls_in TYPE ty_template.
    DATA lv_max_i TYPE i.
    DATA lv_next TYPE n LENGTH 4.
    ls_in = is_template.
    prepare_template( CHANGING cs_template = ls_in ).
    read_form( ls_in-form_id ).
    SELECT MAX( version ) FROM zabappdf_tmpl WHERE form_id = @ls_in-form_id INTO @DATA(lv_max).
    lv_max_i = version_number( lv_max ).
    IF lv_max_i >= zcl_abappdf_config=>version_max.
      RAISE EXCEPTION TYPE zcx_abappdf EXPORTING textid = zcx_abappdf=>version_limit msgv1 = CONV symsgv( zcl_abappdf_config=>version_max ).
    ENDIF.
    lv_next = lv_max_i + 1.
    ls_row-form_id = ls_in-form_id.
    ls_row-version = lv_next.
    ls_row-html_content = ls_in-html.
    ls_row-css_content = ls_in-css.
    ls_row-header_html = ls_in-header.
    ls_row-footer_html = ls_in-footer.
    ls_row-page_size = ls_in-page_size.
    ls_row-orientation = ls_in-orientation.
    ls_row-margin_top = ls_in-margin_top.
    ls_row-margin_right = ls_in-margin_right.
    ls_row-margin_bottom = ls_in-margin_bottom.
    ls_row-margin_left = ls_in-margin_left.
    ls_row-sample_json = ls_in-sample.
    ls_row-is_active = 'X'.
    ls_row-changed_by = current_user( ).
    ls_row-changed_at = now( ).
    INSERT zabappdf_tmpl FROM @ls_row.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_abappdf EXPORTING textid = zcx_abappdf=>version_save_failed msgv1 = CONV symsgv( ls_in-form_id ).
    ENDIF.
    UPDATE zabappdf_tmpl SET is_active = ' '
      WHERE form_id = @ls_in-form_id AND version <> @ls_row-version.
    UPDATE zabappdf_forms
      SET changed_by = @ls_row-changed_by,
          changed_at = @ls_row-changed_at
      WHERE form_id = @ls_in-form_id.
    rv_version = version_number( ls_row-version ).
  ENDMETHOD.


  METHOD read_active.
    DATA(lv_id) = normalize_id( iv_form_id ).
    read_form( CONV string( lv_id ) ).
    SELECT SINGLE * FROM zabappdf_tmpl
      WHERE form_id = @lv_id AND is_active = 'X'
      INTO @DATA(ls_row).
    IF sy-subrc <> 0.
      SELECT * FROM zabappdf_tmpl
        WHERE form_id = @lv_id
        ORDER BY version DESCENDING
        INTO TABLE @DATA(lt_rows).
      IF lt_rows IS INITIAL.
        RAISE EXCEPTION TYPE zcx_abappdf EXPORTING textid = zcx_abappdf=>template_missing msgv1 = CONV symsgv( lv_id ).
      ENDIF.
      READ TABLE lt_rows INDEX 1 INTO ls_row.
    ENDIF.
    rs_template = map_template( ls_row ).
  ENDMETHOD.


  METHOD read_version.
    DATA lv_num TYPE n LENGTH 4.
    DATA(lv_id) = normalize_id( iv_form_id ).
    read_form( CONV string( lv_id ) ).
    IF iv_version < 1 OR iv_version > zcl_abappdf_config=>version_max.
      RAISE EXCEPTION TYPE zcx_abappdf EXPORTING textid = zcx_abappdf=>version_missing msgv1 = CONV symsgv( iv_version ).
    ENDIF.
    lv_num = iv_version.
    SELECT SINGLE * FROM zabappdf_tmpl
      WHERE form_id = @lv_id AND version = @lv_num
      INTO @DATA(ls_row).
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_abappdf EXPORTING textid = zcx_abappdf=>version_missing msgv1 = CONV symsgv( iv_version ).
    ENDIF.
    rs_template = map_template( ls_row ).
  ENDMETHOD.


  METHOD list_versions.
    DATA(lv_id) = normalize_id( iv_form_id ).
    read_form( CONV string( lv_id ) ).
    SELECT version, changed_by, changed_at FROM zabappdf_tmpl
      WHERE form_id = @lv_id
      ORDER BY version DESCENDING
      INTO TABLE @DATA(lt_rows).
    LOOP AT lt_rows INTO DATA(ls_row).
      APPEND VALUE #(
        version = version_number( ls_row-version )
        changed_by = ls_row-changed_by
        changed_at = ts_iso( ls_row-changed_at ) ) TO rt_versions.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_config.
    DATA lv_param TYPE zabappdf_conf-param.
    lv_param = to_upper( iv_param ).
    SELECT SINGLE param_value FROM zabappdf_conf WHERE param = @lv_param INTO @DATA(lv_value).
    IF sy-subrc = 0 AND lv_value IS NOT INITIAL.
      rv_value = lv_value.
      RETURN.
    ENDIF.
    CASE lv_param.
      WHEN zcl_abappdf_config=>param_pdf_engine.
        rv_value = zcl_abappdf_config=>engine_abap.
      WHEN zcl_abappdf_config=>param_http_timeout.
        rv_value = zcl_abappdf_config=>http_timeout_seconds.
      WHEN OTHERS.
        CLEAR rv_value.
    ENDCASE.
  ENDMETHOD.


  METHOD set_config.
    DATA ls_row TYPE zabappdf_conf.
    ls_row-param = to_upper( iv_param ).
    ls_row-param_value = iv_value.
    IF ls_row-param IS INITIAL.
      RAISE EXCEPTION TYPE zcx_abappdf EXPORTING textid = zcx_abappdf=>config_name_required.
    ENDIF.
    IF strlen( ls_row-param ) > zcl_abappdf_config=>config_name_length
        OR strlen( iv_value ) > zcl_abappdf_config=>config_value_length.
      RAISE EXCEPTION TYPE zcx_abappdf EXPORTING textid = zcx_abappdf=>config_value_long.
    ENDIF.
    MODIFY zabappdf_conf FROM @ls_row.
  ENDMETHOD.


  METHOD use_gotenberg.
    rv_yes = xsdbool( to_upper( get_config( zcl_abappdf_config=>param_pdf_engine ) ) = zcl_abappdf_config=>engine_gotenberg ).
  ENDMETHOD.


  METHOD normalize_id.
    DATA lv_id TYPE string.
    lv_id = to_upper( iv_form_id ).
    CONDENSE lv_id NO-GAPS.
    IF lv_id IS INITIAL OR strlen( lv_id ) > 30
        OR lv_id CN 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_'.
      RAISE EXCEPTION TYPE zcx_abappdf EXPORTING textid = zcx_abappdf=>form_id_chars.
    ENDIF.
    rv_form_id = lv_id.
  ENDMETHOD.


  METHOD current_user.
    rv_user = cl_abap_context_info=>get_user_technical_name( ).
    IF strlen( rv_user ) > 12.
      rv_user = substring( val = rv_user len = 12 ).
    ENDIF.
  ENDMETHOD.


  METHOD now.
    rv_ts = utclong_current( ).
  ENDMETHOD.


  METHOD ts_iso.
    IF iv_ts IS INITIAL.
      RETURN.
    ENDIF.
    CONVERT UTCLONG iv_ts INTO DATE DATA(lv_date) TIME DATA(lv_time) TIME ZONE 'UTC'.
    rv_text = |{ lv_date DATE = ISO }T{ lv_time TIME = ISO }Z|.
  ENDMETHOD.


  METHOD version_number.
    IF iv_version CO ' 0'.
      CLEAR rv_no.
      RETURN.
    ENDIF.
    rv_no = iv_version.
  ENDMETHOD.


  METHOD map_template.
    rs_template-form_id = is_row-form_id.
    rs_template-version = version_number( is_row-version ).
    rs_template-html = is_row-html_content.
    rs_template-css = is_row-css_content.
    rs_template-header = is_row-header_html.
    rs_template-footer = is_row-footer_html.
    rs_template-page_size = is_row-page_size.
    rs_template-orientation = is_row-orientation.
    rs_template-margin_top = is_row-margin_top.
    rs_template-margin_right = is_row-margin_right.
    rs_template-margin_bottom = is_row-margin_bottom.
    rs_template-margin_left = is_row-margin_left.
    rs_template-sample = is_row-sample_json.
    rs_template-changed_by = is_row-changed_by.
    rs_template-changed_at = ts_iso( is_row-changed_at ).
  ENDMETHOD.


  METHOD prepare_template.
    DATA ls_page TYPE zcl_abappdf_renderer=>ty_page.
    cs_template-form_id = normalize_id( cs_template-form_id ).
    cs_template-page_size = to_upper( cs_template-page_size ).
    cs_template-orientation = to_upper( cs_template-orientation ).
    IF cs_template-page_size IS INITIAL.
      cs_template-page_size = zcl_abappdf_config=>page_a4.
      IF cs_template-orientation IS INITIAL.
        cs_template-orientation = zcl_abappdf_config=>orient_portrait.
      ENDIF.
      IF cs_template-margin_top = 0 AND cs_template-margin_right = 0
          AND cs_template-margin_bottom = 0 AND cs_template-margin_left = 0.
        cs_template-margin_top = zcl_abappdf_config=>default_margin_top.
        cs_template-margin_right = zcl_abappdf_config=>default_margin_right.
        cs_template-margin_bottom = zcl_abappdf_config=>default_margin_bottom.
        cs_template-margin_left = zcl_abappdf_config=>default_margin_left.
      ENDIF.
    ENDIF.
    IF cs_template-orientation IS INITIAL.
      cs_template-orientation = zcl_abappdf_config=>orient_portrait.
    ENDIF.
    ls_page-page_size = cs_template-page_size.
    ls_page-orientation = cs_template-orientation.
    ls_page-margin_top = cs_template-margin_top.
    ls_page-margin_right = cs_template-margin_right.
    ls_page-margin_bottom = cs_template-margin_bottom.
    ls_page-margin_left = cs_template-margin_left.
    zcl_abappdf_renderer=>validate_page( ls_page ).
    IF strlen( cs_template-html ) + strlen( cs_template-css ) + strlen( cs_template-header )
        + strlen( cs_template-footer ) + strlen( cs_template-sample ) > zcl_abappdf_config=>template_max_chars.
      RAISE EXCEPTION TYPE zcx_abappdf EXPORTING textid = zcx_abappdf=>template_too_long msgv1 = CONV symsgv( zcl_abappdf_config=>template_max_chars ).
    ENDIF.
  ENDMETHOD.


  METHOD request_of.
    DATA lv_id TYPE string.
    lv_id = to_upper( iv_form_id ).
    CONDENSE lv_id NO-GAPS.
    IF lv_id IS INITIAL OR lv_id = zcl_abappdf_config=>param_pdf_engine
        OR lv_id = zcl_abappdf_config=>param_http_timeout.
      RETURN.
    ENDIF.
    rv_request = get_config( lv_id ).
  ENDMETHOD.


  METHOD cut.
    IF iv_text IS INITIAL.
      RETURN.
    ENDIF.
    IF strlen( iv_text ) > iv_length.
      RAISE EXCEPTION TYPE zcx_abappdf EXPORTING textid = zcx_abappdf=>value_too_long msgv1 = CONV symsgv( iv_length ).
    ENDIF.
    rv_text = iv_text.
  ENDMETHOD.

ENDCLASS.
