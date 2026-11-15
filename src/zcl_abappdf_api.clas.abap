CLASS zcl_abappdf_api DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS render_pdf
      IMPORTING
        iv_form_id    TYPE string
        is_data       TYPE any
      RETURNING
        VALUE(rv_pdf) TYPE xstring
      RAISING
        zcx_abappdf.

    CLASS-METHODS render_parts
      IMPORTING
        iv_html       TYPE string
        iv_css        TYPE string OPTIONAL
        iv_header     TYPE string OPTIONAL
        iv_footer     TYPE string OPTIONAL
        is_page       TYPE zcl_abappdf_renderer=>ty_page OPTIONAL
        is_data       TYPE any
      RETURNING
        VALUE(rv_pdf) TYPE xstring
      RAISING
        zcx_abappdf.

  PRIVATE SECTION.
    CLASS-METHODS drawable
      IMPORTING
        iv_html        TYPE string
      RETURNING
        VALUE(rv_html) TYPE string.

    CLASS-METHODS from_model
      IMPORTING
        iv_html        TYPE string
      RETURNING
        VALUE(rv_html) TYPE string.

    CLASS-METHODS decode_b64url
      IMPORTING
        iv_b64         TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.

    CLASS-METHODS widget_html
      IMPORTING
        ir_widget      TYPE REF TO data
      RETURNING
        VALUE(rv_html) TYPE string.

    CLASS-METHODS table_html
      IMPORTING
        ir_widget      TYPE REF TO data
      RETURNING
        VALUE(rv_html) TYPE string.

    CLASS-METHODS rows_html
      IMPORTING
        ir_rows        TYPE REF TO data
        ir_table       TYPE REF TO data OPTIONAL
      RETURNING
        VALUE(rv_html) TYPE string.

    CLASS-METHODS json_text
      IMPORTING
        ir_node        TYPE REF TO data
        iv_name        TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.
ENDCLASS.



CLASS zcl_abappdf_api IMPLEMENTATION.

  METHOD render_pdf.
    DATA(ls_template) = zcl_abappdf_forms=>read_active( iv_form_id ).
    DATA(ls_page) = CORRESPONDING zcl_abappdf_renderer=>ty_page( ls_template ).

    rv_pdf = render_parts(
      iv_html   = ls_template-html
      iv_css    = ls_template-css
      iv_header = ls_template-header
      iv_footer = ls_template-footer
      is_page   = ls_page
      is_data   = is_data ).
  ENDMETHOD.


  METHOD render_parts.
    "Designer HTML (draft render from the browser) still carries the layout model
    "and flow tables; drawable turns it into absolutely positioned HTML for the engine.
    "Already drawable HTML passes through unchanged.
    DATA(lv_html) = zcl_abappdf_binder=>render(
      iv_template = drawable( iv_html )
      is_data     = is_data ).
    DATA(lv_header) = zcl_abappdf_binder=>render(
      iv_template = drawable( iv_header )
      is_data     = is_data ).
    DATA(lv_footer) = zcl_abappdf_binder=>render(
      iv_template = drawable( iv_footer )
      is_data     = is_data ).

    IF zcl_abappdf_forms=>use_gotenberg( ) = abap_true.
      rv_pdf = zcl_abappdf_gotenberg=>render(
        iv_html   = zcl_abappdf_codes=>expand_html( lv_html )
        iv_css    = zcl_abappdf_binder=>render( iv_template = iv_css is_data = is_data )
        iv_header = zcl_abappdf_codes=>expand_html( lv_header )
        iv_footer = zcl_abappdf_codes=>expand_html( lv_footer )
        is_page   = is_page ).
      RETURN.
    ENDIF.

    rv_pdf = zcl_abappdf_renderer=>render(
      iv_html   = lv_html
      iv_header = lv_header
      iv_footer = lv_footer
      is_page   = is_page ).
  ENDMETHOD.


  METHOD drawable.
    rv_html = from_model( iv_html ).
    IF rv_html IS NOT INITIAL.
      RETURN.
    ENDIF.
    rv_html = iv_html.
    REPLACE ALL OCCURRENCES OF 'margin-left:' IN rv_html WITH 'position:absolute;left:' IGNORING CASE.
    REPLACE ALL OCCURRENCES OF 'margin-top:' IN rv_html WITH 'top:' IGNORING CASE.
  ENDMETHOD.


  METHOD from_model.
    DATA lv_at TYPE i.
    DATA lv_end TYPE i.
    DATA lv_b64 TYPE string.
    DATA lv_json TYPE string.
    DATA lr_root TYPE REF TO data.
    DATA lr_widget TYPE REF TO data.

    lv_at = find( val = iv_html sub = zcl_abappdf_config=>model_mark ).
    IF lv_at < 0.
      RETURN.
    ENDIF.
    lv_end = find( val = iv_html sub = '-->' off = lv_at ).
    IF lv_end <= lv_at.
      RETURN.
    ENDIF.
    lv_b64 = substring(
      val = iv_html
      off = lv_at + strlen( zcl_abappdf_config=>model_mark )
      len = lv_end - lv_at - strlen( zcl_abappdf_config=>model_mark ) ).
    lv_json = decode_b64url( lv_b64 ).
    IF lv_json IS INITIAL.
      RETURN.
    ENDIF.
    TRY.
        lr_root = zcl_abappdf_json=>parse( lv_json ).
      CATCH zcx_abappdf.
        RETURN.
    ENDTRY.
    LOOP AT zcl_abappdf_json=>items(
        zcl_abappdf_json=>member( ir_node = lr_root iv_name = 'widgets' ) ) INTO lr_widget.
      rv_html = rv_html && widget_html( lr_widget ).
    ENDLOOP.
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


  METHOD widget_html.
    DATA lv_style TYPE string.
    DATA(lv_kind) = to_lower( json_text( ir_node = ir_widget iv_name = 'kind' ) ).
    IF lv_kind = 'table'.
      rv_html = table_html( ir_widget ).
      RETURN.
    ENDIF.
    DATA(lv_text) = json_text( ir_node = ir_widget iv_name = 'text' ).
    IF lv_text IS INITIAL.
      RETURN.
    ENDIF.
    DATA(lv_x) = json_text( ir_node = ir_widget iv_name = 'x' ).
    DATA(lv_y) = json_text( ir_node = ir_widget iv_name = 'y' ).
    DATA(lv_w) = json_text( ir_node = ir_widget iv_name = 'w' ).
    DATA(lv_h) = json_text( ir_node = ir_widget iv_name = 'h' ).
    DATA(lv_size) = json_text( ir_node = ir_widget iv_name = 'size' ).
    DATA(lv_color) = json_text( ir_node = ir_widget iv_name = 'color' ).
    DATA(lv_align) = json_text( ir_node = ir_widget iv_name = 'align' ).
    DATA(lv_bold) = json_text( ir_node = ir_widget iv_name = 'bold' ).
    IF lv_x IS INITIAL.
      lv_x = zcl_abappdf_config=>widget_x_px.
    ENDIF.
    IF lv_y IS INITIAL.
      lv_y = zcl_abappdf_config=>widget_y_px.
    ENDIF.
    IF lv_w IS INITIAL.
      lv_w = zcl_abappdf_config=>widget_width_px.
    ENDIF.
    IF lv_h IS INITIAL.
      lv_h = zcl_abappdf_config=>widget_height_px.
    ENDIF.
    IF lv_size IS INITIAL.
      lv_size = zcl_abappdf_config=>widget_font_pt.
    ENDIF.
    IF lv_color IS INITIAL.
      lv_color = zcl_abappdf_config=>widget_color.
    ENDIF.
    lv_style = 'position:absolute;left:' && lv_x && 'px;top:' && lv_y && 'px;width:' && lv_w
      && 'px;height:' && lv_h && 'px;font-size:' && lv_size && 'pt;color:' && lv_color && ';'.
    IF lv_align IS NOT INITIAL.
      lv_style = lv_style && 'text-align:' && lv_align && ';'.
    ENDIF.
    IF lv_bold = '1' OR lv_bold = 'true'.
      lv_style = lv_style && 'font-weight:bold;'.
    ENDIF.
    DATA(lv_fmt) = json_text( ir_node = ir_widget iv_name = 'dateFmt' ).
    IF lv_fmt IS INITIAL.
      lv_fmt = json_text( ir_node = ir_widget iv_name = 'numFmt' ).
    ENDIF.
    DATA(lv_body) = lv_text.
    IF lv_fmt IS NOT INITIAL.
      lv_body = |<span data-fmt="{ lv_fmt }">{ lv_text }</span>|.
    ENDIF.
    DATA(lv_attrs) = ``.
    DATA(lv_ecc) = to_upper( json_text( ir_node = ir_widget iv_name = 'ecc' ) ).
    DATA(lv_hr) = json_text( ir_node = ir_widget iv_name = 'hr' ).
    IF lv_kind = 'qrcode'.
      IF strlen( lv_ecc ) <> 1 OR lv_ecc NA 'LMQH'.
        lv_ecc = zcl_abappdf_config=>qr_ecc_default.
      ENDIF.
      lv_attrs = | data-code="qr" data-ecc="{ lv_ecc }"|.
    ELSEIF lv_kind = 'barcode'.
      IF lv_hr IS INITIAL.
        lv_hr = zcl_abappdf_config=>barcode_text_default.
      ENDIF.
      lv_attrs = | data-code="code128" data-hr="{ lv_hr }"|.
    ENDIF.
    rv_html = |<div{ lv_attrs } style="{ lv_style }">{ lv_body }</div>|.
  ENDMETHOD.


  METHOD table_html.
    DATA lr_section TYPE REF TO data.
    DATA(lv_x) = json_text( ir_node = ir_widget iv_name = 'x' ).
    DATA(lv_y) = json_text( ir_node = ir_widget iv_name = 'y' ).
    DATA(lv_w) = json_text( ir_node = ir_widget iv_name = 'w' ).
    DATA(lv_h) = json_text( ir_node = ir_widget iv_name = 'h' ).
    DATA(lv_size) = json_text( ir_node = ir_widget iv_name = 'size' ).
    IF lv_x IS INITIAL.
      lv_x = zcl_abappdf_config=>widget_x_px.
    ENDIF.
    IF lv_y IS INITIAL.
      lv_y = zcl_abappdf_config=>widget_y_px.
    ENDIF.
    IF lv_w IS INITIAL.
      lv_w = zcl_abappdf_config=>table_width_px.
    ENDIF.
    IF lv_h IS INITIAL.
      lv_h = zcl_abappdf_config=>table_height_px.
    ENDIF.
    IF lv_size IS INITIAL.
      lv_size = zcl_abappdf_config=>table_font_pt.
    ENDIF.
    rv_html = '<table data-design-h="' && lv_h && '" style="position:absolute;left:' && lv_x && 'px;top:' && lv_y
      && 'px;width:' && lv_w && 'px;height:' && lv_h && 'px;border-collapse:collapse;font-size:' && lv_size && 'pt;">'.
    LOOP AT zcl_abappdf_json=>items(
        zcl_abappdf_json=>member( ir_node = ir_widget iv_name = 'sections' ) ) INTO lr_section.
      rv_html = rv_html && rows_html(
        ir_rows  = zcl_abappdf_json=>member( ir_node = lr_section iv_name = 'headerRows' )
        ir_table = ir_widget ).
      rv_html = rv_html && rows_html(
        ir_rows  = zcl_abappdf_json=>member( ir_node = lr_section iv_name = 'bodyRows' )
        ir_table = ir_widget ).
      rv_html = rv_html && rows_html(
        ir_rows  = zcl_abappdf_json=>member( ir_node = lr_section iv_name = 'footerRows' )
        ir_table = ir_widget ).
    ENDLOOP.
    rv_html = rv_html && '</table>'.
  ENDMETHOD.


  METHOD rows_html.
    "Each cell carries its own width, colours and border, so the engine draws
    "the table as designed (column widths, header shade, alternate rows).
    DATA lr_row TYPE REF TO data.
    DATA lr_cell TYPE REF TO data.
    DATA lt_widths TYPE string_table.
    DATA lv_cells TYPE string.
    DATA lv_mode TYPE string.
    DATA lv_path TYPE string.
    DATA lv_height TYPE string.
    DATA lv_text TYPE string.
    DATA lv_style TYPE string.
    DATA lv_span TYPE string.
    DATA lv_color TYPE string.
    DATA lv_align TYPE string.
    DATA lv_bold TYPE string.
    DATA lv_fmt TYPE string.
    DATA lv_shade TYPE string.
    DATA lv_fill TYPE string.
    DATA lv_alt TYPE string.
    DATA lv_size TYPE string.
    DATA lv_border_w TYPE string.
    DATA lv_border_c TYPE string.
    DATA lv_table_bw TYPE string.
    DATA lv_table_bc TYPE string.
    DATA lv_col TYPE i.
    DATA lv_width TYPE decfloat34.
    DATA lv_item TYPE string.

    IF ir_table IS BOUND.
      LOOP AT zcl_abappdf_json=>items(
          zcl_abappdf_json=>member( ir_node = ir_table iv_name = 'colWidths' ) ) INTO DATA(lr_width).
        APPEND zcl_abappdf_json=>text_of( lr_width ) TO lt_widths.
      ENDLOOP.
      lv_alt = json_text( ir_node = ir_table iv_name = 'altShade' ).
      lv_table_bw = json_text( ir_node = ir_table iv_name = 'borderW' ).
      lv_table_bc = json_text( ir_node = ir_table iv_name = 'borderColor' ).
    ENDIF.
    IF lv_table_bw IS INITIAL.
      lv_table_bw = '1'.
    ENDIF.
    IF lv_table_bc IS INITIAL.
      lv_table_bc = '#111111'.
    ENDIF.

    LOOP AT zcl_abappdf_json=>items( ir_rows ) INTO lr_row.
      CLEAR lv_cells.
      lv_col = 0.
      lv_height = json_text( ir_node = lr_row iv_name = 'height' ).
      IF lv_height IS INITIAL.
        lv_height = zcl_abappdf_config=>row_height_px.
      ENDIF.
      lv_shade = json_text( ir_node = lr_row iv_name = 'shade' ).
      lv_mode = json_text( ir_node = lr_row iv_name = 'mode' ).
      lv_path = json_text( ir_node = lr_row iv_name = 'dataPath' ).
      LOOP AT zcl_abappdf_json=>items(
          zcl_abappdf_json=>member( ir_node = lr_row iv_name = 'cells' ) ) INTO lr_cell.
        lv_span = json_text( ir_node = lr_cell iv_name = 'colspan' ).
        IF lv_span = '0'.
          CONTINUE.
        ENDIF.
        IF lv_span IS INITIAL OR lv_span CN '0123456789'.
          lv_span = '1'.
        ENDIF.
        CLEAR lv_width.
        DO CONV i( lv_span ) TIMES.
          lv_col = lv_col + 1.
          READ TABLE lt_widths INDEX lv_col INTO lv_item.
          IF sy-subrc = 0 AND lv_item IS NOT INITIAL AND lv_item CO '0123456789.'.
            lv_width = lv_width + CONV decfloat34( lv_item ).
          ENDIF.
        ENDDO.
        lv_text = json_text( ir_node = lr_cell iv_name = 'text' ).
        lv_fmt = json_text( ir_node = lr_cell iv_name = 'fmt' ).
        IF lv_fmt IS NOT INITIAL AND lv_text IS NOT INITIAL.
          lv_text = |<span data-fmt="{ lv_fmt }">{ lv_text }</span>|.
        ENDIF.
        lv_color = json_text( ir_node = lr_cell iv_name = 'color' ).
        lv_align = json_text( ir_node = lr_cell iv_name = 'align' ).
        lv_bold = json_text( ir_node = lr_cell iv_name = 'bold' ).
        lv_fill = json_text( ir_node = lr_cell iv_name = 'fill' ).
        lv_size = json_text( ir_node = lr_cell iv_name = 'size' ).
        lv_border_w = json_text( ir_node = lr_cell iv_name = 'borderW' ).
        lv_border_c = json_text( ir_node = lr_cell iv_name = 'borderColor' ).
        IF lv_border_w IS INITIAL.
          lv_border_w = lv_table_bw.
        ENDIF.
        IF lv_border_c IS INITIAL.
          lv_border_c = lv_table_bc.
        ENDIF.
        lv_style = 'height:' && lv_height && 'px;'.
        IF lv_width > 0.
          lv_style = lv_style && |width:{ lv_width }px;|.
        ENDIF.
        lv_style = lv_style && 'border:' && lv_border_w && 'px solid ' && lv_border_c && ';'.
        IF lv_fill IS NOT INITIAL AND lv_fill <> 'transparent'.
          lv_style = lv_style && 'background:' && lv_fill && ';'.
        ELSEIF lv_mode = 'data' AND lv_path IS NOT INITIAL AND lv_alt IS NOT INITIAL.
          IF lv_shade IS NOT INITIAL.
            lv_style = lv_style && `background:{{#if ROW_EVEN}}` && lv_alt && '{{else}}' && lv_shade && '{{/if}};'.
          ELSE.
            lv_style = lv_style && `{{#if ROW_EVEN}}background:` && lv_alt && ';{{/if}}'.
          ENDIF.
        ELSEIF lv_shade IS NOT INITIAL.
          lv_style = lv_style && 'background:' && lv_shade && ';'.
        ENDIF.
        IF lv_size IS NOT INITIAL AND lv_size <> '0'.
          lv_style = lv_style && 'font-size:' && lv_size && 'pt;'.
        ENDIF.
        IF lv_color IS NOT INITIAL.
          lv_style = lv_style && 'color:' && lv_color && ';'.
        ENDIF.
        IF lv_align IS NOT INITIAL.
          lv_style = lv_style && 'text-align:' && lv_align && ';'.
        ENDIF.
        IF lv_bold = '1' OR lv_bold = 'true'.
          lv_style = lv_style && 'font-weight:bold;'.
        ENDIF.
        lv_cells = lv_cells && '<td style="' && lv_style && '">' && lv_text && '</td>'.
      ENDLOOP.
      IF lv_cells IS INITIAL.
        CONTINUE.
      ENDIF.
      IF lv_mode = 'data' AND lv_path IS NOT INITIAL.
        rv_html = rv_html && `{{#each ` && lv_path && '}}'.
      ENDIF.
      rv_html = rv_html && '<tr>' && lv_cells && '</tr>'.
      IF lv_mode = 'data' AND lv_path IS NOT INITIAL.
        rv_html = rv_html && '{{/each}}'.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD json_text.
    rv_text = zcl_abappdf_json=>text_of(
      zcl_abappdf_json=>member( ir_node = ir_node iv_name = iv_name ) ).
  ENDMETHOD.

ENDCLASS.
