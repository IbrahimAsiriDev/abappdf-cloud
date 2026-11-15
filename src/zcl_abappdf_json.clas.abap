CLASS zcl_abappdf_json DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_pair,
        name TYPE string,
        node TYPE REF TO data,
      END OF ty_pair,
      ty_pairs TYPE STANDARD TABLE OF ty_pair WITH EMPTY KEY,
      ty_items TYPE STANDARD TABLE OF REF TO data WITH EMPTY KEY,
      ty_char1 TYPE c LENGTH 1,
      BEGIN OF ty_node,
        kind  TYPE c LENGTH 1,
        text  TYPE string,
        pairs TYPE ty_pairs,
        items TYPE ty_items,
      END OF ty_node.

    CLASS-METHODS parse
      IMPORTING
        iv_json        TYPE string
      RETURNING
        VALUE(rr_node) TYPE REF TO data
      RAISING
        zcx_abappdf.

    CLASS-METHODS to_abap
      IMPORTING
        iv_json        TYPE string
      RETURNING
        VALUE(rr_data) TYPE REF TO data
      RAISING
        zcx_abappdf.

    CLASS-METHODS escape
      IMPORTING
        iv_text        TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.

    CLASS-METHODS member
      IMPORTING
        ir_node        TYPE REF TO data
        iv_name        TYPE string
      RETURNING
        VALUE(rr_node) TYPE REF TO data.

    CLASS-METHODS text_of
      IMPORTING
        ir_node        TYPE REF TO data
      RETURNING
        VALUE(rv_text) TYPE string.

    CLASS-METHODS kind
      IMPORTING
        ir_node        TYPE REF TO data
      RETURNING
        VALUE(rv_kind) TYPE ty_char1.

    CLASS-METHODS items
      IMPORTING
        ir_node         TYPE REF TO data
      RETURNING
        VALUE(rt_items) TYPE ty_items.

  PRIVATE SECTION.
    DATA mv_json TYPE string.
    DATA mv_pos  TYPE i.
    DATA mv_len  TYPE i.

    METHODS parse_value
      RETURNING
        VALUE(rr_node) TYPE REF TO data
      RAISING
        zcx_abappdf.

    METHODS parse_object
      RETURNING
        VALUE(rr_node) TYPE REF TO data
      RAISING
        zcx_abappdf.

    METHODS parse_array
      RETURNING
        VALUE(rr_node) TYPE REF TO data
      RAISING
        zcx_abappdf.

    METHODS parse_string
      RETURNING
        VALUE(rv_text) TYPE string
      RAISING
        zcx_abappdf.

    METHODS parse_number
      RETURNING
        VALUE(rv_text) TYPE string
      RAISING
        zcx_abappdf.

    METHODS skip_ws.
    METHODS peek
      RETURNING
        VALUE(rv_ch) TYPE string.
    METHODS take
      RETURNING
        VALUE(rv_ch) TYPE string
      RAISING
        zcx_abappdf.
    METHODS expect_word
      IMPORTING
        iv_word TYPE string
      RAISING
        zcx_abappdf.
    METHODS fail
      IMPORTING
        iv_message TYPE string
      RAISING
        zcx_abappdf.

    CLASS-METHODS new_node
      IMPORTING
        iv_kind        TYPE ty_char1
        iv_text        TYPE string OPTIONAL
      RETURNING
        VALUE(rr_node) TYPE REF TO data.

    CLASS-METHODS node
      IMPORTING
        ir_node        TYPE REF TO data
      RETURNING
        VALUE(rs_node) TYPE ty_node.

    CLASS-METHODS as_abap
      IMPORTING
        ir_node        TYPE REF TO data
      RETURNING
        VALUE(rr_data) TYPE REF TO data
      RAISING
        zcx_abappdf.

    CLASS-METHODS type_of
      IMPORTING
        ir_node        TYPE REF TO data
      RETURNING
        VALUE(ro_type) TYPE REF TO cl_abap_datadescr
      RAISING
        zcx_abappdf.

    CLASS-METHODS struct_type
      IMPORTING
        it_pairs       TYPE ty_pairs
      RETURNING
        VALUE(ro_type) TYPE REF TO cl_abap_structdescr
      RAISING
        zcx_abappdf.

    CLASS-METHODS table_type
      IMPORTING
        it_items       TYPE ty_items
      RETURNING
        VALUE(ro_type) TYPE REF TO cl_abap_tabledescr
      RAISING
        zcx_abappdf.

    CLASS-METHODS fill
      IMPORTING
        ir_node TYPE REF TO data
      CHANGING
        c_data  TYPE any
      RAISING
        zcx_abappdf.

    CLASS-METHODS comp_name
      IMPORTING
        iv_name        TYPE string
      RETURNING
        VALUE(rv_name) TYPE string.

    CLASS-METHODS hex_char
      IMPORTING
        iv_hex         TYPE string
      RETURNING
        VALUE(rv_char) TYPE string.
ENDCLASS.



CLASS zcl_abappdf_json IMPLEMENTATION.

  METHOD parse.
    DATA(lo_parser) = NEW zcl_abappdf_json( ).
    lo_parser->mv_json = iv_json.
    lo_parser->mv_len = strlen( iv_json ).
    lo_parser->skip_ws( ).
    IF lo_parser->mv_pos >= lo_parser->mv_len.
      lo_parser->fail( 'JSON is empty' ).
    ENDIF.
    rr_node = lo_parser->parse_value( ).
    lo_parser->skip_ws( ).
    IF lo_parser->mv_pos < lo_parser->mv_len.
      lo_parser->fail( 'JSON has trailing characters' ).
    ENDIF.
  ENDMETHOD.


  METHOD to_abap.
    rr_data = as_abap( parse( iv_json ) ).
  ENDMETHOD.


  METHOD escape.
    DATA lv_cr TYPE c LENGTH 1.
    DATA lv_crlf TYPE string.
    rv_text = iv_text.
    lv_crlf = cl_abap_char_utilities=>cr_lf.
    lv_cr = substring( val = lv_crlf len = 1 ).
    REPLACE ALL OCCURRENCES OF '\' IN rv_text WITH '\\'.
    REPLACE ALL OCCURRENCES OF '"' IN rv_text WITH '\"'.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN rv_text WITH '\n'.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>newline IN rv_text WITH '\n'.
    REPLACE ALL OCCURRENCES OF lv_cr IN rv_text WITH ''.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>horizontal_tab IN rv_text WITH '\t'.
  ENDMETHOD.


  METHOD member.
    DATA ls_pair TYPE ty_pair.
    IF ir_node IS NOT BOUND.
      RETURN.
    ENDIF.
    LOOP AT node( ir_node )-pairs INTO ls_pair.
      IF to_upper( ls_pair-name ) = to_upper( iv_name ).
        rr_node = ls_pair-node.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD text_of.
    IF ir_node IS NOT BOUND.
      RETURN.
    ENDIF.
    rv_text = node( ir_node )-text.
  ENDMETHOD.


  METHOD kind.
    IF ir_node IS BOUND.
      rv_kind = node( ir_node )-kind.
    ENDIF.
  ENDMETHOD.


  METHOD items.
    IF ir_node IS BOUND.
      rt_items = node( ir_node )-items.
    ENDIF.
  ENDMETHOD.


  METHOD parse_value.
    DATA lv_ch TYPE c LENGTH 1.
    skip_ws( ).
    lv_ch = peek( ).
    CASE lv_ch.
      WHEN '{'.
        rr_node = parse_object( ).
      WHEN '['.
        rr_node = parse_array( ).
      WHEN '"'.
        rr_node = new_node( iv_kind = 'S' iv_text = parse_string( ) ).
      WHEN 't'.
        expect_word( 'true' ).
        rr_node = new_node( iv_kind = 'B' iv_text = 'true' ).
      WHEN 'f'.
        expect_word( 'false' ).
        rr_node = new_node( iv_kind = 'B' ).
      WHEN 'n'.
        expect_word( 'null' ).
        rr_node = new_node( iv_kind = 'Z' ).
      WHEN OTHERS.
        rr_node = new_node( iv_kind = 'N' iv_text = parse_number( ) ).
    ENDCASE.
  ENDMETHOD.


  METHOD parse_object.
    DATA ls_pair TYPE ty_pair.
    DATA ls_node TYPE ty_node.
    FIELD-SYMBOLS <node> TYPE ty_node.
    rr_node = new_node( 'O' ).
    expect_word( '{' ).
    skip_ws( ).
    IF peek( ) = '}'.
      take( ).
      RETURN.
    ENDIF.
    WHILE mv_pos < mv_len.
      skip_ws( ).
      IF peek( ) <> '"'.
        fail( 'JSON object key must be a string' ).
      ENDIF.
      ls_pair-name = parse_string( ).
      skip_ws( ).
      IF take( ) <> ':'.
        fail( 'JSON object is missing a colon' ).
      ENDIF.
      ls_pair-node = parse_value( ).
      ls_node = node( rr_node ).
      APPEND ls_pair TO ls_node-pairs.
      CLEAR ls_pair.
      ASSIGN rr_node->* TO <node>.
      <node> = ls_node.
      skip_ws( ).
      CASE take( ).
        WHEN ','.
          CONTINUE.
        WHEN '}'.
          RETURN.
        WHEN OTHERS.
          fail( 'JSON object is not closed' ).
      ENDCASE.
    ENDWHILE.
    fail( 'JSON object is not closed' ).
  ENDMETHOD.


  METHOD parse_array.
    DATA ls_node TYPE ty_node.
    FIELD-SYMBOLS <node> TYPE ty_node.
    rr_node = new_node( 'A' ).
    expect_word( '[' ).
    skip_ws( ).
    IF peek( ) = ']'.
      take( ).
      RETURN.
    ENDIF.
    WHILE mv_pos < mv_len.
      DATA(lr_item) = parse_value( ).
      ls_node = node( rr_node ).
      APPEND lr_item TO ls_node-items.
      ASSIGN rr_node->* TO <node>.
      <node> = ls_node.
      skip_ws( ).
      CASE take( ).
        WHEN ','.
          CONTINUE.
        WHEN ']'.
          RETURN.
        WHEN OTHERS.
          fail( 'JSON array is not closed' ).
      ENDCASE.
    ENDWHILE.
    fail( 'JSON array is not closed' ).
  ENDMETHOD.


  METHOD parse_string.
    DATA lv_ch TYPE string.
    DATA lv_cr TYPE c LENGTH 1.
    DATA lv_crlf TYPE string.
    DATA lv_hex TYPE string.
    lv_crlf = cl_abap_char_utilities=>cr_lf.
    lv_cr = substring( val = lv_crlf len = 1 ).
    IF take( ) <> '"'.
      fail( 'JSON string is missing a quote' ).
    ENDIF.
    WHILE mv_pos < mv_len.
      lv_ch = take( ).
      IF lv_ch = '"'.
        RETURN.
      ENDIF.
      IF lv_ch <> '\'.
        rv_text = |{ rv_text }{ lv_ch }|.
        CONTINUE.
      ENDIF.
      lv_ch = take( ).
      CASE lv_ch.
        WHEN '"' OR '\' OR '/'.
          rv_text = |{ rv_text }{ lv_ch }|.
        WHEN 'b'.
          rv_text = rv_text && cl_abap_char_utilities=>horizontal_tab.
        WHEN 'f'.
          rv_text = rv_text && cl_abap_char_utilities=>form_feed.
        WHEN 'n'.
          rv_text = rv_text && cl_abap_char_utilities=>newline.
        WHEN 'r'.
          rv_text = rv_text && lv_cr.
        WHEN 't'.
          rv_text = rv_text && cl_abap_char_utilities=>horizontal_tab.
        WHEN 'u'.
          IF mv_pos + 4 > mv_len.
            fail( 'JSON unicode escape is too short' ).
          ENDIF.
          lv_hex = to_upper( substring( val = mv_json off = mv_pos len = 4 ) ).
          IF lv_hex CN '0123456789ABCDEF'.
            fail( 'JSON unicode escape is not hexadecimal' ).
          ENDIF.
          mv_pos = mv_pos + 4.
          rv_text = rv_text && hex_char( lv_hex ).
        WHEN OTHERS.
          fail( 'JSON string has an unknown escape' ).
      ENDCASE.
    ENDWHILE.
    fail( 'JSON string is not closed' ).
  ENDMETHOD.


  METHOD parse_number.
    DATA lv_ch TYPE c LENGTH 1.
    skip_ws( ).
    WHILE mv_pos < mv_len.
      lv_ch = peek( ).
      IF lv_ch CA '0123456789+-eE.'.
        rv_text = rv_text && take( ).
      ELSE.
        EXIT.
      ENDIF.
    ENDWHILE.
    IF rv_text IS INITIAL OR rv_text NA '0123456789'.
      fail( 'JSON number is invalid' ).
    ENDIF.
  ENDMETHOD.


  METHOD skip_ws.
    DATA lv_ch TYPE c LENGTH 1.
    DATA lv_cr TYPE c LENGTH 1.
    DATA lv_crlf TYPE string.
    lv_crlf = cl_abap_char_utilities=>cr_lf.
    lv_cr = substring( val = lv_crlf len = 1 ).
    WHILE mv_pos < mv_len.
      lv_ch = substring( val = mv_json off = mv_pos len = 1 ).
      IF lv_ch <> ' ' AND lv_ch <> cl_abap_char_utilities=>horizontal_tab
          AND lv_ch <> cl_abap_char_utilities=>newline
          AND lv_ch <> lv_cr.
        RETURN.
      ENDIF.
      mv_pos = mv_pos + 1.
    ENDWHILE.
  ENDMETHOD.


  METHOD peek.
    IF mv_pos < mv_len.
      rv_ch = substring( val = mv_json off = mv_pos len = 1 ).
    ENDIF.
  ENDMETHOD.


  METHOD take.
    IF mv_pos >= mv_len.
      fail( 'Unexpected end of JSON' ).
    ENDIF.
    rv_ch = substring( val = mv_json off = mv_pos len = 1 ).
    mv_pos = mv_pos + 1.
  ENDMETHOD.


  METHOD expect_word.
    DATA lv_i TYPE i.
    DATA lv_ch TYPE c LENGTH 1.
    DO strlen( iv_word ) TIMES.
      lv_i = sy-index - 1.
      lv_ch = substring( val = iv_word off = lv_i len = 1 ).
      IF take( ) <> lv_ch.
        fail( 'JSON value is invalid' ).
      ENDIF.
    ENDDO.
  ENDMETHOD.


  METHOD fail.
    RAISE EXCEPTION TYPE zcx_abappdf
      EXPORTING
        textid = zcx_abappdf=>json_invalid
        msgv1  = CONV symsgv( iv_message ).
  ENDMETHOD.


  METHOD new_node.
    DATA ls_node TYPE ty_node.
    ls_node-kind = iv_kind.
    ls_node-text = iv_text.
    CREATE DATA rr_node TYPE ty_node.
    ASSIGN rr_node->* TO FIELD-SYMBOL(<node>).
    <node> = ls_node.
  ENDMETHOD.


  METHOD node.
    ASSIGN ir_node->* TO FIELD-SYMBOL(<node>).
    rs_node = <node>.
  ENDMETHOD.


  METHOD as_abap.
    DATA(lo_type) = type_of( ir_node ).
    CREATE DATA rr_data TYPE HANDLE lo_type.
    ASSIGN rr_data->* TO FIELD-SYMBOL(<data>).
    fill( EXPORTING ir_node = ir_node CHANGING c_data = <data> ).
  ENDMETHOD.


  METHOD type_of.
    CASE node( ir_node )-kind.
      WHEN 'O'.
        ro_type = struct_type( node( ir_node )-pairs ).
      WHEN 'A'.
        ro_type = table_type( node( ir_node )-items ).
      WHEN OTHERS.
        ro_type = cl_abap_elemdescr=>get_string( ).
    ENDCASE.
  ENDMETHOD.


  METHOD struct_type.
    DATA lt_comp TYPE cl_abap_structdescr=>component_table.
    DATA ls_comp LIKE LINE OF lt_comp.
    DATA ls_pair TYPE ty_pair.
    LOOP AT it_pairs INTO ls_pair.
      ls_comp-name = comp_name( ls_pair-name ).
      IF ls_comp-name IS INITIAL.
        CONTINUE.
      ENDIF.
      READ TABLE lt_comp TRANSPORTING NO FIELDS WITH KEY name = ls_comp-name.
      IF sy-subrc = 0.
        CONTINUE.
      ENDIF.
      ls_comp-type = type_of( ls_pair-node ).
      APPEND ls_comp TO lt_comp.
    ENDLOOP.
    IF lt_comp IS INITIAL.
      CLEAR ls_comp.
      ls_comp-name = 'EMPTY'.
      ls_comp-type = cl_abap_elemdescr=>get_string( ).
      APPEND ls_comp TO lt_comp.
    ENDIF.
    ro_type = cl_abap_structdescr=>create( lt_comp ).
  ENDMETHOD.


  METHOD table_type.
    DATA lr_item TYPE REF TO data.
    DATA ls_node TYPE ty_node.
    DATA ls_pair TYPE ty_pair.
    DATA lt_pairs TYPE ty_pairs.
    DATA lo_line TYPE REF TO cl_abap_datadescr.
    IF it_items IS INITIAL.
      lo_line = cl_abap_elemdescr=>get_string( ).
    ELSE.
      READ TABLE it_items INDEX 1 INTO lr_item.
      ls_node = node( lr_item ).
      IF ls_node-kind = 'O'.
        LOOP AT it_items INTO lr_item.
          ls_node = node( lr_item ).
          IF ls_node-kind <> 'O'.
            CONTINUE.
          ENDIF.
          LOOP AT ls_node-pairs INTO ls_pair.
            READ TABLE lt_pairs TRANSPORTING NO FIELDS WITH KEY name = ls_pair-name.
            IF sy-subrc <> 0.
              APPEND ls_pair TO lt_pairs.
            ENDIF.
          ENDLOOP.
        ENDLOOP.
        lo_line = struct_type( lt_pairs ).
      ELSE.
        lo_line = type_of( lr_item ).
      ENDIF.
    ENDIF.
    ro_type = cl_abap_tabledescr=>create( p_line_type = lo_line ).
  ENDMETHOD.


  METHOD fill.
    DATA ls_node TYPE ty_node.
    DATA ls_pair TYPE ty_pair.
    DATA lr_item TYPE REF TO data.
    FIELD-SYMBOLS <table> TYPE ANY TABLE.
    FIELD-SYMBOLS <row> TYPE any.
    FIELD-SYMBOLS <comp> TYPE any.
    IF ir_node IS NOT BOUND.
      RETURN.
    ENDIF.
    ls_node = node( ir_node ).
    CASE ls_node-kind.
      WHEN 'O'.
        LOOP AT ls_node-pairs INTO ls_pair.
          ASSIGN COMPONENT comp_name( ls_pair-name ) OF STRUCTURE c_data TO <comp>.
          IF sy-subrc = 0.
            fill( EXPORTING ir_node = ls_pair-node CHANGING c_data = <comp> ).
          ENDIF.
        ENDLOOP.
      WHEN 'A'.
        ASSIGN c_data TO <table>.
        IF sy-subrc <> 0.
          RETURN.
        ENDIF.
        LOOP AT ls_node-items INTO lr_item.
          INSERT INITIAL LINE INTO TABLE <table> ASSIGNING <row>.
          fill( EXPORTING ir_node = lr_item CHANGING c_data = <row> ).
        ENDLOOP.
      WHEN 'B' OR 'Z'.
        c_data = ls_node-text.
      WHEN OTHERS.
        c_data = ls_node-text.
    ENDCASE.
  ENDMETHOD.


  METHOD comp_name.
    DATA lv_raw TYPE string.
    DATA lv_ch TYPE c LENGTH 1.
    DATA lv_i TYPE i.
    lv_raw = to_upper( iv_name ).
    DO strlen( lv_raw ) TIMES.
      lv_i = sy-index - 1.
      lv_ch = substring( val = lv_raw off = lv_i len = 1 ).
      IF lv_ch CA 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_'.
        rv_name = rv_name && lv_ch.
      ELSE.
        rv_name = rv_name && '_'.
      ENDIF.
    ENDDO.
    IF rv_name IS INITIAL.
      RETURN.
    ENDIF.
    IF substring( val = rv_name len = 1 ) CA '0123456789'.
      rv_name = 'F' && rv_name.
    ENDIF.
    IF strlen( rv_name ) > 30.
      rv_name = substring( val = rv_name len = 30 ).
    ENDIF.
  ENDMETHOD.


  METHOD hex_char.
    DATA lv_n TYPE i.
    DATA lv_d TYPE i.
    DATA lv_ch TYPE c LENGTH 1.
    DATA lv_digits TYPE string VALUE '0123456789ABCDEF'.
    DATA lv_x TYPE xstring.
    DATA lv_b0 TYPE x LENGTH 1.
    DATA lv_b1 TYPE x LENGTH 1.
    DATA lv_b2 TYPE x LENGTH 1.
    DO strlen( iv_hex ) TIMES.
      lv_ch = substring( val = to_upper( iv_hex ) off = sy-index - 1 len = 1 ).
      lv_d = find( val = lv_digits sub = lv_ch ).
      IF lv_d < 0.
        RETURN.
      ENDIF.
      lv_n = lv_n * 16 + lv_d.
    ENDDO.
    IF lv_n < 128.
      lv_b0 = lv_n.
      lv_x = lv_b0.
    ELSEIF lv_n < 2048.
      lv_b0 = 192 + lv_n DIV 64.
      lv_b1 = 128 + lv_n MOD 64.
      lv_x = lv_b0 && lv_b1.
    ELSE.
      lv_b0 = 224 + lv_n DIV 4096.
      lv_b1 = 128 + lv_n DIV 64 MOD 64.
      lv_b2 = 128 + lv_n MOD 64.
      lv_x = lv_b0 && lv_b1 && lv_b2.
    ENDIF.
    TRY.
        rv_char = cl_abap_conv_codepage=>create_in( codepage = 'UTF-8' )->convert( lv_x ).
      CATCH cx_root.
        rv_char = '?'.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
