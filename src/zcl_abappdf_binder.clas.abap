CLASS zcl_abappdf_binder DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    CLASS-METHODS render
      IMPORTING
        iv_template      TYPE string
        is_data          TYPE any
      RETURNING
        VALUE(rv_result) TYPE string
      RAISING
        zcx_abappdf.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_tag,
        kind  TYPE string,
        path  TYPE string,
        close TYPE string,
      END OF ty_tag.

    TYPES:
      BEGIN OF ty_fmt,
        path    TYPE string,
        pattern TYPE string,
      END OF ty_fmt.

    DATA mt_ctx TYPE STANDARD TABLE OF REF TO data WITH EMPTY KEY.
    DATA mt_rowno TYPE STANDARD TABLE OF i WITH EMPTY KEY.
    DATA mt_fmt TYPE HASHED TABLE OF ty_fmt WITH UNIQUE KEY path.

    METHODS run
      IMPORTING
        iv_template      TYPE string
        is_data          TYPE any
      RETURNING
        VALUE(rv_result) TYPE string
      RAISING
        zcx_abappdf.

    METHODS apply_column_sums
      IMPORTING
        iv_html        TYPE string
      RETURNING
        VALUE(rv_html) TYPE string
      RAISING
        zcx_abappdf.

    METHODS strip_model
      IMPORTING
        iv_html        TYPE string
      RETURNING
        VALUE(rv_html) TYPE string.

    METHODS render_template
      IMPORTING
        iv_template      TYPE string
      RETURNING
        VALUE(rv_result) TYPE string
      RAISING
        zcx_abappdf.

    METHODS find_block_end
      IMPORTING
        iv_template TYPE string
        iv_start    TYPE i
        iv_close    TYPE string
      EXPORTING
        ev_inner    TYPE string
        ev_else     TYPE string
        ev_end      TYPE i
      RAISING
        zcx_abappdf.

    METHODS classify_tag
      IMPORTING
        iv_tag         TYPE string
      RETURNING
        VALUE(rs_tag) TYPE ty_tag.

    METHODS render_each
      IMPORTING
        iv_path          TYPE string
        iv_inner         TYPE string
        iv_else          TYPE string
      RETURNING
        VALUE(rv_result) TYPE string
      RAISING
        zcx_abappdf.

    METHODS render_if
      IMPORTING
        iv_path          TYPE string
        iv_inner         TYPE string
        iv_else          TYPE string
        iv_inverted      TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(rv_result) TYPE string
      RAISING
        zcx_abappdf.

    METHODS render_sum
      IMPORTING
        iv_path        TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.

    METHODS apply_patterns
      IMPORTING
        iv_template        TYPE string
      RETURNING
        VALUE(rv_template) TYPE string.

    METHODS apply_fmt_marks
      IMPORTING
        iv_html        TYPE string
      RETURNING
        VALUE(rv_html) TYPE string.

    METHODS format_display
      IMPORTING
        iv_value       TYPE string
        iv_pattern     TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.

    METHODS remember_pattern
      IMPORTING
        iv_path    TYPE string
        iv_pattern TYPE string.

    METHODS pattern_for
      IMPORTING
        iv_html          TYPE string
        iv_at            TYPE i
        iv_path          TYPE string
      RETURNING
        VALUE(rv_pattern) TYPE string.

    METHODS arabic_digits
      IMPORTING
        iv_text        TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.

    METHODS is_aggregate
      IMPORTING
        iv_tag       TYPE string
      RETURNING
        VALUE(rv_yes) TYPE abap_bool.

    METHODS aggregate
      IMPORTING
        iv_tag         TYPE string
      RETURNING
        VALUE(rv_text) TYPE string
      RAISING
        zcx_abappdf.

    METHODS parse_number
      IMPORTING
        iv_text     TYPE string
      EXPORTING
        ev_value    TYPE decfloat34
        ev_ok       TYPE abap_bool
        ev_decimals TYPE i
        ev_dec_sep  TYPE string
        ev_grouped  TYPE abap_bool.

    METHODS format_number
      IMPORTING
        iv_value       TYPE decfloat34
        iv_decimals    TYPE i
        iv_dec_sep     TYPE string
        iv_group_sep   TYPE string
        iv_arabic      TYPE abap_bool OPTIONAL
      RETURNING
        VALUE(rv_text) TYPE string.

    METHODS number_pattern
      IMPORTING
        iv_value       TYPE string
        iv_pattern     TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.

    METHODS decode_b64url
      IMPORTING
        iv_b64         TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.

    METHODS resolve_text
      IMPORTING
        iv_path        TYPE string
      RETURNING
        VALUE(rv_text) TYPE string
      RAISING
        zcx_abappdf.

    METHODS try_resolve
      IMPORTING
        iv_path  TYPE string
      EXPORTING
        eo_data  TYPE REF TO data
        ev_found TYPE abap_bool.

    METHODS walk
      IMPORTING
        io_data         TYPE REF TO data
        iv_path         TYPE string
      EXPORTING
        eo_data         TYPE REF TO data
      RETURNING
        VALUE(rv_found) TYPE abap_bool.

    METHODS is_truthy
      IMPORTING
        io_data          TYPE REF TO data
      RETURNING
        VALUE(rv_truthy) TYPE abap_bool.

    METHODS value_to_string
      IMPORTING
        io_data        TYPE REF TO data
      RETURNING
        VALUE(rv_text) TYPE string.

    METHODS escape_html
      IMPORTING
        iv_text        TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.

    METHODS trim
      IMPORTING
        iv_text        TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.

    METHODS dot_number
      IMPORTING
        iv_value       TYPE p
        iv_decimals    TYPE i
      RETURNING
        VALUE(rv_text) TYPE string.

    METHODS json_string
      IMPORTING
        iv_json        TYPE string
        iv_key         TYPE string
      RETURNING
        VALUE(rv_value) TYPE string.

    METHODS object_around
      IMPORTING
        iv_json        TYPE string
        iv_at          TYPE i
      RETURNING
        VALUE(rv_obj)  TYPE string.

    METHODS mustache_name
      IMPORTING
        iv_text        TYPE string
      RETURNING
        VALUE(rv_name) TYPE string.

    METHODS find_ci
      IMPORTING
        iv_text      TYPE string
        iv_sub       TYPE string
        iv_off       TYPE i DEFAULT 0
      RETURNING
        VALUE(rv_at) TYPE i.
ENDCLASS.



CLASS zcl_abappdf_binder IMPLEMENTATION.

  METHOD render.
    rv_result = NEW zcl_abappdf_binder( )->run(
      iv_template = iv_template
      is_data     = is_data ).
  ENDMETHOD.


  METHOD run.
    DATA lr_root TYPE REF TO data.
    DATA lv_html TYPE string.
    GET REFERENCE OF is_data INTO lr_root.
    APPEND lr_root TO mt_ctx.
    CLEAR mt_fmt.
    lv_html = apply_column_sums( iv_template ).
    lv_html = apply_patterns( lv_html ).
    rv_result = render_template( strip_model( lv_html ) ).
  ENDMETHOD.


  METHOD apply_column_sums.
    DATA lv_at TYPE i.
    DATA lv_end TYPE i.
    DATA lv_comment TYPE string.
    DATA lv_body TYPE string.
    DATA lv_scan TYPE i.
    DATA lv_sum_at TYPE i.
    DATA lv_obj TYPE string.
    DATA lv_path TYPE string.
    DATA lv_field TYPE string.
    DATA lv_total TYPE string.
    DATA lv_each_at TYPE i.
    DATA lv_close_at TYPE i.
    DATA lv_zero TYPE i.

    rv_html = iv_html.
    "The designer saves the model base64url encoded (<!--abappdf64:...-->);
    "older forms carry plain JSON (<!--abappdf:...-->).
    lv_at = find( val = iv_html sub = '<!--abappdf64:' ).
    IF lv_at >= 0.
      lv_end = find( val = iv_html sub = '-->' off = lv_at ).
      IF lv_end < 0.
        RETURN.
      ENDIF.
      lv_comment = decode_b64url( substring(
        val = iv_html
        off = lv_at + 14
        len = lv_end - lv_at - 14 ) ).
      IF lv_comment IS INITIAL.
        RETURN.
      ENDIF.
    ELSE.
      lv_at = find( val = iv_html sub = '<!--abappdf:' ).
      IF lv_at < 0.
        RETURN.
      ENDIF.
      lv_end = find( val = iv_html sub = '-->' off = lv_at ).
      IF lv_end < 0.
        RETURN.
      ENDIF.
      lv_comment = substring( val = iv_html off = lv_at len = lv_end - lv_at ).
      REPLACE ALL OCCURRENCES OF '- -' IN lv_comment WITH '--'.
    ENDIF.
    lv_body = substring( val = iv_html off = lv_end + 3 ).

    WHILE lv_scan < strlen( lv_comment ).
      lv_sum_at = find( val = lv_comment sub = '"sum":1' off = lv_scan ).
      IF lv_sum_at < 0.
        EXIT.
      ENDIF.
      lv_obj = object_around( iv_json = lv_comment iv_at = lv_sum_at ).
      lv_path = json_string( iv_json = lv_obj iv_key = 'dataPath' ).
      lv_field = mustache_name( lv_obj ).
      IF lv_path IS NOT INITIAL AND lv_field IS NOT INITIAL AND lv_field NS ` `.
        lv_total = escape_html( render_sum( lv_path && '.' && lv_field ) ).
        lv_each_at = find_ci(
          iv_text = lv_body
          iv_sub  = `{{#each ` && lv_path && '}}' ).
        IF lv_each_at >= 0.
          lv_close_at = find_ci(
            iv_text = lv_body
            iv_sub  = '{{/each}}'
            iv_off  = lv_each_at ).
        ELSE.
          lv_close_at = -1.
        ENDIF.
        IF lv_close_at >= 0.
          lv_zero = find( val = lv_body sub = '>0</div>' off = lv_close_at ).
          IF lv_zero < 0.
            lv_zero = find( val = lv_body sub = '>0.00</div>' off = lv_close_at ).
            IF lv_zero >= 0.
              lv_body = substring( val = lv_body off = 0 len = lv_zero + 1 ) &&
                lv_total &&
                substring( val = lv_body off = lv_zero + 5 ).
              lv_zero = -1.
            ENDIF.
          ENDIF.
          IF lv_zero >= 0.
            lv_body = substring( val = lv_body off = 0 len = lv_zero + 1 ) &&
              lv_total &&
              substring( val = lv_body off = lv_zero + 2 ).
          ENDIF.
        ENDIF.
      ENDIF.
      lv_scan = lv_sum_at + 7.
    ENDWHILE.

    rv_html = substring( val = iv_html off = 0 len = lv_end + 3 ) && lv_body.
  ENDMETHOD.


  METHOD strip_model.
    DATA lv_at TYPE i.
    DATA lv_end TYPE i.
    rv_html = iv_html.
    lv_at = find( val = iv_html sub = '<!--abappdf' ).
    IF lv_at < 0.
      RETURN.
    ENDIF.
    lv_end = find( val = iv_html sub = '-->' off = lv_at ).
    IF lv_end < 0.
      RETURN.
    ENDIF.
    rv_html = substring( val = iv_html off = 0 len = lv_at ) &&
      substring( val = iv_html off = lv_end + 3 ).
  ENDMETHOD.


  METHOD render_template.
    DATA lv_pos TYPE i VALUE 0.
    DATA lv_len TYPE i.
    DATA lv_open TYPE i.
    DATA lv_end TYPE i.
    DATA lv_after TYPE i.
    DATA lv_tag_text TYPE string.
    DATA ls_tag TYPE ty_tag.
    DATA lv_inner TYPE string.
    DATA lv_else TYPE string.
    DATA lv_block_end TYPE i.
    DATA lv_piece TYPE string.
    DATA lv_fmt TYPE string.
    DATA lr_section TYPE REF TO data.
    DATA lv_found TYPE abap_bool.
    FIELD-SYMBOLS <section> TYPE any.

    lv_len = strlen( iv_template ).
    WHILE lv_pos < lv_len.
      lv_open = find( val = iv_template sub = '{{' off = lv_pos ).
      IF lv_open < 0.
        rv_result = rv_result && substring( val = iv_template off = lv_pos ).
        RETURN.
      ENDIF.
      IF lv_open > lv_pos.
        rv_result = rv_result && substring(
          val = iv_template
          off = lv_pos
          len = lv_open - lv_pos ).
      ENDIF.

      IF lv_open + 3 <= lv_len AND substring( val = iv_template off = lv_open len = 3 ) = '{{{'.
        lv_end = find( val = iv_template sub = '}}}' off = lv_open + 3 ).
        IF lv_end < 0.
          RAISE EXCEPTION TYPE zcx_abappdf EXPORTING textid = zcx_abappdf=>template_unclosed msgv1 = zcl_abappdf_config=>mark_triple.
        ENDIF.
        lv_tag_text = substring(
          val = iv_template
          off = lv_open + 3
          len = lv_end - lv_open - 3 ).
        rv_result = rv_result && resolve_text( trim( lv_tag_text ) ).
        lv_pos = lv_end + 3.
        CONTINUE.
      ENDIF.

      lv_end = find( val = iv_template sub = '}}' off = lv_open + 2 ).
      IF lv_end < 0.
        RAISE EXCEPTION TYPE zcx_abappdf EXPORTING textid = zcx_abappdf=>template_unclosed msgv1 = zcl_abappdf_config=>mark_double.
      ENDIF.
      lv_tag_text = trim( substring(
        val = iv_template
        off = lv_open + 2
        len = lv_end - lv_open - 2 ) ).
      lv_after = lv_end + 2.
      ls_tag = classify_tag( lv_tag_text ).

      CASE ls_tag-kind.
        WHEN 'comment' OR 'close' OR 'else'.
          lv_pos = lv_after.
        WHEN 'sum'.
          rv_result = rv_result && escape_html( render_sum( ls_tag-path ) ).
          lv_pos = lv_after.
        WHEN 'var'.
          IF is_aggregate( ls_tag-path ) = abap_true.
            lv_piece = aggregate( ls_tag-path ).
          ELSE.
            lv_piece = resolve_text( ls_tag-path ).
          ENDIF.
          lv_fmt = pattern_for(
            iv_html = iv_template
            iv_at   = lv_open
            iv_path = ls_tag-path ).
          IF lv_fmt IS NOT INITIAL.
            lv_piece = format_display( iv_value = lv_piece iv_pattern = lv_fmt ).
          ENDIF.
          rv_result = rv_result && escape_html( lv_piece ).
          lv_pos = lv_after.
        WHEN 'each' OR 'if' OR 'section' OR 'inverted'.
          find_block_end(
            EXPORTING
              iv_template = iv_template
              iv_start    = lv_after
              iv_close    = ls_tag-close
            IMPORTING
              ev_inner    = lv_inner
              ev_else     = lv_else
              ev_end      = lv_block_end ).
          CASE ls_tag-kind.
            WHEN 'each'.
              rv_result = rv_result && render_each(
                iv_path  = ls_tag-path
                iv_inner = lv_inner
                iv_else  = lv_else ).
            WHEN 'if'.
              rv_result = rv_result && render_if(
                iv_path  = ls_tag-path
                iv_inner = lv_inner
                iv_else  = lv_else ).
            WHEN 'inverted'.
              rv_result = rv_result && render_if(
                iv_path     = ls_tag-path
                iv_inner    = lv_inner
                iv_else     = lv_else
                iv_inverted = abap_true ).
            WHEN 'section'.
              CLEAR lr_section.
              CLEAR lv_found.
              try_resolve(
                EXPORTING iv_path = ls_tag-path
                IMPORTING eo_data = lr_section ev_found = lv_found ).
              IF lv_found = abap_true.
                ASSIGN lr_section->* TO <section>.
                IF sy-subrc <> 0
                    OR cl_abap_typedescr=>describe_by_data( <section> )->kind
                        <> cl_abap_typedescr=>kind_table.
                  CLEAR lv_found.
                ENDIF.
              ENDIF.
              IF lv_found = abap_true.
                rv_result = rv_result && render_each(
                  iv_path  = ls_tag-path
                  iv_inner = lv_inner
                  iv_else  = lv_else ).
              ELSE.
                rv_result = rv_result && render_if(
                  iv_path  = ls_tag-path
                  iv_inner = lv_inner
                  iv_else  = lv_else ).
              ENDIF.
          ENDCASE.
          lv_pos = lv_block_end.
      ENDCASE.
    ENDWHILE.
  ENDMETHOD.


  METHOD find_block_end.
    DATA lv_pos TYPE i.
    DATA lv_len TYPE i.
    DATA lv_depth TYPE i VALUE 1.
    DATA lv_open TYPE i.
    DATA lv_end TYPE i.
    DATA lv_tag_text TYPE string.
    DATA ls_tag TYPE ty_tag.
    DATA lv_else_open TYPE i VALUE -1.
    DATA lv_else_after TYPE i.

    lv_pos = iv_start.
    lv_len = strlen( iv_template ).
    WHILE lv_pos < lv_len.
      lv_open = find( val = iv_template sub = '{{' off = lv_pos ).
      IF lv_open < 0.
        RAISE EXCEPTION TYPE zcx_abappdf EXPORTING textid = zcx_abappdf=>block_unclosed msgv1 = CONV symsgv( |/{ iv_close }| ).
      ENDIF.
      IF lv_open + 3 <= lv_len AND substring( val = iv_template off = lv_open len = 3 ) = '{{{'.
        lv_end = find( val = iv_template sub = '}}}' off = lv_open + 3 ).
        IF lv_end < 0.
          RAISE EXCEPTION TYPE zcx_abappdf EXPORTING textid = zcx_abappdf=>template_unclosed msgv1 = zcl_abappdf_config=>mark_triple.
        ENDIF.
        lv_pos = lv_end + 3.
        CONTINUE.
      ENDIF.
      lv_end = find( val = iv_template sub = '}}' off = lv_open + 2 ).
      IF lv_end < 0.
        RAISE EXCEPTION TYPE zcx_abappdf EXPORTING textid = zcx_abappdf=>template_unclosed msgv1 = zcl_abappdf_config=>mark_double.
      ENDIF.
      lv_tag_text = trim( substring(
        val = iv_template
        off = lv_open + 2
        len = lv_end - lv_open - 2 ) ).
      ls_tag = classify_tag( lv_tag_text ).
      IF ls_tag-kind = 'each' OR ls_tag-kind = 'if'
          OR ls_tag-kind = 'section' OR ls_tag-kind = 'inverted'.
        lv_depth = lv_depth + 1.
      ELSEIF ls_tag-kind = 'close'.
        lv_depth = lv_depth - 1.
        IF lv_depth = 0.
          IF to_upper( ls_tag-path ) <> to_upper( iv_close ).
            RAISE EXCEPTION TYPE zcx_abappdf
              EXPORTING
                textid = zcx_abappdf=>block_mismatch
                msgv1  = CONV symsgv( |/{ iv_close }| )
                msgv2  = CONV symsgv( |/{ ls_tag-path }| ).
          ENDIF.
          IF lv_else_open < 0.
            ev_inner = substring( val = iv_template off = iv_start len = lv_open - iv_start ).
            CLEAR ev_else.
          ELSE.
            ev_inner = substring( val = iv_template off = iv_start len = lv_else_open - iv_start ).
            ev_else = substring( val = iv_template off = lv_else_after len = lv_open - lv_else_after ).
          ENDIF.
          ev_end = lv_end + 2.
          RETURN.
        ENDIF.
      ELSEIF ls_tag-kind = 'else' AND lv_depth = 1.
        lv_else_open = lv_open.
        lv_else_after = lv_end + 2.
      ENDIF.
      lv_pos = lv_end + 2.
    ENDWHILE.
    RAISE EXCEPTION TYPE zcx_abappdf EXPORTING textid = zcx_abappdf=>block_unclosed msgv1 = CONV symsgv( |/{ iv_close }| ).
  ENDMETHOD.


  METHOD classify_tag.
    DATA lv_tag TYPE string.
    DATA lv_up TYPE string.
    DATA lv_len TYPE i.

    lv_tag = trim( iv_tag ).
    lv_up = to_upper( lv_tag ).
    lv_len = strlen( lv_tag ).
    IF lv_len = 0.
      rs_tag-kind = 'var'.
      RETURN.
    ENDIF.
    IF substring( val = lv_tag len = 1 ) = '!'.
      rs_tag-kind = 'comment'.
      RETURN.
    ENDIF.
    IF lv_up = 'ELSE'.
      rs_tag-kind = 'else'.
      RETURN.
    ENDIF.
    IF substring( val = lv_tag len = 1 ) = '/'.
      rs_tag-kind = 'close'.
      rs_tag-path = trim( substring( val = lv_tag off = 1 ) ).
      rs_tag-close = rs_tag-path.
      RETURN.
    ENDIF.
    IF lv_len >= 5 AND substring( val = lv_up len = 5 ) = '#EACH'.
      rs_tag-kind = 'each'.
      rs_tag-close = 'each'.
      IF lv_len > 5.
        rs_tag-path = trim( substring( val = lv_tag off = 5 ) ).
      ENDIF.
      IF rs_tag-path IS INITIAL.
        rs_tag-path = '.'.
      ENDIF.
      RETURN.
    ENDIF.
    IF lv_len >= 3 AND substring( val = lv_up len = 3 ) = '#IF'.
      rs_tag-kind = 'if'.
      rs_tag-close = 'if'.
      IF lv_len > 3.
        rs_tag-path = trim( substring( val = lv_tag off = 3 ) ).
      ENDIF.
      IF rs_tag-path IS INITIAL.
        rs_tag-path = '.'.
      ENDIF.
      RETURN.
    ENDIF.
    IF lv_len >= 5 AND substring( val = lv_up len = 5 ) = `#SUM `.
      rs_tag-kind = 'sum'.
      rs_tag-path = trim( substring( val = lv_tag off = 5 ) ).
      RETURN.
    ENDIF.
    IF substring( val = lv_tag len = 1 ) = '#'.
      rs_tag-kind = 'section'.
      rs_tag-path = trim( substring( val = lv_tag off = 1 ) ).
      rs_tag-close = rs_tag-path.
      RETURN.
    ENDIF.
    IF substring( val = lv_tag len = 1 ) = '^'.
      rs_tag-kind = 'inverted'.
      rs_tag-path = trim( substring( val = lv_tag off = 1 ) ).
      rs_tag-close = rs_tag-path.
      RETURN.
    ENDIF.
    rs_tag-kind = 'var'.
    rs_tag-path = lv_tag.
  ENDMETHOD.


  METHOD render_each.
    DATA lr_data TYPE REF TO data.
    DATA lv_found TYPE abap_bool.
    DATA lr_row TYPE REF TO data.
    DATA lv_row_number TYPE i.
    FIELD-SYMBOLS <node> TYPE any.
    FIELD-SYMBOLS <table> TYPE ANY TABLE.
    FIELD-SYMBOLS <row> TYPE any.

    try_resolve(
      EXPORTING iv_path = iv_path
      IMPORTING eo_data = lr_data ev_found = lv_found ).
    IF lv_found = abap_false.
      rv_result = render_template( iv_else ).
      RETURN.
    ENDIF.
    ASSIGN lr_data->* TO <node>.
    IF sy-subrc <> 0.
      rv_result = render_template( iv_else ).
      RETURN.
    ENDIF.
    IF cl_abap_typedescr=>describe_by_data( <node> )->kind = cl_abap_typedescr=>kind_struct.
      APPEND 1 TO mt_rowno.
      APPEND lr_data TO mt_ctx.
      rv_result = render_template( iv_inner ).
      DELETE mt_ctx INDEX lines( mt_ctx ).
      DELETE mt_rowno INDEX lines( mt_rowno ).
      RETURN.
    ENDIF.
    ASSIGN <node> TO <table>.
    IF sy-subrc <> 0 OR lines( <table> ) = 0.
      rv_result = render_template( iv_else ).
      RETURN.
    ENDIF.
    LOOP AT <table> ASSIGNING <row>.
      lv_row_number = lv_row_number + 1.
      APPEND lv_row_number TO mt_rowno.
      GET REFERENCE OF <row> INTO lr_row.
      APPEND lr_row TO mt_ctx.
      rv_result = rv_result && render_template( iv_inner ).
      DELETE mt_ctx INDEX lines( mt_ctx ).
      DELETE mt_rowno INDEX lines( mt_rowno ).
    ENDLOOP.
  ENDMETHOD.


  METHOD render_if.
    DATA lr_data TYPE REF TO data.
    DATA lv_found TYPE abap_bool.
    DATA lv_yes TYPE abap_bool.
    DATA lv_upper TYPE string.
    DATA lv_row TYPE i.

    lv_upper = to_upper( trim( iv_path ) ).
    IF ( lv_upper = 'ROW_EVEN' OR lv_upper = 'ROW_ODD' ) AND lines( mt_rowno ) > 0.
      READ TABLE mt_rowno INDEX lines( mt_rowno ) INTO lv_row.
      lv_yes = xsdbool( lv_row MOD 2 = 0 ).
      IF lv_upper = 'ROW_ODD'.
        lv_yes = xsdbool( lv_yes = abap_false ).
      ENDIF.
      IF iv_inverted = abap_true.
        lv_yes = xsdbool( lv_yes = abap_false ).
      ENDIF.
      IF lv_yes = abap_true.
        rv_result = render_template( iv_inner ).
      ELSE.
        rv_result = render_template( iv_else ).
      ENDIF.
      RETURN.
    ENDIF.

    try_resolve(
      EXPORTING iv_path = iv_path
      IMPORTING eo_data = lr_data ev_found = lv_found ).
    IF lv_found = abap_true.
      lv_yes = is_truthy( lr_data ).
    ENDIF.
    IF iv_inverted = abap_true.
      lv_yes = xsdbool( lv_yes = abap_false ).
    ENDIF.
    IF lv_yes = abap_true.
      rv_result = render_template( iv_inner ).
    ELSE.
      rv_result = render_template( iv_else ).
    ENDIF.
  ENDMETHOD.


  METHOD render_sum.
    DATA lv_path TYPE string.
    DATA lv_table TYPE string.
    DATA lv_field TYPE string.
    DATA lv_len TYPE i.
    DATA lv_i TYPE i.
    DATA lv_dot TYPE i VALUE -1.
    DATA lr_data TYPE REF TO data.
    DATA lr_row TYPE REF TO data.
    DATA lv_found TYPE abap_bool.
    DATA lv_total TYPE p LENGTH 16 DECIMALS 2.
    DATA lv_part TYPE p LENGTH 16 DECIMALS 2.
    DATA lv_frac TYPE abap_bool.
    DATA lv_text TYPE string.
    DATA lv_raw TYPE string.
    DATA lv_clean TYPE string.
    DATA lv_ch TYPE c LENGTH 1.
    DATA lv_len2 TYPE i.
    DATA lv_dotflag TYPE abap_bool.
    FIELD-SYMBOLS <node> TYPE any.
    FIELD-SYMBOLS <table> TYPE ANY TABLE.
    FIELD-SYMBOLS <row> TYPE any.
    FIELD-SYMBOLS <comp> TYPE any.

    rv_text = '0'.
    lv_path = trim( iv_path ).
    IF lv_path IS INITIAL.
      RETURN.
    ENDIF.
    lv_len = strlen( lv_path ).
    DO lv_len TIMES.
      lv_i = lv_len - sy-index.
      IF substring( val = lv_path off = lv_i len = 1 ) = '.'.
        lv_dot = lv_i.
        EXIT.
      ENDIF.
    ENDDO.
    IF lv_dot > 0.
      lv_table = substring( val = lv_path len = lv_dot ).
      lv_field = substring( val = lv_path off = lv_dot + 1 ).
    ELSE.
      lv_table = lv_path.
      CLEAR lv_field.
    ENDIF.
    try_resolve(
      EXPORTING iv_path = lv_table
      IMPORTING eo_data = lr_data ev_found = lv_found ).
    IF lv_found = abap_false OR lr_data IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN lr_data->* TO <node>.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    IF cl_abap_typedescr=>describe_by_data( <node> )->kind <> cl_abap_typedescr=>kind_table.
      RETURN.
    ENDIF.
    ASSIGN <node> TO <table>.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    LOOP AT <table> ASSIGNING <row>.
      IF lv_field IS INITIAL.
        GET REFERENCE OF <row> INTO lr_row.
        lv_text = value_to_string( lr_row ).
      ELSE.
        IF cl_abap_typedescr=>describe_by_data( <row> )->kind <> cl_abap_typedescr=>kind_struct.
          CONTINUE.
        ENDIF.
        ASSIGN COMPONENT to_upper( lv_field ) OF STRUCTURE <row> TO <comp>.
        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.
        GET REFERENCE OF <comp> INTO lr_row.
        lv_text = value_to_string( lr_row ).
      ENDIF.
      CLEAR: lv_clean, lv_dotflag.
      lv_raw = lv_text.
      CONDENSE lv_raw NO-GAPS.
      IF lv_raw CS ',' AND lv_raw NS '.'.
        REPLACE ALL OCCURRENCES OF ',' IN lv_raw WITH '.'.
      ENDIF.
      lv_len2 = strlen( lv_raw ).
      DO lv_len2 TIMES.
        lv_i = sy-index - 1.
        lv_ch = substring( val = lv_raw off = lv_i len = 1 ).
        IF lv_ch = '-' AND lv_clean IS INITIAL.
          lv_clean = '-'.
        ELSEIF lv_ch = '.' AND lv_dotflag = abap_false.
          lv_dotflag = abap_true.
          lv_clean = lv_clean && '.'.
        ELSEIF lv_ch CA '0123456789'.
          lv_clean = lv_clean && lv_ch.
        ENDIF.
      ENDDO.
      IF lv_clean IS INITIAL OR lv_clean = '-' OR lv_clean = '.' OR lv_clean = '-.'.
        CONTINUE.
      ENDIF.
      TRY.
          lv_part = lv_clean.
        CATCH cx_root.
          CONTINUE.
      ENDTRY.
      lv_total = lv_total + lv_part.
      IF lv_dotflag = abap_true.
        lv_frac = abap_true.
      ENDIF.
    ENDLOOP.
    IF lv_frac = abap_true.
      rv_text = dot_number( iv_value = lv_total iv_decimals = 2 ).
    ELSE.
      rv_text = dot_number( iv_value = lv_total iv_decimals = 0 ).
    ENDIF.
  ENDMETHOD.


  METHOD resolve_text.
    DATA lr_data TYPE REF TO data.
    DATA lv_found TYPE abap_bool.
    DATA lv_path TYPE string.
    DATA lv_no TYPE i.

    lv_path = trim( iv_path ).
    IF to_upper( lv_path ) = 'ROW' AND lines( mt_rowno ) > 0.
      READ TABLE mt_rowno INDEX lines( mt_rowno ) INTO lv_no.
      rv_text = |{ lv_no }|.
      RETURN.
    ENDIF.
    try_resolve(
      EXPORTING iv_path = lv_path
      IMPORTING eo_data = lr_data ev_found = lv_found ).
    IF lv_found = abap_false.
      RAISE EXCEPTION TYPE zcx_abappdf
        EXPORTING
          textid = zcx_abappdf=>field_unknown
          msgv1  = CONV symsgv( lv_path ).
    ENDIF.
    rv_text = value_to_string( lr_data ).
  ENDMETHOD.


  METHOD try_resolve.
    DATA lv_path TYPE string.
    DATA lv_skip TYPE i.
    DATA lv_index TYPE i.
    DATA lv_walk TYPE abap_bool.
    DATA lr_ctx TYPE REF TO data.
    DATA lr_found TYPE REF TO data.

    CLEAR eo_data.
    ev_found = abap_false.
    lv_path = trim( iv_path ).
    WHILE strlen( lv_path ) >= 3 AND substring( val = lv_path len = 3 ) = '../'.
      lv_skip = lv_skip + 1.
      lv_path = substring( val = lv_path off = 3 ).
    ENDWHILE.
    lv_path = trim( lv_path ).
    lv_index = lines( mt_ctx ) - lv_skip.
    WHILE lv_index >= 1.
      READ TABLE mt_ctx INDEX lv_index INTO lr_ctx.
      CLEAR lr_found.
      lv_walk = walk(
        EXPORTING io_data = lr_ctx iv_path = lv_path
        IMPORTING eo_data = lr_found ).
      IF lv_walk = abap_true.
        eo_data = lr_found.
        ev_found = abap_true.
        RETURN.
      ENDIF.
      lv_index = lv_index - 1.
    ENDWHILE.
  ENDMETHOD.


  METHOD walk.
    DATA lv_path TYPE string.
    DATA lt_parts TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    DATA lv_part TYPE string.
    DATA lr_cur TYPE REF TO data.
    FIELD-SYMBOLS <node> TYPE any.
    FIELD-SYMBOLS <comp> TYPE any.

    rv_found = abap_false.
    CLEAR eo_data.
    IF io_data IS NOT BOUND.
      RETURN.
    ENDIF.
    lv_path = trim( iv_path ).
    REPLACE ALL OCCURRENCES OF '-' IN lv_path WITH '.'.
    IF lv_path IS INITIAL OR lv_path = '.'.
      eo_data = io_data.
      rv_found = abap_true.
      RETURN.
    ENDIF.
    lr_cur = io_data.
    SPLIT lv_path AT '.' INTO TABLE lt_parts.
    LOOP AT lt_parts INTO lv_part.
      lv_part = trim( lv_part ).
      IF lv_part IS INITIAL OR lv_part = '.'.
        CONTINUE.
      ENDIF.
      ASSIGN lr_cur->* TO <node>.
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.
      IF cl_abap_typedescr=>describe_by_data( <node> )->kind <> cl_abap_typedescr=>kind_struct.
        RETURN.
      ENDIF.
      ASSIGN COMPONENT lv_part OF STRUCTURE <node> TO <comp>.
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.
      GET REFERENCE OF <comp> INTO lr_cur.
    ENDLOOP.
    eo_data = lr_cur.
    rv_found = abap_true.
  ENDMETHOD.


  METHOD is_truthy.
    DATA lo_type TYPE REF TO cl_abap_typedescr.
    FIELD-SYMBOLS <value> TYPE any.
    FIELD-SYMBOLS <table> TYPE ANY TABLE.

    rv_truthy = abap_false.
    IF io_data IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN io_data->* TO <value>.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    lo_type = cl_abap_typedescr=>describe_by_data( <value> ).
    CASE lo_type->kind.
      WHEN cl_abap_typedescr=>kind_table.
        ASSIGN io_data->* TO <table>.
        IF sy-subrc = 0 AND lines( <table> ) > 0.
          rv_truthy = abap_true.
        ENDIF.
      WHEN cl_abap_typedescr=>kind_struct.
        rv_truthy = abap_true.
      WHEN OTHERS.
        IF <value> IS NOT INITIAL.
          rv_truthy = abap_true.
        ENDIF.
    ENDCASE.
  ENDMETHOD.


  METHOD value_to_string.
    DATA lo_type TYPE REF TO cl_abap_typedescr.
    FIELD-SYMBOLS <value> TYPE any.
    DATA lv_text TYPE string.

    IF io_data IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN io_data->* TO <value>.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    lo_type = cl_abap_typedescr=>describe_by_data( <value> ).
    IF lo_type->kind <> cl_abap_typedescr=>kind_elem.
      RETURN.
    ENDIF.
    CASE lo_type->type_kind.
      WHEN cl_abap_typedescr=>typekind_char
        OR cl_abap_typedescr=>typekind_string
        OR cl_abap_typedescr=>typekind_num.
        lv_text = <value>.
        SHIFT lv_text RIGHT DELETING TRAILING space.
      WHEN OTHERS.
        lv_text = |{ <value> }|.
        CONDENSE lv_text.
        IF lv_text CS ','.
          REPLACE ALL OCCURRENCES OF '.' IN lv_text WITH ''.
          REPLACE ALL OCCURRENCES OF ',' IN lv_text WITH '.'.
        ENDIF.
    ENDCASE.
    rv_text = lv_text.
  ENDMETHOD.


  METHOD escape_html.
    rv_text = iv_text.
    REPLACE ALL OCCURRENCES OF '&' IN rv_text WITH '&amp;'.
    REPLACE ALL OCCURRENCES OF '<' IN rv_text WITH '&lt;'.
    REPLACE ALL OCCURRENCES OF '>' IN rv_text WITH '&gt;'.
    REPLACE ALL OCCURRENCES OF '"' IN rv_text WITH '&quot;'.
    REPLACE ALL OCCURRENCES OF `'` IN rv_text WITH '&#39;'.
  ENDMETHOD.


  METHOD trim.
    rv_text = iv_text.
    SHIFT rv_text LEFT DELETING LEADING space.
    SHIFT rv_text RIGHT DELETING TRAILING space.
  ENDMETHOD.


  METHOD dot_number.
    DATA lv_value TYPE p LENGTH 16 DECIMALS 2.
    DATA lv_neg TYPE abap_bool.
    DATA lv_whole TYPE i.
    DATA lv_frac TYPE i.
    lv_value = iv_value.
    IF lv_value < 0.
      lv_neg = abap_true.
      lv_value = - lv_value.
    ENDIF.
    lv_whole = trunc( lv_value ).
    lv_frac = ( lv_value - lv_whole ) * 100.
    IF lv_frac >= 100.
      lv_whole = lv_whole + 1.
      lv_frac = lv_frac - 100.
    ENDIF.
    IF iv_decimals = 0.
      rv_text = |{ lv_whole }|.
    ELSE.
      rv_text = |{ lv_whole }.{ lv_frac WIDTH = 2 ALIGN = RIGHT PAD = '0' }|.
    ENDIF.
    CONDENSE rv_text NO-GAPS.
    IF lv_neg = abap_true AND lv_value <> 0.
      rv_text = '-' && rv_text.
    ENDIF.
  ENDMETHOD.


  METHOD json_string.
    DATA lv_key TYPE string.
    DATA lv_at TYPE i.
    DATA lv_pos TYPE i.
    DATA lv_len TYPE i.
    DATA lv_ch TYPE string.
    DATA lv_esc TYPE abap_bool.
    lv_key = |"{ iv_key }":"|.
    lv_at = find( val = iv_json sub = lv_key ).
    IF lv_at < 0.
      lv_at = find( val = to_lower( iv_json ) sub = to_lower( lv_key ) ).
    ENDIF.
    IF lv_at < 0.
      RETURN.
    ENDIF.
    lv_pos = lv_at + strlen( lv_key ).
    lv_len = strlen( iv_json ).
    WHILE lv_pos < lv_len.
      lv_ch = substring( val = iv_json off = lv_pos len = 1 ).
      IF lv_esc = abap_true.
        rv_value = rv_value && lv_ch.
        lv_esc = abap_false.
      ELSEIF lv_ch = '\'.
        lv_esc = abap_true.
      ELSEIF lv_ch = '"'.
        RETURN.
      ELSE.
        rv_value = rv_value && lv_ch.
      ENDIF.
      lv_pos = lv_pos + 1.
    ENDWHILE.
  ENDMETHOD.


  METHOD object_around.
    DATA lv_pos TYPE i.
    DATA lv_start TYPE i.
    DATA lv_depth TYPE i.
    DATA lv_in TYPE abap_bool.
    DATA lv_esc TYPE abap_bool.
    DATA lv_ch TYPE c LENGTH 1.
    DATA lt_open TYPE STANDARD TABLE OF i WITH EMPTY KEY.
    " Scan forward up to iv_at and keep a stack of open objects. Braces
    " inside JSON strings (such as {{AMOUNT}}) are skipped, so the top of
    " the stack is the object that really encloses iv_at.
    WHILE lv_pos < iv_at AND lv_pos < strlen( iv_json ).
      lv_ch = substring( val = iv_json off = lv_pos len = 1 ).
      IF lv_in = abap_true.
        IF lv_esc = abap_true.
          lv_esc = abap_false.
        ELSEIF lv_ch = '\'.
          lv_esc = abap_true.
        ELSEIF lv_ch = '"'.
          lv_in = abap_false.
        ENDIF.
      ELSEIF lv_ch = '"'.
        lv_in = abap_true.
      ELSEIF lv_ch = '{'.
        APPEND lv_pos TO lt_open.
      ELSEIF lv_ch = '}' AND lt_open IS NOT INITIAL.
        DELETE lt_open INDEX lines( lt_open ).
      ENDIF.
      lv_pos = lv_pos + 1.
    ENDWHILE.
    IF lt_open IS INITIAL.
      RETURN.
    ENDIF.
    lv_start = lt_open[ lines( lt_open ) ].
    CLEAR lv_in.
    CLEAR lv_esc.
    lv_pos = lv_start.
    WHILE lv_pos < strlen( iv_json ).
      lv_ch = substring( val = iv_json off = lv_pos len = 1 ).
      IF lv_in = abap_true.
        IF lv_esc = abap_true.
          lv_esc = abap_false.
        ELSEIF lv_ch = '\'.
          lv_esc = abap_true.
        ELSEIF lv_ch = '"'.
          lv_in = abap_false.
        ENDIF.
      ELSEIF lv_ch = '"'.
        lv_in = abap_true.
      ELSEIF lv_ch = '{'.
        lv_depth = lv_depth + 1.
      ELSEIF lv_ch = '}'.
        lv_depth = lv_depth - 1.
        IF lv_depth = 0.
          rv_obj = substring( val = iv_json off = lv_start len = lv_pos - lv_start + 1 ).
          RETURN.
        ENDIF.
      ENDIF.
      lv_pos = lv_pos + 1.
    ENDWHILE.
  ENDMETHOD.


  METHOD mustache_name.
    DATA lv_at TYPE i.
    DATA lv_end TYPE i.
    DATA lv_name TYPE string.
    lv_at = 0.
    WHILE lv_at < strlen( iv_text ).
      lv_at = find( val = iv_text sub = '{{' off = lv_at ).
      IF lv_at < 0.
        RETURN.
      ENDIF.
      lv_end = find( val = iv_text sub = '}}' off = lv_at + 2 ).
      IF lv_end < 0.
        RETURN.
      ENDIF.
      lv_name = trim( substring( val = iv_text off = lv_at + 2 len = lv_end - lv_at - 2 ) ).
      IF lv_name IS NOT INITIAL
          AND substring( val = lv_name len = 1 ) <> '#'
          AND substring( val = lv_name len = 1 ) <> '/'
          AND substring( val = lv_name len = 1 ) <> '^'
          AND substring( val = lv_name len = 1 ) <> '!'.
        rv_name = lv_name.
        RETURN.
      ENDIF.
      lv_at = lv_end + 2.
    ENDWHILE.
  ENDMETHOD.


  METHOD find_ci.
    rv_at = find( val = to_upper( iv_text ) sub = to_upper( iv_sub ) off = iv_off ).
  ENDMETHOD.


  METHOD apply_patterns.
    DATA lv_mark TYPE string VALUE '<!--abappdf:'.
    DATA lv_at TYPE i.
    DATA lv_end TYPE i.
    DATA lv_json TYPE string.
    DATA lv_body TYPE string.
    DATA lv_pos TYPE i.
    DATA lv_len TYPE i.
    DATA lv_obj_at TYPE i.
    DATA lv_depth TYPE i.
    DATA lv_in_str TYPE abap_bool.
    DATA lv_esc TYPE abap_bool.
    DATA lv_ch TYPE c LENGTH 1.
    DATA lv_obj TYPE string.
    DATA lv_text TYPE string.
    DATA lv_fmt TYPE string.
    DATA lv_path TYPE string.
    DATA lv_value TYPE string.
    DATA lv_shown TYPE string.

    rv_template = iv_template.
    lv_at = find( val = iv_template sub = '<!--abappdf64:' ).
    IF lv_at >= 0.
      lv_mark = '<!--abappdf64:'.
    ELSE.
      lv_at = find( val = iv_template sub = lv_mark ).
      IF lv_at < 0.
        rv_template = apply_fmt_marks( iv_template ).
        RETURN.
      ENDIF.
    ENDIF.
    lv_end = find( val = iv_template sub = '-->' off = lv_at ).
    IF lv_end < 0.
      RETURN.
    ENDIF.
    lv_json = substring(
      val = iv_template
      off = lv_at + strlen( lv_mark )
      len = lv_end - lv_at - strlen( lv_mark ) ).
    IF lv_mark = '<!--abappdf64:'.
      lv_json = decode_b64url( lv_json ).
      IF lv_json IS INITIAL.
        rv_template = substring( val = iv_template off = 0 len = lv_end + 3 ) &&
          apply_fmt_marks( substring( val = iv_template off = lv_end + 3 ) ).
        RETURN.
      ENDIF.
    ELSE.
      REPLACE ALL OCCURRENCES OF '- -' IN lv_json WITH '--'.
    ENDIF.
    IF lv_json NS '"dateFmt"' AND lv_json NS 'Date/Time Field'.
      rv_template = substring( val = iv_template off = 0 len = lv_end + 3 ) &&
        apply_fmt_marks( substring( val = iv_template off = lv_end + 3 ) ).
      RETURN.
    ENDIF.
    lv_body = apply_fmt_marks( substring( val = iv_template off = lv_end + 3 ) ).
    lv_pos = find( val = lv_json sub = '"widgets":[' ).
    IF lv_pos < 0.
      rv_template = substring( val = iv_template off = 0 len = lv_end + 3 ) && lv_body.
      RETURN.
    ENDIF.
    lv_pos = lv_pos + strlen( '"widgets":[' ).
    lv_len = strlen( lv_json ).
    WHILE lv_pos < lv_len.
      lv_ch = substring( val = lv_json off = lv_pos len = 1 ).
      IF lv_ch = ']'.
        EXIT.
      ENDIF.
      IF lv_ch <> '{'.
        lv_pos = lv_pos + 1.
        CONTINUE.
      ENDIF.
      lv_obj_at = lv_pos.
      lv_depth = 0.
      lv_in_str = abap_false.
      lv_esc = abap_false.
      WHILE lv_pos < lv_len.
        lv_ch = substring( val = lv_json off = lv_pos len = 1 ).
        IF lv_in_str = abap_true.
          IF lv_esc = abap_true.
            lv_esc = abap_false.
          ELSEIF lv_ch = '\'.
            lv_esc = abap_true.
          ELSEIF lv_ch = '"'.
            lv_in_str = abap_false.
          ENDIF.
        ELSEIF lv_ch = '"'.
          lv_in_str = abap_true.
        ELSEIF lv_ch = '{'.
          lv_depth = lv_depth + 1.
        ELSEIF lv_ch = '}'.
          lv_depth = lv_depth - 1.
          IF lv_depth = 0.
            lv_obj = substring(
              val = lv_json
              off = lv_obj_at
              len = lv_pos - lv_obj_at + 1 ).
            lv_pos = lv_pos + 1.
            EXIT.
          ENDIF.
        ENDIF.
        lv_pos = lv_pos + 1.
      ENDWHILE.
      lv_fmt = json_string( iv_json = lv_obj iv_key = 'dateFmt' ).
      lv_text = json_string( iv_json = lv_obj iv_key = 'text' ).
      IF lv_fmt IS INITIAL
          AND json_string( iv_json = lv_obj iv_key = 'type' ) = 'Date/Time Field'.
        lv_fmt = 'YYYY-MM-DD'.
      ENDIF.
      lv_text = trim( lv_text ).
      IF lv_fmt IS INITIAL
          OR strlen( lv_text ) < 5
          OR substring( val = lv_text len = 2 ) <> '{{'
          OR substring( val = lv_text off = strlen( lv_text ) - 2 len = 2 ) <> '}}'.
        CONTINUE.
      ENDIF.
      lv_path = trim( substring( val = lv_text off = 2 len = strlen( lv_text ) - 4 ) ).
      IF lv_path IS INITIAL OR lv_path CS ` `.
        CONTINUE.
      ENDIF.
      remember_pattern( iv_path = lv_path iv_pattern = lv_fmt ).
      TRY.
          lv_value = resolve_text( lv_path ).
        CATCH zcx_abappdf.
          CONTINUE.
      ENDTRY.
      lv_shown = format_display( iv_value = lv_value iv_pattern = lv_fmt ).
      IF lv_shown <> lv_value.
        REPLACE FIRST OCCURRENCE OF lv_text IN lv_body WITH lv_shown.
      ENDIF.
    ENDWHILE.
    rv_template = substring( val = iv_template off = 0 len = lv_end + 3 ) && lv_body.
  ENDMETHOD.


  METHOD apply_fmt_marks.
    DATA lv_pos TYPE i.
    DATA lv_at TYPE i.
    DATA lv_endq TYPE i.
    DATA lv_fmt TYPE string.
    DATA lv_gt TYPE i.
    DATA lv_close TYPE i.
    DATA lv_path TYPE string.
    DATA lv_value TYPE string.
    DATA lv_shown TYPE string.
    DATA lv_mark TYPE string VALUE 'data-fmt="'.

    rv_html = iv_html.
    WHILE lv_pos < strlen( rv_html ).
      lv_at = find( val = rv_html sub = lv_mark off = lv_pos ).
      IF lv_at < 0.
        RETURN.
      ENDIF.
      lv_endq = find(
        val = rv_html
        sub = '"'
        off = lv_at + strlen( lv_mark ) ).
      IF lv_endq < 0.
        RETURN.
      ENDIF.
      lv_fmt = substring(
        val = rv_html
        off = lv_at + strlen( lv_mark )
        len = lv_endq - lv_at - strlen( lv_mark ) ).
      lv_gt = lv_endq + 1.
      IF lv_gt < strlen( rv_html )
          AND substring( val = rv_html off = lv_gt len = 1 ) = '>'.
        lv_gt = lv_gt + 1.
      ENDIF.
      IF lv_gt + 2 > strlen( rv_html )
          OR substring( val = rv_html off = lv_gt len = 2 ) <> '{{'.
        lv_pos = lv_endq + 1.
        CONTINUE.
      ENDIF.
      lv_close = find( val = rv_html sub = '}}' off = lv_gt + 2 ).
      IF lv_close < 0.
        RETURN.
      ENDIF.
      lv_path = trim( substring(
        val = rv_html
        off = lv_gt + 2
        len = lv_close - lv_gt - 2 ) ).
      IF ( strlen( lv_path ) > 0 AND substring( val = lv_path len = 1 ) CA '#/^' )
          OR is_aggregate( lv_path ) = abap_true.
        lv_pos = lv_close + 2.
        CONTINUE.
      ENDIF.
      remember_pattern( iv_path = lv_path iv_pattern = lv_fmt ).
      TRY.
          lv_value = resolve_text( lv_path ).
        CATCH zcx_abappdf.
          lv_pos = lv_close + 2.
          CONTINUE.
      ENDTRY.
      lv_shown = format_display( iv_value = lv_value iv_pattern = lv_fmt ).
      IF lv_shown <> lv_value.
        rv_html = substring( val = rv_html off = 0 len = lv_gt ) &&
          lv_shown &&
          substring( val = rv_html off = lv_close + 2 ).
        lv_pos = lv_gt + strlen( lv_shown ).
      ELSE.
        lv_pos = lv_close + 2.
      ENDIF.
    ENDWHILE.
  ENDMETHOD.


  METHOD format_display.
    DATA lv_digits TYPE string.
    DATA lv_len TYPE i.
    DATA lv_i TYPE i.
    DATA lv_ch TYPE c LENGTH 1.
    DATA lv_day TYPE string.
    DATA lv_month TYPE string.
    DATA lv_year TYPE string.
    DATA lv_hour TYPE string.
    DATA lv_min TYPE string.
    DATA lv_sec TYPE string.
    DATA lv_date TYPE string.
    DATA lv_time TYPE string.
    DATA lv_head TYPE string.

    rv_text = iv_value.
    IF iv_pattern IS INITIAL OR iv_value IS INITIAL.
      RETURN.
    ENDIF.
    lv_head = substring( val = iv_pattern len = 1 ).
    IF lv_head CA '#0'
        OR ( strlen( iv_pattern ) > 2
          AND substring( val = iv_pattern len = 2 ) = 'AR'
          AND substring( val = iv_pattern off = 2 len = 1 ) CA '#0' ).
      rv_text = number_pattern( iv_value = iv_value iv_pattern = iv_pattern ).
      RETURN.
    ENDIF.
    lv_len = strlen( iv_value ).
    DO lv_len TIMES.
      lv_i = sy-index - 1.
      lv_ch = substring( val = iv_value off = lv_i len = 1 ).
      IF lv_ch CA '0123456789'.
        lv_digits = lv_digits && lv_ch.
      ENDIF.
    ENDDO.
    IF strlen( lv_digits ) = 8.
      lv_day = substring( val = lv_digits off = 0 len = 2 ).
      lv_month = substring( val = lv_digits off = 2 len = 2 ).
      lv_year = substring( val = lv_digits off = 4 len = 4 ).
      CASE iv_pattern.
        WHEN 'MM/DD/YYYY'.
          lv_date = |{ lv_month }/{ lv_day }/{ lv_year }|.
        WHEN 'DD.MM.YYYY'.
          lv_date = |{ lv_day }.{ lv_month }.{ lv_year }|.
        WHEN 'YYYY/MM/DD'.
          lv_date = |{ lv_year }/{ lv_month }/{ lv_day }|.
        WHEN 'YYYY-MM-DD' OR 'YYYY-MM-DD HH:MM'.
          lv_date = |{ lv_year }-{ lv_month }-{ lv_day }|.
        WHEN 'AR'.
          lv_date = arabic_digits( |{ lv_year }/{ lv_month }/{ lv_day }| ).
        WHEN OTHERS.
          lv_date = |{ lv_day }/{ lv_month }/{ lv_year }|.
      ENDCASE.
      IF iv_pattern = 'YYYY-MM-DD HH:MM' OR iv_pattern = 'DD/MM/YYYY HH:MM'.
        rv_text = |{ lv_date } 00:00|.
      ELSEIF iv_pattern CP 'HH*'.
        RETURN.
      ELSE.
        rv_text = lv_date.
      ENDIF.
      RETURN.
    ENDIF.
    IF strlen( lv_digits ) = 6 OR strlen( lv_digits ) = 4.
      lv_hour = substring( val = lv_digits off = 0 len = 2 ).
      lv_min = substring( val = lv_digits off = 2 len = 2 ).
      IF strlen( lv_digits ) = 6.
        lv_sec = substring( val = lv_digits off = 4 len = 2 ).
      ELSE.
        lv_sec = '00'.
      ENDIF.
      lv_time = |{ lv_hour }:{ lv_min }|.
      CASE iv_pattern.
        WHEN 'HH:MM'.
          rv_text = lv_time.
        WHEN 'HH:MM:SS'.
          rv_text = |{ lv_hour }:{ lv_min }:{ lv_sec }|.
        WHEN 'YYYY-MM-DD HH:MM' OR 'DD/MM/YYYY HH:MM'.
          rv_text = lv_time.
        WHEN OTHERS.
          RETURN.
      ENDCASE.
    ENDIF.
  ENDMETHOD.


  METHOD remember_pattern.
    DATA ls_fmt TYPE ty_fmt.
    FIELD-SYMBOLS <fmt> TYPE ty_fmt.
    IF iv_pattern IS INITIAL OR iv_path IS INITIAL.
      RETURN.
    ENDIF.
    ls_fmt-path = to_upper( trim( iv_path ) ).
    ls_fmt-pattern = trim( iv_pattern ).
    IF ls_fmt-path IS INITIAL OR ls_fmt-pattern IS INITIAL.
      RETURN.
    ENDIF.
    READ TABLE mt_fmt ASSIGNING <fmt> WITH TABLE KEY path = ls_fmt-path.
    IF sy-subrc = 0.
      <fmt>-pattern = ls_fmt-pattern.
    ELSE.
      INSERT ls_fmt INTO TABLE mt_fmt.
    ENDIF.
  ENDMETHOD.


  METHOD pattern_for.
    DATA lv_from TYPE i.
    DATA lv_prefix TYPE string.
    DATA lv_len TYPE i.
    DATA lv_at TYPE i.
    DATA lv_hit TYPE i.
    DATA lv_endq TYPE i.
    DATA lv_key TYPE string VALUE 'data-fmt="'.
    DATA lv_prev TYPE i.
    DATA lv_ch TYPE c LENGTH 1.
    FIELD-SYMBOLS <fmt> TYPE ty_fmt.

    IF iv_at > 0.
      lv_from = iv_at - 120.
      IF lv_from < 0.
        lv_from = 0.
      ENDIF.
      lv_prefix = substring( val = iv_html off = lv_from len = iv_at - lv_from ).
      lv_len = strlen( lv_prefix ).
      WHILE lv_len > 0.
        lv_ch = substring( val = lv_prefix off = lv_len - 1 len = 1 ).
        IF lv_ch <> ' '.
          EXIT.
        ENDIF.
        lv_len = lv_len - 1.
        lv_prefix = substring( val = lv_prefix off = 0 len = lv_len ).
      ENDWHILE.
      IF lv_len > 1
          AND substring( val = lv_prefix off = lv_len - 1 len = 1 ) = '>'.
        lv_prefix = substring( val = lv_prefix off = 0 len = lv_len - 1 ).
        lv_len = strlen( lv_prefix ).
        IF lv_len > 1
            AND substring( val = lv_prefix off = lv_len - 1 len = 1 ) = '"'.
          lv_hit = -1.
          lv_at = 0.
          WHILE lv_at < lv_len.
            lv_endq = find( val = lv_prefix sub = lv_key off = lv_at ).
            IF lv_endq < 0.
              EXIT.
            ENDIF.
            lv_hit = lv_endq.
            lv_at = lv_endq + 1.
          ENDWHILE.
          IF lv_hit >= 0.
            lv_at = lv_hit + strlen( lv_key ).
            lv_endq = find( val = lv_prefix sub = '"' off = lv_at ).
            IF lv_endq = lv_len - 1.
              rv_pattern = trim( substring(
                val = lv_prefix
                off = lv_at
                len = lv_endq - lv_at ) ).
              IF rv_pattern IS NOT INITIAL.
                RETURN.
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.
      lv_prev = iv_at - 1.
      WHILE lv_prev >= 0.
        lv_ch = substring( val = iv_html off = lv_prev len = 1 ).
        IF lv_ch <> ' '.
          EXIT.
        ENDIF.
        lv_prev = lv_prev - 1.
      ENDWHILE.
      IF lv_prev >= 0 AND lv_ch = '"'.
        RETURN.
      ENDIF.
    ENDIF.
    READ TABLE mt_fmt ASSIGNING <fmt>
      WITH TABLE KEY path = to_upper( trim( iv_path ) ).
    IF sy-subrc = 0.
      rv_pattern = <fmt>-pattern.
    ENDIF.
  ENDMETHOD.


  METHOD arabic_digits.
    DATA lv_len TYPE i.
    DATA lv_i TYPE i.
    DATA lv_ch TYPE c LENGTH 1.
    CONSTANTS lc_digits TYPE string VALUE '٠١٢٣٤٥٦٧٨٩'.
    lv_len = strlen( iv_text ).
    DO lv_len TIMES.
      lv_i = sy-index - 1.
      lv_ch = substring( val = iv_text off = lv_i len = 1 ).
      IF lv_ch CA '0123456789'.
        rv_text = rv_text && substring( val = lc_digits off = CONV i( lv_ch ) len = 1 ).
      ELSE.
        rv_text = rv_text && lv_ch.
      ENDIF.
    ENDDO.
  ENDMETHOD.


  METHOD is_aggregate.
    DATA lv_tag TYPE string.
    DATA lv_word TYPE string.
    DATA lv_rest TYPE string.
    lv_tag = condense( iv_tag ).
    SPLIT lv_tag AT ` ` INTO lv_word lv_rest.
    lv_word = to_lower( lv_word ).
    IF lv_rest IS NOT INITIAL
        AND ( lv_word = 'sum' OR lv_word = 'count'
          OR lv_word = 'avg' OR lv_word = 'min' OR lv_word = 'max' ).
      rv_yes = abap_true.
    ENDIF.
  ENDMETHOD.


  METHOD parse_number.
    DATA lv_text TYPE string.
    DATA lv_clean TYPE string.
    DATA lv_len TYPE i.
    DATA lv_i TYPE i.
    DATA lv_c TYPE c LENGTH 1.
    DATA lv_neg TYPE abap_bool.
    DATA lv_dot TYPE i.
    DATA lv_comma TYPE i.
    DATA lv_dots TYPE i.
    DATA lv_commas TYPE i.
    DATA lv_dec TYPE string.
    DATA lv_grp TYPE string.
    DATA lv_at TYPE i.
    DATA lv_digit TYPE string.
    CONSTANTS lc_digits TYPE string VALUE '٠١٢٣٤٥٦٧٨٩'.
    CONSTANTS lc_dec TYPE string VALUE '٫'.
    CONSTANTS lc_grp TYPE string VALUE '٬'.

    CLEAR: ev_value, ev_ok, ev_decimals, ev_dec_sep, ev_grouped.
    lv_text = iv_text.
    DO 10 TIMES.
      lv_digit = substring( val = lc_digits off = sy-index - 1 len = 1 ).
      REPLACE ALL OCCURRENCES OF lv_digit IN lv_text WITH |{ sy-index - 1 }|.
    ENDDO.
    REPLACE ALL OCCURRENCES OF lc_dec IN lv_text WITH '.'.
    REPLACE ALL OCCURRENCES OF lc_grp IN lv_text WITH ','.
    lv_len = strlen( lv_text ).
    DO lv_len TIMES.
      lv_i = sy-index - 1.
      lv_c = substring( val = lv_text off = lv_i len = 1 ).
      IF lv_c CA '0123456789'.
        lv_clean = lv_clean && lv_c.
      ELSEIF lv_c = '.'.
        lv_clean = lv_clean && lv_c.
        lv_dots = lv_dots + 1.
      ELSEIF lv_c = ','.
        lv_clean = lv_clean && lv_c.
        lv_commas = lv_commas + 1.
      ELSEIF lv_c = '-'.
        lv_neg = abap_true.
      ENDIF.
    ENDDO.
    IF lv_clean NA '0123456789'.
      RETURN.
    ENDIF.
    lv_dot = find( val = lv_clean sub = '.' occ = -1 ).
    lv_comma = find( val = lv_clean sub = ',' occ = -1 ).
    IF lv_dot >= 0 AND lv_comma >= 0.
      IF lv_dot > lv_comma.
        lv_dec = '.'.
        lv_grp = ','.
      ELSE.
        lv_dec = ','.
        lv_grp = '.'.
      ENDIF.
    ELSEIF lv_comma >= 0.
      IF lv_commas = 1 AND strlen( lv_clean ) - lv_comma - 1 <> 3.
        lv_dec = ','.
      ELSE.
        lv_grp = ','.
      ENDIF.
    ELSEIF lv_dot >= 0.
      IF lv_dots = 1.
        lv_dec = '.'.
      ELSE.
        lv_grp = '.'.
      ENDIF.
    ENDIF.
    IF lv_grp IS NOT INITIAL.
      REPLACE ALL OCCURRENCES OF lv_grp IN lv_clean WITH ``.
      ev_grouped = abap_true.
    ENDIF.
    IF lv_dec IS NOT INITIAL.
      lv_at = find( val = lv_clean sub = lv_dec occ = -1 ).
      ev_decimals = strlen( lv_clean ) - lv_at - 1.
      REPLACE ALL OCCURRENCES OF lv_dec IN lv_clean WITH '.'.
      ev_dec_sep = lv_dec.
    ENDIF.
    IF strlen( lv_clean ) > 0 AND substring( val = lv_clean len = 1 ) = '.'.
      lv_clean = '0' && lv_clean.
    ENDIF.
    IF strlen( lv_clean ) > 0
        AND substring( val = lv_clean off = strlen( lv_clean ) - 1 len = 1 ) = '.'.
      lv_clean = lv_clean && '0'.
    ENDIF.
    IF lv_clean CN '0123456789.' OR strlen( lv_clean ) > 30.
      RETURN.
    ENDIF.
    TRY.
        ev_value = lv_clean.
      CATCH cx_root.
        RETURN.
    ENDTRY.
    IF lv_neg = abap_true.
      ev_value = 0 - ev_value.
    ENDIF.
    ev_ok = abap_true.
  ENDMETHOD.


  METHOD format_number.
    DATA lv_p TYPE p LENGTH 16 DECIMALS 6.
    DATA lv_raw TYPE string.
    DATA lv_int TYPE string.
    DATA lv_frac TYPE string.
    DATA lv_out TYPE string.
    DATA lv_len TYPE i.
    DATA lv_count TYPE i.
    DATA lv_i TYPE i.
    DATA lv_c TYPE c LENGTH 1.
    DATA lv_decimals TYPE i.
    DATA lv_neg TYPE abap_bool.
    DATA lv_dec TYPE string.
    DATA lv_grp TYPE string.
    CONSTANTS lc_dec TYPE string VALUE '٫'.
    CONSTANTS lc_grp TYPE string VALUE '٬'.

    lv_decimals = iv_decimals.
    IF lv_decimals < 0.
      lv_decimals = 0.
    ELSEIF lv_decimals > 6.
      lv_decimals = 6.
    ENDIF.
    lv_p = round( val = iv_value dec = lv_decimals ).
    IF lv_p < 0.
      lv_neg = abap_true.
      lv_p = 0 - lv_p.
    ENDIF.
    lv_raw = |{ lv_p }|.
    SPLIT lv_raw AT '.' INTO lv_int lv_frac.
    IF lv_decimals > 0.
      lv_frac = lv_frac && '000000'.
      lv_frac = substring( val = lv_frac len = lv_decimals ).
    ELSE.
      CLEAR lv_frac.
    ENDIF.
    lv_dec = iv_dec_sep.
    IF lv_dec IS INITIAL.
      lv_dec = '.'.
    ENDIF.
    lv_grp = iv_group_sep.
    IF iv_arabic = abap_true.
      lv_dec = lc_dec.
      IF lv_grp IS NOT INITIAL.
        lv_grp = lc_grp.
      ENDIF.
    ENDIF.
    lv_len = strlen( lv_int ).
    lv_i = lv_len.
    WHILE lv_i > 0.
      lv_i = lv_i - 1.
      lv_c = substring( val = lv_int off = lv_i len = 1 ).
      IF lv_count > 0 AND lv_count MOD 3 = 0 AND lv_grp IS NOT INITIAL.
        lv_out = lv_grp && lv_out.
      ENDIF.
      lv_out = lv_c && lv_out.
      lv_count = lv_count + 1.
    ENDWHILE.
    IF lv_frac IS NOT INITIAL.
      lv_out = lv_out && lv_dec && lv_frac.
    ENDIF.
    IF lv_neg = abap_true AND lv_p <> 0.
      lv_out = '-' && lv_out.
    ENDIF.
    IF iv_arabic = abap_true.
      lv_out = arabic_digits( lv_out ).
    ENDIF.
    rv_text = lv_out.
  ENDMETHOD.


  METHOD number_pattern.
    DATA lv_pattern TYPE string.
    DATA lv_arabic TYPE abap_bool.
    DATA lv_value TYPE decfloat34.
    DATA lv_ok TYPE abap_bool.
    DATA lv_decimals TYPE i.
    DATA lv_dec_sep TYPE string.
    DATA lv_grouped TYPE abap_bool.
    DATA lv_dot TYPE i.
    DATA lv_comma TYPE i.
    DATA lv_last TYPE i.
    DATA lv_sep TYPE string.
    DATA lv_after TYPE string.
    DATA lv_dec TYPE string.
    DATA lv_grp TYPE string.
    DATA lv_places TYPE i.

    rv_text = iv_value.
    lv_pattern = condense( iv_pattern ).
    IF strlen( lv_pattern ) > 2 AND substring( val = lv_pattern len = 2 ) = 'AR'.
      lv_arabic = abap_true.
      lv_pattern = substring( val = lv_pattern off = 2 ).
    ENDIF.
    parse_number(
      EXPORTING iv_text = iv_value
      IMPORTING
        ev_value    = lv_value
        ev_ok       = lv_ok
        ev_decimals = lv_decimals
        ev_dec_sep  = lv_dec_sep
        ev_grouped  = lv_grouped ).
    IF lv_ok = abap_false.
      RETURN.
    ENDIF.
    lv_dot = find( val = lv_pattern sub = '.' occ = -1 ).
    lv_comma = find( val = lv_pattern sub = ',' occ = -1 ).
    IF lv_dot >= 0 AND lv_comma >= 0.
      IF lv_dot > lv_comma.
        lv_dec = '.'.
        lv_grp = ','.
        lv_last = lv_dot.
      ELSE.
        lv_dec = ','.
        lv_grp = '.'.
        lv_last = lv_comma.
      ENDIF.
    ELSEIF lv_dot >= 0 OR lv_comma >= 0.
      lv_last = nmax( val1 = lv_dot val2 = lv_comma ).
      lv_sep = substring( val = lv_pattern off = lv_last len = 1 ).
      lv_after = substring( val = lv_pattern off = lv_last + 1 ).
      IF lv_after CO '0'
          AND ( substring( val = lv_pattern len = 1 ) = '0' OR strlen( lv_after ) <> 3 ).
        lv_dec = lv_sep.
      ELSE.
        lv_grp = lv_sep.
        lv_last = -1.
      ENDIF.
    ELSE.
      lv_last = -1.
    ENDIF.
    IF lv_dec IS NOT INITIAL AND lv_last >= 0.
      lv_places = strlen( lv_pattern ) - lv_last - 1.
    ENDIF.
    rv_text = format_number(
      iv_value     = lv_value
      iv_decimals  = lv_places
      iv_dec_sep   = lv_dec
      iv_group_sep = lv_grp
      iv_arabic    = lv_arabic ).
  ENDMETHOD.


  METHOD aggregate.
    DATA lt_words TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    DATA lv_op TYPE string.
    DATA lv_term TYPE string.
    DATA lv_table TYPE string.
    DATA lv_field TYPE string.
    DATA lv_at TYPE i.
    DATA lr_data TYPE REF TO data.
    DATA lr_row TYPE REF TO data.
    DATA lr_value TYPE REF TO data.
    DATA lv_found TYPE abap_bool.
    DATA lt_texts TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    DATA lv_text TYPE string.
    DATA lv_rows TYPE i.
    DATA lv_value TYPE decfloat34.
    DATA lv_ok TYPE abap_bool.
    DATA lv_decimals TYPE i.
    DATA lv_dec_sep TYPE string.
    DATA lv_grouped TYPE abap_bool.
    DATA lv_sum TYPE decfloat34.
    DATA lv_min TYPE decfloat34.
    DATA lv_max TYPE decfloat34.
    DATA lv_result TYPE decfloat34.
    DATA lv_numbers TYPE i.
    DATA lv_places TYPE i.
    DATA lv_dec TYPE string.
    DATA lv_any_group TYPE abap_bool.
    DATA lv_grp TYPE string.
    FIELD-SYMBOLS <node> TYPE any.
    FIELD-SYMBOLS <table> TYPE ANY TABLE.
    FIELD-SYMBOLS <row> TYPE any.

    lv_text = condense( iv_tag ).
    SPLIT lv_text AT ` ` INTO TABLE lt_words.
    DELETE lt_words WHERE table_line IS INITIAL.
    READ TABLE lt_words INTO lv_op INDEX 1.
    lv_op = to_lower( lv_op ).
    DELETE lt_words INDEX 1.
    LOOP AT lt_words INTO lv_term.
      IF lv_term CO '0123456789.,-'.
        IF lv_op = 'count'.
          parse_number(
            EXPORTING iv_text = lv_term
            IMPORTING ev_value = lv_value ev_ok = lv_ok ).
          IF lv_ok = abap_true.
            lv_rows = lv_rows + lv_value.
          ENDIF.
        ELSE.
          APPEND lv_term TO lt_texts.
        ENDIF.
        CONTINUE.
      ENDIF.
      IF lv_op = 'count'.
        lv_table = lv_term.
        CLEAR lv_field.
      ELSE.
        lv_at = find( val = lv_term sub = '.' occ = -1 ).
        IF lv_at > 0.
          lv_table = substring( val = lv_term len = lv_at ).
          lv_field = substring( val = lv_term off = lv_at + 1 ).
        ELSE.
          lv_table = lv_term.
          CLEAR lv_field.
        ENDIF.
      ENDIF.
      try_resolve(
        EXPORTING iv_path = lv_table
        IMPORTING eo_data = lr_data ev_found = lv_found ).
      IF lv_found = abap_false.
        RAISE EXCEPTION TYPE zcx_abappdf
          EXPORTING textid = zcx_abappdf=>field_unknown_op msgv1 = CONV symsgv( lv_op ) msgv2 = CONV symsgv( lv_table ).
      ENDIF.
      ASSIGN lr_data->* TO <node>.
      IF cl_abap_typedescr=>describe_by_data( <node> )->kind = cl_abap_typedescr=>kind_table.
        ASSIGN lr_data->* TO <table>.
        IF lv_op = 'count'.
          lv_rows = lv_rows + lines( <table> ).
          CONTINUE.
        ENDIF.
        LOOP AT <table> ASSIGNING <row>.
          GET REFERENCE OF <row> INTO lr_row.
          IF lv_field IS INITIAL.
            APPEND value_to_string( lr_row ) TO lt_texts.
          ELSEIF walk(
              EXPORTING io_data = lr_row iv_path = lv_field
              IMPORTING eo_data = lr_value ) = abap_true.
            APPEND value_to_string( lr_value ) TO lt_texts.
          ENDIF.
        ENDLOOP.
      ELSE.
        IF lv_op = 'count'.
          lv_rows = lv_rows + 1.
        ELSEIF lv_field IS INITIAL.
          APPEND value_to_string( lr_data ) TO lt_texts.
        ELSEIF walk(
            EXPORTING io_data = lr_data iv_path = lv_field
            IMPORTING eo_data = lr_value ) = abap_true.
          APPEND value_to_string( lr_value ) TO lt_texts.
        ENDIF.
      ENDIF.
    ENDLOOP.
    IF lv_op = 'count'.
      rv_text = |{ lv_rows }|.
      RETURN.
    ENDIF.
    LOOP AT lt_texts INTO lv_text.
      parse_number(
        EXPORTING iv_text = lv_text
        IMPORTING
          ev_value    = lv_value
          ev_ok       = lv_ok
          ev_decimals = lv_decimals
          ev_dec_sep  = lv_dec_sep
          ev_grouped  = lv_grouped ).
      IF lv_ok = abap_false.
        CONTINUE.
      ENDIF.
      IF lv_numbers = 0.
        lv_min = lv_value.
        lv_max = lv_value.
      ELSE.
        lv_min = nmin( val1 = lv_min val2 = lv_value ).
        lv_max = nmax( val1 = lv_max val2 = lv_value ).
      ENDIF.
      lv_sum = lv_sum + lv_value.
      lv_numbers = lv_numbers + 1.
      lv_places = nmax( val1 = lv_places val2 = lv_decimals ).
      IF lv_dec IS INITIAL AND lv_dec_sep IS NOT INITIAL.
        lv_dec = lv_dec_sep.
      ENDIF.
      IF lv_grouped = abap_true.
        lv_any_group = abap_true.
      ENDIF.
    ENDLOOP.
    CASE lv_op.
      WHEN 'sum'.
        lv_result = lv_sum.
      WHEN 'avg'.
        IF lv_numbers = 0.
          RETURN.
        ENDIF.
        lv_result = lv_sum / lv_numbers.
        lv_places = nmax( val1 = lv_places val2 = 2 ).
      WHEN 'min'.
        IF lv_numbers = 0.
          RETURN.
        ENDIF.
        lv_result = lv_min.
      WHEN 'max'.
        IF lv_numbers = 0.
          RETURN.
        ENDIF.
        lv_result = lv_max.
    ENDCASE.
    IF lv_dec IS INITIAL.
      lv_dec = '.'.
    ENDIF.
    IF lv_any_group = abap_true.
      lv_grp = COND #( WHEN lv_dec = ',' THEN '.' ELSE ',' ).
    ENDIF.
    rv_text = format_number(
      iv_value     = lv_result
      iv_decimals  = lv_places
      iv_dec_sep   = lv_dec
      iv_group_sep = lv_grp ).
  ENDMETHOD.


  METHOD decode_b64url.
    DATA lv_b64 TYPE string.
    DATA lv_x TYPE xstring.
    lv_b64 = iv_b64.
    REPLACE ALL OCCURRENCES OF '-' IN lv_b64 WITH '+'.
    REPLACE ALL OCCURRENCES OF '_' IN lv_b64 WITH '/'.
    WHILE strlen( lv_b64 ) MOD 4 <> 0.
      lv_b64 = lv_b64 && '='.
    ENDWHILE.
    TRY.
        lv_x = cl_web_http_utility=>decode_x_base64( lv_b64 ).
        rv_text = cl_abap_conv_codepage=>create_in( codepage = 'UTF-8' )->convert( lv_x ).
      CATCH cx_root.
        CLEAR rv_text.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
