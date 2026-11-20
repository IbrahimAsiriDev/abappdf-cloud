CLASS ltcl_engine DEFINITION FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS pixels_to_points FOR TESTING.
    METHODS positioned_text FOR TESTING RAISING zcx_abappdf.
    METHODS arabic_text FOR TESTING RAISING zcx_abappdf.
    METHODS qr_follows_grown_table FOR TESTING RAISING zcx_abappdf.
    METHODS qr_on_rows_moves_below FOR TESTING RAISING zcx_abappdf.
    METHODS widget_past_page_moves_next FOR TESTING RAISING zcx_abappdf.
    METHODS long_text_wraps FOR TESTING RAISING zcx_abappdf.
    METHODS table_cell_style FOR TESTING RAISING zcx_abappdf.
    METHODS margins_move_content FOR TESTING RAISING zcx_abappdf.
    METHODS empty_box_draws_fill FOR TESTING RAISING zcx_abappdf.
    METHODS tm_y
      IMPORTING
        iv_text        TYPE string
        iv_word        TYPE string
      RETURNING
        VALUE(rv_y)    TYPE decfloat34.
ENDCLASS.

CLASS ltcl_engine IMPLEMENTATION.

  METHOD pixels_to_points.
    DATA lv_pt TYPE decfloat34.
    lv_pt = zcl_abappdf_renderer=>px_to_pt( 96 ).
    cl_abap_unit_assert=>assert_equals(
      act = CONV i( lv_pt )
      exp = 72 ).
  ENDMETHOD.

  METHOD positioned_text.
    DATA(lv_pdf) = zcl_abappdf_renderer=>render(
      iv_html = '<div style="position:absolute;left:96px;top:10px;width:200px;height:24px;">Hello</div>' ).
    DATA(lv_text) = cl_abap_conv_codepage=>create_in( )->convert( lv_pdf ).
    cl_abap_unit_assert=>assert_equals(
      act = substring( val = lv_text len = 4 )
      exp = '%PDF' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_text CS '%PDF' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_text CS 'Hello' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_text CS '72.00' ) ).
  ENDMETHOD.

  METHOD long_text_wraps.
    " 150px is about 112pt: at 12pt "Hello wide world" needs two lines.
    DATA(lv_pdf) = zcl_abappdf_renderer=>render(
      iv_html = '<div style="position:absolute;left:10px;top:10px;width:150px;height:60px;font-size:12pt;">Hello wide world again</div>' ).
    DATA(lv_text) = cl_abap_conv_codepage=>create_in( )->convert( lv_pdf ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_text CS '(Hello wide world) Tj' OR lv_text CS '(Hello wide) Tj' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_text CS '(Hello wide world again) Tj' ) ).
  ENDMETHOD.

  METHOD table_cell_style.
    " Cell width, shade, border colour and bold come from the td style.
    DATA(lv_pdf) = zcl_abappdf_renderer=>render(
      iv_html = '<table style="position:absolute;left:0px;top:0px;width:300px;font-size:10pt;"><tr>' &&
                '<td style="height:20px;width:100px;border:1px solid #ff0000;background:#00ff00;font-weight:bold;">A</td>' &&
                '<td style="height:20px;width:200px;">B</td></tr></table>' ).
    DATA(lv_text) = cl_abap_conv_codepage=>create_in( )->convert( lv_pdf ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_text CS '0.00 1.00 0.00 rg' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_text CS '1.00 0.00 0.00 RG' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_text CS 'Helvetica-Bold' ) ).
    " Second cell starts at 100px = 75pt, not at the half of 300px.
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_text CS '75.00' ) ).
  ENDMETHOD.

  METHOD arabic_text.
    DATA lv_pdf TYPE xstring.
    DATA lv_text TYPE string.
    DATA(lv_hex) = zcl_abappdf_font=>glyphs( 'لا' ).
    cl_abap_unit_assert=>assert_equals( act = strlen( lv_hex ) exp = 4 ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_hex = '0000' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( zcl_abappdf_font=>advance( iv_text = 'لا' iv_size = 12 ) > 0 ) ).
    lv_pdf = zcl_abappdf_renderer=>render(
      iv_html = '<div style="position:absolute;left:36px;top:40px;width:400px;height:30px;text-align:center;">العملة</div>' ).
    lv_text = cl_abap_conv_codepage=>create_in( )->convert( lv_pdf ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_text CS 'NotoNaskhArabic-Regular' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_text CS '/Identity-H' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_text CS '????' ) ).
  ENDMETHOD.

  METHOD qr_follows_grown_table.
    DATA lv_html TYPE string.
    DATA lv_pdf TYPE xstring.
    DATA lv_text TYPE string.
    DATA lv_side TYPE decfloat34.
    DATA lv_last TYPE decfloat34.
    DATA lv_qr TYPE decfloat34.
    lv_html = '<div style="position:absolute;left:300px;top:110px;width:40px;height:20px;">SIDE</div>'
      && '<table data-design-h="48" style="position:absolute;left:10px;top:100px;width:200px;height:48px;">'
      && '<tr><td style="height:24px;">HEAD</td></tr>'
      && '<tr><td style="height:24px;">R1</td></tr>'
      && '<tr><td style="height:24px;">R2</td></tr>'
      && '<tr><td style="height:24px;">R3</td></tr>'
      && '<tr><td style="height:24px;">R4</td></tr>'
      && '</table>'
      && '<div style="position:absolute;left:10px;top:148px;width:80px;height:40px;">QRDOWN</div>'.
    lv_pdf = zcl_abappdf_renderer=>render( iv_html = lv_html ).
    lv_text = cl_abap_conv_codepage=>create_in( )->convert( lv_pdf ).
    lv_side = tm_y( iv_text = lv_text iv_word = 'SIDE' ).
    lv_last = tm_y( iv_text = lv_text iv_word = 'R4' ).
    lv_qr = tm_y( iv_text = lv_text iv_word = 'QRDOWN' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_side > 0 ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_last > 0 ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_qr > 0 ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_side - lv_last > 30 ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_last > lv_qr ) ).
  ENDMETHOD.

  METHOD qr_on_rows_moves_below.
    DATA lv_html TYPE string.
    DATA lv_pdf TYPE xstring.
    DATA lv_text TYPE string.
    DATA lv_side TYPE decfloat34.
    DATA lv_last TYPE decfloat34.
    DATA lv_qr TYPE decfloat34.
    lv_html = '<div style="position:absolute;left:300px;top:160px;width:40px;height:20px;">SIDE</div>'
      && '<table data-design-h="120" style="position:absolute;left:10px;top:100px;width:200px;height:120px;">'
      && '<tr><td style="height:24px;">HEAD</td></tr>'
      && '<tr><td style="height:24px;">R1</td></tr>'
      && '<tr><td style="height:24px;">R2</td></tr>'
      && '<tr><td style="height:24px;">R3</td></tr>'
      && '<tr><td style="height:24px;">R4</td></tr>'
      && '</table>'
      && '<div style="position:absolute;left:40px;top:160px;width:70px;height:48px;">QRDOWN</div>'.
    lv_pdf = zcl_abappdf_renderer=>render( iv_html = lv_html ).
    lv_text = cl_abap_conv_codepage=>create_in( )->convert( lv_pdf ).
    lv_side = tm_y( iv_text = lv_text iv_word = 'SIDE' ).
    lv_last = tm_y( iv_text = lv_text iv_word = 'R4' ).
    lv_qr = tm_y( iv_text = lv_text iv_word = 'QRDOWN' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_side > 0 ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_last > 0 ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_qr > 0 ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_side - lv_last > 20 ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_last > lv_qr ) ).
  ENDMETHOD.

  METHOD widget_past_page_moves_next.
    DATA lv_pdf TYPE xstring.
    DATA lv_text TYPE string.
    DATA lv_pages TYPE i.
    DATA lv_at TYPE i.
    lv_pdf = zcl_abappdf_renderer=>render(
      iv_html = '<div style="position:absolute;left:36px;top:1080px;width:80px;height:80px;">NXTPAGE</div>' ).
    lv_text = cl_abap_conv_codepage=>create_in( )->convert( lv_pdf ).
    lv_at = 0.
    WHILE lv_at >= 0.
      lv_at = find( val = lv_text sub = `/Type /Page ` off = lv_at ).
      IF lv_at < 0.
        EXIT.
      ENDIF.
      lv_pages = lv_pages + 1.
      lv_at = lv_at + 12.
    ENDWHILE.
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_text CS 'NXTPAGE' ) ).
    cl_abap_unit_assert=>assert_equals( act = lv_pages exp = 2 ).
  ENDMETHOD.

  METHOD tm_y.
    DATA lv_at TYPE i.
    DATA lv_tm TYPE i.
    DATA lv_from TYPE i.
    DATA lv_end TYPE i.
    DATA lv_head TYPE string.
    DATA lv_y TYPE string.
    DATA lv_ch TYPE c LENGTH 1.
    DATA lv_scan TYPE i.
    DATA lv_hit TYPE i.
    lv_at = find( val = iv_text sub = |({ iv_word }) Tj| ).
    IF lv_at < 0.
      RETURN.
    ENDIF.
    lv_head = substring( val = iv_text off = 0 len = lv_at ).
    lv_hit = -1.
    WHILE lv_scan < strlen( lv_head ).
      lv_tm = find( val = lv_head sub = ' Tm' off = lv_scan ).
      IF lv_tm < 0.
        EXIT.
      ENDIF.
      lv_hit = lv_tm.
      lv_scan = lv_tm + 3.
    ENDWHILE.
    lv_tm = lv_hit.
    IF lv_tm < 1.
      RETURN.
    ENDIF.
    lv_from = lv_tm - 1.
    WHILE lv_from >= 0.
      lv_ch = substring( val = lv_head off = lv_from len = 1 ).
      IF lv_ch <> ` `.
        EXIT.
      ENDIF.
      lv_from = lv_from - 1.
    ENDWHILE.
    lv_end = lv_from + 1.
    WHILE lv_from >= 0.
      lv_ch = substring( val = lv_head off = lv_from len = 1 ).
      IF lv_ch NA '0123456789.-'.
        EXIT.
      ENDIF.
      lv_from = lv_from - 1.
    ENDWHILE.
    lv_y = substring( val = lv_head off = lv_from + 1 len = lv_end - lv_from - 1 ).
    rv_y = lv_y.
  ENDMETHOD.

  METHOD margins_move_content.
    " Designer positions start at the printable area: left:0 with a 10 mm margin prints at 28.35 pt.
    DATA ls_page TYPE zcl_abappdf_renderer=>ty_page.
    ls_page-page_size = 'A4'.
    ls_page-orientation = 'P'.
    ls_page-margin_top = 10.
    ls_page-margin_right = 10.
    ls_page-margin_bottom = 10.
    ls_page-margin_left = 10.
    DATA(lv_pdf) = zcl_abappdf_renderer=>render(
      iv_html = '<div style="position:absolute;left:0px;top:0px;width:200px;height:24px;">Hello</div>'
      is_page = ls_page ).
    DATA(lv_text) = cl_abap_conv_codepage=>create_in( )->convert( lv_pdf ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_text CS |q\n28.35 | ) ).
  ENDMETHOD.

  METHOD empty_box_draws_fill.
    " A rectangle from the designer has no text but prints its fill and border.
    DATA(lv_pdf) = zcl_abappdf_renderer=>render(
      iv_html = '<div style="position:absolute;left:0px;top:0px;width:100px;height:40px;background:#0000ff;border:1px solid #ff0000;"></div>' ).
    DATA(lv_text) = cl_abap_conv_codepage=>create_in( )->convert( lv_pdf ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_text CS '0.00 0.00 1.00 rg' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_text CS '1.00 0.00 0.00 RG' ) ).
  ENDMETHOD.

ENDCLASS.
