CLASS zcl_abappdf_renderer DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_page,
        page_size     TYPE string,
        orientation   TYPE c LENGTH 1,
        margin_top    TYPE i,
        margin_right  TYPE i,
        margin_bottom TYPE i,
        margin_left   TYPE i,
      END OF ty_page.

    CLASS-METHODS render
      IMPORTING
        iv_html       TYPE string
        iv_header     TYPE string OPTIONAL
        iv_footer     TYPE string OPTIONAL
        is_page       TYPE ty_page OPTIONAL
      RETURNING
        VALUE(rv_pdf) TYPE xstring
      RAISING
        zcx_abappdf.

    CLASS-METHODS px_to_pt
      IMPORTING
        iv_px        TYPE decfloat34
      RETURNING
        VALUE(rv_pt) TYPE decfloat34.

    CLASS-METHODS validate_page
      IMPORTING
        is_page TYPE ty_page
      RAISING
        zcx_abappdf.

  PRIVATE SECTION.
    "Printable ASCII in code order and the AFM advance widths (1/1000 em) of
    "Helvetica and Helvetica-Bold for each character, three digits per character.
    CONSTANTS c_ascii TYPE string VALUE ` !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_``abcdefghijklmnopqrstuvwxyz{|}~`.
    CONSTANTS c_helv_1 TYPE string VALUE `278278355556556889667191333333389584278333278278556556556556556556556556556556278278584584584556`.
    CONSTANTS c_helv_2 TYPE string VALUE `999667667722722667611778722278500667556833722778667778722667611722667944667667611278278278469556`.
    CONSTANTS c_helv_3 TYPE string VALUE `333556556500556556278556556222222500222833556556556556333500278556500722500500500334260334584`.
    CONSTANTS c_bold_1 TYPE string VALUE `278333474556556889722238333333389584278333278278556556556556556556556556556556333333584584584611`.
    CONSTANTS c_bold_2 TYPE string VALUE `975722722722722667611778722278556722611833722778667778722667611722667944667667611333278333584556`.
    CONSTANTS c_bold_3 TYPE string VALUE `333556611556611556333611611278278556278889611611611611389556333611556778556556500389280389584`.

    TYPES:
      BEGIN OF ty_box,
        page     TYPE i,
        fixed    TYPE abap_bool,
        footer   TYPE abap_bool,
        x        TYPE decfloat34,
        y        TYPE decfloat34,
        w        TYPE decfloat34,
        h        TYPE decfloat34,
        text     TYPE string,
        size     TYPE decfloat34,
        bold     TYPE abap_bool,
        italic   TYPE abap_bool,
        face     TYPE string,
        color    TYPE string,
        fill     TYPE string,
        border   TYPE string,
        border_w TYPE decfloat34,
        align    TYPE string,
        code     TYPE string,
        ecc      TYPE string,
        hr       TYPE abap_bool,
        flow     TYPE i,
        valign   TYPE string,
      END OF ty_box,
      ty_boxes TYPE STANDARD TABLE OF ty_box WITH EMPTY KEY,
      BEGIN OF ty_grow,
        flow   TYPE i,
        top    TYPE decfloat34,
        design TYPE decfloat34,
        left   TYPE decfloat34,
        width  TYPE decfloat34,
        actual TYPE decfloat34,
        extra  TYPE decfloat34,
        push   TYPE decfloat34,
      END OF ty_grow,
      ty_grows TYPE STANDARD TABLE OF ty_grow WITH EMPTY KEY.

    CLASS-METHODS page_mm
      IMPORTING
        is_page    TYPE ty_page
      EXPORTING
        ev_width   TYPE decfloat34
        ev_height  TYPE decfloat34.

    CLASS-METHODS collect
      IMPORTING
        iv_html        TYPE string
        iv_fixed       TYPE abap_bool DEFAULT abap_false
        iv_footer      TYPE abap_bool DEFAULT abap_false
        iv_page_h      TYPE decfloat34
      RETURNING
        VALUE(rt_boxes) TYPE ty_boxes.

    CLASS-METHODS element_span
      IMPORTING
        iv_html      TYPE string
        iv_open      TYPE i
      EXPORTING
        ev_tag       TYPE string
        ev_style     TYPE string
        ev_inner     TYPE string
        ev_after     TYPE i.

    CLASS-METHODS style_prop
      IMPORTING
        iv_style       TYPE string
        iv_name        TYPE string
      RETURNING
        VALUE(rv_value) TYPE string.

    CLASS-METHODS style_num
      IMPORTING
        iv_style       TYPE string
        iv_name        TYPE string
      RETURNING
        VALUE(rv_value) TYPE decfloat34.

    CLASS-METHODS has_position
      IMPORTING
        iv_style     TYPE string
      RETURNING
        VALUE(rv_yes) TYPE abap_bool.

    CLASS-METHODS plain_text
      IMPORTING
        iv_html        TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.

    CLASS-METHODS unescape
      IMPORTING
        iv_text        TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.

    CLASS-METHODS table_boxes
      IMPORTING
        iv_inner       TYPE string
        iv_style       TYPE string
        iv_fixed       TYPE abap_bool
        iv_footer      TYPE abap_bool
        iv_flow        TYPE i DEFAULT 0
      RETURNING
        VALUE(rt_boxes) TYPE ty_boxes.

    CLASS-METHODS flow_down
      IMPORTING
        it_boxes       TYPE ty_boxes
        it_grow        TYPE ty_grows
      RETURNING
        VALUE(rt_boxes) TYPE ty_boxes.

    "! Width of a text line in points, from the Helvetica / Courier metrics.
    CLASS-METHODS text_width
      IMPORTING
        iv_text         TYPE string
        iv_size         TYPE decfloat34
        iv_face         TYPE string
      RETURNING
        VALUE(rv_width) TYPE decfloat34.

    "! Breaks text into lines that fit iv_width, at spaces, like a browser.
    CLASS-METHODS wrap_text
      IMPORTING
        iv_text         TYPE string
        iv_size         TYPE decfloat34
        iv_face         TYPE string
        iv_width        TYPE decfloat34
      RETURNING
        VALUE(rt_lines) TYPE string_table.

    "! Header or footer HTML without positioned elements (as the designer saves it)
    "! becomes one text box across the top or bottom margin.
    CLASS-METHODS band_box
      IMPORTING
        iv_html       TYPE string
        iv_footer     TYPE abap_bool
        iv_x          TYPE decfloat34
        iv_y          TYPE decfloat34
        iv_w          TYPE decfloat34
        iv_h          TYPE decfloat34
      RETURNING
        VALUE(rs_box) TYPE ty_box.

    CLASS-METHODS pdf_color
      IMPORTING
        iv_value       TYPE string
      RETURNING
        VALUE(rv_rgb)  TYPE string.

    CLASS-METHODS nibble
      IMPORTING
        iv_ch      TYPE string
      RETURNING
        VALUE(rv_n) TYPE i.

    CLASS-METHODS face_name
      IMPORTING
        is_box       TYPE ty_box
      RETURNING
        VALUE(rv_face) TYPE string.

    CLASS-METHODS num2
      IMPORTING
        iv_value       TYPE decfloat34
      RETURNING
        VALUE(rv_text) TYPE string.

    CLASS-METHODS pdf_escape
      IMPORTING
        iv_text        TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.

    CLASS-METHODS draw_box
      IMPORTING
        is_box         TYPE ty_box
        iv_page_h      TYPE decfloat34
        iv_page_no     TYPE i
        iv_page_count  TYPE i
        it_faces       TYPE string_table
      RETURNING
        VALUE(rv_ops)  TYPE string
      RAISING
        zcx_abappdf.

    CLASS-METHODS html_attr
      IMPORTING
        iv_tag         TYPE string
        iv_name        TYPE string
      RETURNING
        VALUE(rv_value) TYPE string.

    CLASS-METHODS code_ops
      IMPORTING
        is_box       TYPE ty_box
        iv_x         TYPE decfloat34
        iv_y         TYPE decfloat34
        iv_w         TYPE decfloat34
        iv_h         TYPE decfloat34
      RETURNING
        VALUE(rv_ops) TYPE string
      RAISING
        zcx_abappdf.

    CLASS-METHODS assemble
      IMPORTING
        it_pages       TYPE string_table
        it_faces       TYPE string_table
        iv_width       TYPE decfloat34
        iv_height      TYPE decfloat34
      RETURNING
        VALUE(rv_pdf)  TYPE xstring
      RAISING
        zcx_abappdf.
ENDCLASS.



CLASS zcl_abappdf_renderer IMPLEMENTATION.

  METHOD render.
    DATA ls_page TYPE ty_page.
    DATA lv_mm_w TYPE decfloat34.
    DATA lv_mm_h TYPE decfloat34.
    DATA lv_page_h_px TYPE decfloat34.
    DATA lt_boxes TYPE ty_boxes.
    DATA lt_fixed TYPE ty_boxes.
    DATA ls_box TYPE ty_box.
    DATA lt_faces TYPE string_table.
    DATA lt_pages TYPE string_table.
    DATA lv_ops TYPE string.
    DATA lv_max TYPE i.
    DATA lv_page TYPE i.
    DATA lv_count TYPE i.
    DATA lv_margin_x TYPE decfloat34.
    DATA lv_margin_y TYPE decfloat34.
    DATA lv_body_h_px TYPE decfloat34.
    DATA lv_break TYPE decfloat34.
    DATA lv_local TYPE decfloat34.
    DATA lv_delta TYPE decfloat34.
    DATA lv_found TYPE abap_bool.
    DATA lv_arabic TYPE abap_bool.
    DATA lv_px_mm TYPE decfloat34.
    DATA lv_page_w_px TYPE decfloat34.
    DATA lv_band TYPE decfloat34.

    ls_page = is_page.
    IF ls_page-page_size IS INITIAL.
      ls_page-page_size = zcl_abappdf_config=>page_a4.
    ENDIF.
    IF ls_page-orientation IS INITIAL.
      ls_page-orientation = zcl_abappdf_config=>orient_portrait.
    ENDIF.
    ls_page-page_size = to_upper( ls_page-page_size ).
    ls_page-orientation = to_upper( ls_page-orientation ).
    validate_page( ls_page ).
    page_mm(
      EXPORTING is_page = ls_page
      IMPORTING ev_width = lv_mm_w ev_height = lv_mm_h ).
    lv_page_h_px = lv_mm_h * zcl_abappdf_config=>px_per_inch / zcl_abappdf_config=>mm_per_inch.
    "Designer positions are relative to the printable area: content boxes are laid out on
    "pages of the printable height and moved by the left and top margins when they are drawn.
    lv_margin_x = ls_page-margin_left * zcl_abappdf_config=>px_per_inch / zcl_abappdf_config=>mm_per_inch.
    lv_margin_y = ls_page-margin_top * zcl_abappdf_config=>px_per_inch / zcl_abappdf_config=>mm_per_inch.
    lv_body_h_px = lv_page_h_px
      - ( ls_page-margin_top + ls_page-margin_bottom ) * zcl_abappdf_config=>px_per_inch / zcl_abappdf_config=>mm_per_inch.
    IF lv_body_h_px <= 0.
      lv_body_h_px = lv_page_h_px.
    ENDIF.

    lt_boxes = collect( iv_html = iv_html iv_page_h = lv_page_h_px ).
    lt_fixed = collect(
      iv_html   = iv_header
      iv_fixed  = abap_true
      iv_page_h = lv_page_h_px ).
    APPEND LINES OF collect(
      iv_html   = iv_footer
      iv_fixed  = abap_true
      iv_footer = abap_true
      iv_page_h = lv_page_h_px ) TO lt_fixed.

    lv_px_mm = zcl_abappdf_config=>px_per_inch / zcl_abappdf_config=>mm_per_inch.
    lv_page_w_px = lv_mm_w * lv_px_mm.
    lv_band = ls_page-margin_bottom * lv_px_mm.
    IF lv_band < 20.
      lv_band = 20.
    ENDIF.
    IF iv_footer IS NOT INITIAL AND iv_footer NS 'position:' AND plain_text( iv_footer ) IS NOT INITIAL.
      APPEND band_box(
        iv_html   = iv_footer
        iv_footer = abap_true
        iv_x      = ls_page-margin_left * lv_px_mm
        iv_y      = lv_page_h_px - lv_band
        iv_w      = lv_page_w_px - ( ls_page-margin_left + ls_page-margin_right ) * lv_px_mm
        iv_h      = lv_band ) TO lt_fixed.
    ENDIF.
    lv_band = ls_page-margin_top * lv_px_mm.
    IF lv_band < 20.
      lv_band = 20.
    ENDIF.
    IF iv_header IS NOT INITIAL AND iv_header NS 'position:' AND plain_text( iv_header ) IS NOT INITIAL.
      APPEND band_box(
        iv_html   = iv_header
        iv_footer = abap_false
        iv_x      = ls_page-margin_left * lv_px_mm
        iv_y      = 0
        iv_w      = lv_page_w_px - ( ls_page-margin_left + ls_page-margin_right ) * lv_px_mm
        iv_h      = lv_band ) TO lt_fixed.
    ENDIF.

    IF lt_boxes IS INITIAL AND iv_html IS NOT INITIAL AND iv_html NS 'position:'.
      CLEAR ls_box.
      ls_box-x = zcl_abappdf_config=>fallback_inset_px.
      ls_box-y = zcl_abappdf_config=>fallback_inset_px.
      ls_box-w = lv_mm_w * zcl_abappdf_config=>px_per_inch / zcl_abappdf_config=>mm_per_inch
        - zcl_abappdf_config=>fallback_inset_px * 2.
      ls_box-h = zcl_abappdf_config=>fallback_height_px.
      ls_box-text = plain_text( iv_html ).
      ls_box-size = zcl_abappdf_config=>fallback_font_pt.
      ls_box-face = zcl_abappdf_config=>font_helvetica.
      ls_box-color = zcl_abappdf_config=>fallback_color.
      ls_box-align = 'left'.
      APPEND ls_box TO lt_boxes.
    ENDIF.

    IF lv_body_h_px > 0.
      lv_found = abap_false.
      LOOP AT lt_boxes INTO ls_box WHERE fixed = abap_false AND flow = 0.
        IF ls_box-h <= 0 OR ls_box-h >= lv_body_h_px.
          CONTINUE.
        ENDIF.
        lv_page = trunc( ls_box-y / lv_body_h_px ).
        lv_local = ls_box-y - lv_page * lv_body_h_px.
        IF lv_local + ls_box-h > lv_body_h_px.
          IF lv_found = abap_false OR ls_box-y < lv_break.
            lv_break = ls_box-y.
            lv_found = abap_true.
          ENDIF.
        ENDIF.
      ENDLOOP.
      IF lv_found = abap_true.
        lv_page = trunc( lv_break / lv_body_h_px ).
        lv_delta = ( lv_page + 1 ) * lv_body_h_px - lv_break.
        LOOP AT lt_boxes INTO ls_box WHERE fixed = abap_false AND flow = 0 AND y >= lv_break.
          ls_box-y = ls_box-y + lv_delta.
          MODIFY lt_boxes FROM ls_box.
        ENDLOOP.
      ENDIF.
    ENDIF.

    LOOP AT lt_boxes INTO ls_box.
      IF ls_box-fixed = abap_false AND lv_body_h_px > 0 AND ls_box-y >= lv_body_h_px.
        ls_box-page = trunc( ls_box-y / lv_body_h_px ).
        ls_box-y = ls_box-y - ls_box-page * lv_body_h_px.
      ENDIF.
      IF ls_box-fixed = abap_false.
        ls_box-x = ls_box-x + lv_margin_x.
        ls_box-y = ls_box-y + lv_margin_y.
      ENDIF.
      IF ls_box-page > lv_max.
        lv_max = ls_box-page.
      ENDIF.
      ls_box-face = face_name( ls_box ).
      MODIFY lt_boxes FROM ls_box.
      READ TABLE lt_faces TRANSPORTING NO FIELDS WITH KEY table_line = ls_box-face.
      IF sy-subrc <> 0.
        APPEND ls_box-face TO lt_faces.
      ENDIF.
    ENDLOOP.
    LOOP AT lt_fixed INTO ls_box.
      ls_box-face = face_name( ls_box ).
      MODIFY lt_fixed FROM ls_box.
      READ TABLE lt_faces TRANSPORTING NO FIELDS WITH KEY table_line = ls_box-face.
      IF sy-subrc <> 0.
        APPEND ls_box-face TO lt_faces.
      ENDIF.
    ENDLOOP.
    IF lt_faces IS INITIAL.
      APPEND zcl_abappdf_config=>font_helvetica TO lt_faces.
    ENDIF.
    LOOP AT lt_boxes INTO ls_box.
      IF zcl_abappdf_font=>contains( ls_box-text ) = abap_true.
        lv_arabic = abap_true.
      ENDIF.
    ENDLOOP.
    LOOP AT lt_fixed INTO ls_box.
      IF zcl_abappdf_font=>contains( ls_box-text ) = abap_true.
        lv_arabic = abap_true.
      ENDIF.
    ENDLOOP.
    IF lv_arabic = abap_true.
      READ TABLE lt_faces WITH KEY table_line = zcl_abappdf_config=>font_arabic TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        APPEND zcl_abappdf_config=>font_arabic TO lt_faces.
      ENDIF.
    ENDIF.

    lv_count = lv_max + 1.
    DO lv_count TIMES.
      lv_page = sy-index - 1.
      CLEAR lv_ops.
      LOOP AT lt_fixed INTO ls_box.
        lv_ops = lv_ops && draw_box(
          is_box        = ls_box
          iv_page_h     = lv_mm_h * zcl_abappdf_config=>points_per_inch / zcl_abappdf_config=>mm_per_inch
          iv_page_no    = lv_page + 1
          iv_page_count = lv_count
          it_faces      = lt_faces ).
      ENDLOOP.
      LOOP AT lt_boxes INTO ls_box WHERE page = lv_page.
        lv_ops = lv_ops && draw_box(
          is_box        = ls_box
          iv_page_h     = lv_mm_h * zcl_abappdf_config=>points_per_inch / zcl_abappdf_config=>mm_per_inch
          iv_page_no    = lv_page + 1
          iv_page_count = lv_count
          it_faces      = lt_faces ).
      ENDLOOP.
      APPEND lv_ops TO lt_pages.
    ENDDO.

    rv_pdf = assemble(
      it_pages  = lt_pages
      it_faces  = lt_faces
      iv_width  = lv_mm_w * zcl_abappdf_config=>points_per_inch / zcl_abappdf_config=>mm_per_inch
      iv_height = lv_mm_h * zcl_abappdf_config=>points_per_inch / zcl_abappdf_config=>mm_per_inch ).
  ENDMETHOD.


  METHOD px_to_pt.
    rv_pt = iv_px * zcl_abappdf_config=>points_per_inch / zcl_abappdf_config=>px_per_inch.
  ENDMETHOD.


  METHOD validate_page.
    DATA lv_width TYPE decfloat34.
    DATA lv_height TYPE decfloat34.
    IF is_page-page_size <> zcl_abappdf_config=>page_a3 AND is_page-page_size <> zcl_abappdf_config=>page_a4 AND
       is_page-page_size <> zcl_abappdf_config=>page_a5 AND is_page-page_size <> zcl_abappdf_config=>page_letter AND
       is_page-page_size <> zcl_abappdf_config=>page_legal.
      RAISE EXCEPTION TYPE zcx_abappdf EXPORTING textid = zcx_abappdf=>page_size_unknown msgv1 = CONV symsgv( is_page-page_size ).
    ENDIF.
    IF is_page-orientation <> zcl_abappdf_config=>orient_portrait AND is_page-orientation <> zcl_abappdf_config=>orient_landscape.
      RAISE EXCEPTION TYPE zcx_abappdf
        EXPORTING
          textid = zcx_abappdf=>orientation_invalid
          msgv1  = CONV symsgv( zcl_abappdf_config=>orient_portrait )
          msgv2  = CONV symsgv( zcl_abappdf_config=>orient_landscape ).
    ENDIF.
    IF is_page-margin_top < 0 OR is_page-margin_top > zcl_abappdf_config=>margin_max_mm OR
       is_page-margin_right < 0 OR is_page-margin_right > zcl_abappdf_config=>margin_max_mm OR
       is_page-margin_bottom < 0 OR is_page-margin_bottom > zcl_abappdf_config=>margin_max_mm OR
       is_page-margin_left < 0 OR is_page-margin_left > zcl_abappdf_config=>margin_max_mm.
      RAISE EXCEPTION TYPE zcx_abappdf EXPORTING textid = zcx_abappdf=>margin_range msgv1 = CONV symsgv( zcl_abappdf_config=>margin_max_mm ).
    ENDIF.
    page_mm(
      EXPORTING is_page = is_page
      IMPORTING ev_width = lv_width ev_height = lv_height ).
    IF is_page-margin_left + is_page-margin_right >= lv_width OR
       is_page-margin_top + is_page-margin_bottom >= lv_height.
      RAISE EXCEPTION TYPE zcx_abappdf EXPORTING textid = zcx_abappdf=>margin_area.
    ENDIF.
  ENDMETHOD.


  METHOD page_mm.
    CASE is_page-page_size.
      WHEN zcl_abappdf_config=>page_a3.
        ev_width = zcl_abappdf_config=>mm_a3_short.
        ev_height = zcl_abappdf_config=>mm_a3_long.
      WHEN zcl_abappdf_config=>page_a5.
        ev_width = zcl_abappdf_config=>mm_a5_short.
        ev_height = zcl_abappdf_config=>mm_a5_long.
      WHEN zcl_abappdf_config=>page_letter.
        ev_width = zcl_abappdf_config=>mm_letter_short.
        ev_height = zcl_abappdf_config=>mm_letter_long.
      WHEN zcl_abappdf_config=>page_legal.
        ev_width = zcl_abappdf_config=>mm_legal_short.
        ev_height = zcl_abappdf_config=>mm_legal_long.
      WHEN OTHERS.
        ev_width = zcl_abappdf_config=>mm_a4_short.
        ev_height = zcl_abappdf_config=>mm_a4_long.
    ENDCASE.
    IF is_page-orientation = zcl_abappdf_config=>orient_landscape.
      DATA(lv_swap) = ev_width.
      ev_width = ev_height.
      ev_height = lv_swap.
    ENDIF.
  ENDMETHOD.


  METHOD collect.
    DATA lv_pos TYPE i.
    DATA lv_at TYPE i.
    DATA lv_len TYPE i.
    DATA lv_tag TYPE string.
    DATA lv_style TYPE string.
    DATA lv_inner TYPE string.
    DATA lv_after TYPE i.
    DATA lv_lower TYPE string.
    DATA ls_box TYPE ty_box.
    DATA lv_html TYPE string.
    DATA lv_gt TYPE i.
    DATA lv_open TYPE string.
    DATA lv_attr TYPE string.
    DATA lv_flow TYPE i.
    DATA lv_design_h TYPE decfloat34.
    DATA ls_grow TYPE ty_grow.
    DATA lt_grow TYPE ty_grows.

    lv_html = iv_html.
    REPLACE ALL OCCURRENCES OF '<script' IN lv_html WITH '<script'.
    lv_len = strlen( lv_html ).
    WHILE lv_pos < lv_len.
      lv_lower = to_lower( lv_html ).
      lv_at = find( val = lv_lower sub = '<script' off = lv_pos ).
      IF lv_at >= 0.
        DATA(lv_script_end) = find( val = lv_lower sub = '</script>' off = lv_at ).
        IF lv_script_end > lv_at.
          lv_html = substring( val = lv_html off = 0 len = lv_at ) &&
            substring( val = lv_html off = lv_script_end + 9 ).
          lv_len = strlen( lv_html ).
          lv_pos = lv_at.
          CONTINUE.
        ENDIF.
      ENDIF.
      EXIT.
    ENDWHILE.

    lv_pos = 0.
    lv_len = strlen( lv_html ).
    WHILE lv_pos < lv_len.
      lv_at = find( val = lv_html sub = '<' off = lv_pos ).
      IF lv_at < 0.
        EXIT.
      ENDIF.
      element_span(
        EXPORTING iv_html = lv_html iv_open = lv_at
        IMPORTING ev_tag = lv_tag ev_style = lv_style ev_inner = lv_inner ev_after = lv_after ).
      IF lv_after <= lv_at.
        lv_pos = lv_at + 1.
        CONTINUE.
      ENDIF.
      IF ( lv_tag = 'div' OR lv_tag = 'table' ) AND has_position( lv_style ) = abap_true.
        IF lv_tag = 'table'.
          lv_flow = lv_flow + 1.
          CLEAR lv_open.
          CLEAR lv_attr.
          CLEAR lv_design_h.
          lv_gt = find( val = lv_html sub = '>' off = lv_at ).
          IF lv_gt > lv_at.
            lv_open = substring( val = lv_html off = lv_at len = lv_gt - lv_at + 1 ).
            lv_attr = html_attr( iv_tag = lv_open iv_name = 'data-design-h' ).
          ENDIF.
          IF lv_attr IS NOT INITIAL.
            lv_design_h = style_num( iv_style = |height:{ lv_attr }px| iv_name = 'height' ).
          ELSE.
            lv_design_h = style_num( iv_style = lv_style iv_name = 'height' ).
          ENDIF.
          APPEND LINES OF table_boxes(
            iv_inner  = lv_inner
            iv_style  = lv_style
            iv_fixed  = iv_fixed
            iv_footer = iv_footer
            iv_flow   = lv_flow ) TO rt_boxes.
          IF lv_design_h > 0.
            CLEAR ls_grow.
            ls_grow-flow = lv_flow.
            ls_grow-top = style_num( iv_style = lv_style iv_name = 'top' ).
            ls_grow-design = ls_grow-top + lv_design_h.
            ls_grow-left = style_num( iv_style = lv_style iv_name = 'left' ).
            ls_grow-width = style_num( iv_style = lv_style iv_name = 'width' ).
            APPEND ls_grow TO lt_grow.
          ENDIF.
        ELSE.
          CLEAR ls_box.
          ls_box-fixed = iv_fixed.
          ls_box-footer = iv_footer.
          ls_box-x = style_num( iv_style = lv_style iv_name = 'left' ).
          ls_box-y = style_num( iv_style = lv_style iv_name = 'top' ).
          ls_box-w = style_num( iv_style = lv_style iv_name = 'width' ).
          ls_box-h = style_num( iv_style = lv_style iv_name = 'height' ).
          IF ls_box-w <= 0.
            ls_box-w = 120.
          ENDIF.
          IF ls_box-h <= 0.
            ls_box-h = 20.
          ENDIF.
          ls_box-size = style_num( iv_style = lv_style iv_name = 'font-size' ).
          IF ls_box-size <= 0.
            ls_box-size = 12.
          ENDIF.
          IF style_prop( iv_style = lv_style iv_name = 'font-size' ) CS 'px'.
            ls_box-size = px_to_pt( ls_box-size ).
          ENDIF.
          ls_box-text = plain_text( lv_inner ).
          lv_gt = find( val = lv_html sub = '>' off = lv_at ).
          IF lv_gt > lv_at.
            lv_open = substring( val = lv_html off = lv_at len = lv_gt - lv_at + 1 ).
            ls_box-code = to_lower( html_attr( iv_tag = lv_open iv_name = 'data-code' ) ).
            ls_box-ecc = html_attr( iv_tag = lv_open iv_name = 'data-ecc' ).
            IF html_attr( iv_tag = lv_open iv_name = 'data-hr' ) = '1'.
              ls_box-hr = abap_true.
            ENDIF.
          ENDIF.
          ls_box-color = pdf_color( style_prop( iv_style = lv_style iv_name = 'color' ) ).
          ls_box-fill = pdf_color( style_prop( iv_style = lv_style iv_name = 'background' ) ).
          ls_box-border_w = style_num( iv_style = lv_style iv_name = 'border' ).
          ls_box-border = pdf_color( style_prop( iv_style = lv_style iv_name = 'border' ) ).
          ls_box-align = to_lower( style_prop( iv_style = lv_style iv_name = 'text-align' ) ).
          IF style_prop( iv_style = lv_style iv_name = 'font-weight' ) CS 'bold'
              OR style_prop( iv_style = lv_style iv_name = 'font-weight' ) = '700'.
            ls_box-bold = abap_true.
          ENDIF.
          IF style_prop( iv_style = lv_style iv_name = 'font-style' ) CS 'italic'.
            ls_box-italic = abap_true.
          ENDIF.
          ls_box-face = style_prop( iv_style = lv_style iv_name = 'font-family' ).
          IF to_lower( lv_style ) CS 'position:fixed' OR to_lower( lv_style ) CS 'position: fixed'.
            ls_box-fixed = abap_true.
          ENDIF.
          APPEND ls_box TO rt_boxes.
        ENDIF.
        lv_pos = lv_after.
        CONTINUE.
      ENDIF.
      lv_pos = lv_at + 1.
    ENDWHILE.
    IF lt_grow IS NOT INITIAL.
      rt_boxes = flow_down( it_boxes = rt_boxes it_grow = lt_grow ).
    ENDIF.
  ENDMETHOD.


  METHOD flow_down.
    DATA ls_grow TYPE ty_grow.
    DATA ls_box TYPE ty_box.
    DATA ls_extra TYPE ty_grow.
    DATA lt_extra TYPE ty_grows.
    DATA lv_actual TYPE decfloat34.
    DATA lv_shift TYPE decfloat34.
    DATA lv_min TYPE decfloat34.
    DATA lv_found TYPE abap_bool.

    rt_boxes = it_boxes.
    LOOP AT it_grow INTO ls_grow.
      lv_actual = ls_grow-top.
      LOOP AT rt_boxes INTO ls_box WHERE flow = ls_grow-flow.
        IF ls_box-y + ls_box-h > lv_actual.
          lv_actual = ls_box-y + ls_box-h.
        ENDIF.
      ENDLOOP.
      CLEAR ls_extra.
      ls_extra-flow = ls_grow-flow.
      ls_extra-top = ls_grow-top.
      ls_extra-design = ls_grow-design.
      ls_extra-left = ls_grow-left.
      ls_extra-width = ls_grow-width.
      ls_extra-actual = lv_actual.
      IF lv_actual > ls_grow-design.
        ls_extra-extra = lv_actual - ls_grow-design.
      ENDIF.
      lv_min = lv_actual.
      lv_found = abap_false.
      LOOP AT rt_boxes INTO ls_box WHERE flow = 0.
        IF ls_box-y >= ls_grow-design OR ls_box-y >= lv_actual OR ls_box-y + 1 < ls_grow-top.
          CONTINUE.
        ENDIF.
        IF ls_box-y + ls_box-h <= ls_grow-top.
          CONTINUE.
        ENDIF.
        IF ls_extra-width <= 0
            OR ls_box-x + ls_box-w <= ls_extra-left
            OR ls_box-x >= ls_extra-left + ls_extra-width.
          CONTINUE.
        ENDIF.
        lv_found = abap_true.
        IF ls_box-y < lv_min.
          lv_min = ls_box-y.
        ENDIF.
      ENDLOOP.
      IF lv_found = abap_true.
        ls_extra-push = lv_actual - lv_min.
      ENDIF.
      IF ls_extra-extra > 0 OR ls_extra-push > 0.
        APPEND ls_extra TO lt_extra.
      ENDIF.
    ENDLOOP.

    LOOP AT rt_boxes INTO ls_box.
      CLEAR lv_shift.
      LOOP AT lt_extra INTO ls_extra.
        IF ls_box-flow = ls_extra-flow.
          CONTINUE.
        ENDIF.
        IF ls_box-y >= ls_extra-design AND ls_extra-extra > 0.
          lv_shift = lv_shift + ls_extra-extra.
          CONTINUE.
        ENDIF.
        IF ls_box-flow <> 0 OR ls_extra-push <= 0 OR ls_box-y >= ls_extra-design.
          CONTINUE.
        ENDIF.
        IF ls_box-y >= ls_extra-actual OR ls_box-y + 1 < ls_extra-top OR ls_box-y + ls_box-h <= ls_extra-top.
          CONTINUE.
        ENDIF.
        IF ls_box-x + ls_box-w <= ls_extra-left OR ls_box-x >= ls_extra-left + ls_extra-width.
          CONTINUE.
        ENDIF.
        IF ls_extra-push > lv_shift.
          lv_shift = ls_extra-push.
        ENDIF.
      ENDLOOP.
      IF lv_shift > 0.
        ls_box-y = ls_box-y + lv_shift.
        MODIFY rt_boxes FROM ls_box.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD element_span.
    DATA lv_len TYPE i.
    DATA lv_pos TYPE i.
    DATA lv_ch TYPE c LENGTH 1.
    DATA lv_in TYPE abap_bool.
    DATA lv_depth TYPE i.
    DATA lv_name TYPE string.
    DATA lv_lower TYPE string.
    DATA lv_gt TYPE i.
    DATA lv_close TYPE string.

    CLEAR: ev_tag, ev_style, ev_inner, ev_after.
    lv_len = strlen( iv_html ).
    IF iv_open < 0 OR iv_open >= lv_len.
      RETURN.
    ENDIF.
    lv_pos = iv_open + 1.
    IF lv_pos < lv_len AND substring( val = iv_html off = lv_pos len = 1 ) = '/'.
      RETURN.
    ENDIF.
    WHILE lv_pos < lv_len.
      lv_ch = substring( val = iv_html off = lv_pos len = 1 ).
      IF lv_ch CA ' >/' AND ev_tag IS INITIAL.
        EXIT.
      ENDIF.
      IF ev_tag IS INITIAL OR lv_ch CA 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'.
        ev_tag = ev_tag && lv_ch.
      ELSE.
        EXIT.
      ENDIF.
      lv_pos = lv_pos + 1.
    ENDWHILE.
    ev_tag = to_lower( ev_tag ).
    lv_gt = find( val = iv_html sub = '>' off = iv_open ).
    IF lv_gt < 0.
      RETURN.
    ENDIF.
    DATA(lv_start_tag) = substring( val = iv_html off = iv_open len = lv_gt - iv_open ).
    DATA(lv_style_at) = find( val = to_lower( lv_start_tag ) sub = 'style="' ).
    IF lv_style_at >= 0.
      lv_style_at = lv_style_at + 7.
      DATA(lv_style_end) = find( val = lv_start_tag sub = '"' off = lv_style_at ).
      IF lv_style_end > lv_style_at.
        ev_style = substring( val = lv_start_tag off = lv_style_at len = lv_style_end - lv_style_at ).
      ENDIF.
    ENDIF.
    IF lv_gt > 0 AND substring( val = iv_html off = lv_gt - 1 len = 1 ) = '/'.
      ev_after = lv_gt + 1.
      RETURN.
    ENDIF.
    IF ev_tag IS INITIAL.
      ev_after = lv_gt + 1.
      RETURN.
    ENDIF.
    lv_close = '</' && ev_tag.
    lv_depth = 1.
    lv_pos = lv_gt + 1.
    lv_lower = to_lower( iv_html ).
    WHILE lv_pos < lv_len AND lv_depth > 0.
      DATA(lv_next) = find( val = lv_lower sub = '<' off = lv_pos ).
      IF lv_next < 0.
        EXIT.
      ENDIF.
      IF strlen( lv_lower ) >= lv_next + strlen( lv_close )
          AND substring( val = lv_lower off = lv_next len = strlen( lv_close ) ) = lv_close.
        lv_depth = lv_depth - 1.
        lv_gt = find( val = iv_html sub = '>' off = lv_next ).
        IF lv_depth = 0 AND lv_gt > lv_next.
          ev_inner = substring( val = iv_html off = find( val = iv_html sub = '>' off = iv_open ) + 1
            len = lv_next - ( find( val = iv_html sub = '>' off = iv_open ) + 1 ) ).
          ev_after = lv_gt + 1.
          RETURN.
        ENDIF.
        lv_pos = lv_next + 1.
        CONTINUE.
      ENDIF.
      lv_name = '<' && ev_tag.
      IF strlen( lv_lower ) >= lv_next + strlen( lv_name )
          AND substring( val = lv_lower off = lv_next len = strlen( lv_name ) ) = lv_name.
        DATA(lv_after_name) = lv_next + strlen( lv_name ).
        IF lv_after_name >= lv_len
            OR substring( val = lv_lower off = lv_after_name len = 1 ) CA ' >/'.
          lv_depth = lv_depth + 1.
        ENDIF.
      ENDIF.
      lv_pos = lv_next + 1.
    ENDWHILE.
    ev_after = lv_gt + 1.
  ENDMETHOD.


  METHOD style_prop.
    DATA lv_style TYPE string.
    DATA lv_key TYPE string.
    DATA lv_at TYPE i.
    DATA lv_from TYPE i.
    DATA lv_end TYPE i.
    DATA lv_prev TYPE c LENGTH 1.
    lv_style = to_lower( iv_style ).
    lv_key = to_lower( iv_name ) && ':'.
    WHILE lv_from < strlen( lv_style ).
      lv_at = find( val = lv_style sub = lv_key off = lv_from ).
      IF lv_at < 0.
        RETURN.
      ENDIF.
      IF lv_at > 0.
        lv_prev = substring( val = lv_style off = lv_at - 1 len = 1 ).
      ELSE.
        lv_prev = ';'.
      ENDIF.
      IF lv_at = 0 OR lv_prev = ';'.
        lv_end = find( val = iv_style sub = ';' off = lv_at + strlen( lv_key ) ).
        IF lv_end < 0.
          rv_value = substring( val = iv_style off = lv_at + strlen( lv_key ) ).
        ELSE.
          rv_value = substring(
            val = iv_style
            off = lv_at + strlen( lv_key )
            len = lv_end - lv_at - strlen( lv_key ) ).
        ENDIF.
        SHIFT rv_value LEFT DELETING LEADING space.
        SHIFT rv_value RIGHT DELETING TRAILING space.
        RETURN.
      ENDIF.
      lv_from = lv_at + 1.
    ENDWHILE.
  ENDMETHOD.


  METHOD style_num.
    DATA lv_val TYPE string.
    DATA lv_ch TYPE c LENGTH 1.
    DATA lv_num TYPE string.
    DATA lv_i TYPE i.
    DATA lv_dot TYPE abap_bool.
    lv_val = style_prop( iv_style = iv_style iv_name = iv_name ).
    DO strlen( lv_val ) TIMES.
      lv_i = sy-index - 1.
      lv_ch = substring( val = lv_val off = lv_i len = 1 ).
      IF lv_ch CA '0123456789'.
        lv_num = lv_num && lv_ch.
      ELSEIF lv_ch = '.' AND lv_dot = abap_false AND lv_num IS NOT INITIAL.
        lv_dot = abap_true.
        lv_num = lv_num && '.'.
      ELSEIF lv_num IS NOT INITIAL.
        EXIT.
      ENDIF.
    ENDDO.
    IF lv_num IS INITIAL OR lv_num = '.'.
      RETURN.
    ENDIF.
    TRY.
        rv_value = lv_num.
      CATCH cx_root.
        CLEAR rv_value.
    ENDTRY.
  ENDMETHOD.


  METHOD has_position.
    DATA lv_style TYPE string.
    lv_style = to_lower( iv_style ).
    IF lv_style CS 'position:absolute' OR lv_style CS 'position: absolute'
        OR lv_style CS 'position:fixed' OR lv_style CS 'position: fixed'.
      rv_yes = abap_true.
    ENDIF.
  ENDMETHOD.


  METHOD plain_text.
    DATA lv_html TYPE string.
    DATA lv_out TYPE string.
    DATA lv_i TYPE i.
    DATA lv_ch TYPE string.
    DATA lv_tag TYPE abap_bool.
    lv_html = iv_html.
    REPLACE ALL OCCURRENCES OF '<br>' IN lv_html WITH cl_abap_char_utilities=>newline.
    REPLACE ALL OCCURRENCES OF '<br/>' IN lv_html WITH cl_abap_char_utilities=>newline.
    REPLACE ALL OCCURRENCES OF '<br />' IN lv_html WITH cl_abap_char_utilities=>newline.
    DO strlen( lv_html ) TIMES.
      lv_i = sy-index - 1.
      lv_ch = substring( val = lv_html off = lv_i len = 1 ).
      IF lv_ch = '<'.
        lv_tag = abap_true.
        CONTINUE.
      ENDIF.
      IF lv_ch = '>'.
        lv_tag = abap_false.
        CONTINUE.
      ENDIF.
      IF lv_tag = abap_false.
        lv_out = lv_out && lv_ch.
      ENDIF.
    ENDDO.
    rv_text = unescape( lv_out ).
    SHIFT rv_text LEFT DELETING LEADING space.
    SHIFT rv_text RIGHT DELETING TRAILING space.
  ENDMETHOD.


  METHOD unescape.
    rv_text = iv_text.
    REPLACE ALL OCCURRENCES OF '&lt;' IN rv_text WITH '<'.
    REPLACE ALL OCCURRENCES OF '&gt;' IN rv_text WITH '>'.
    REPLACE ALL OCCURRENCES OF '&quot;' IN rv_text WITH '"'.
    REPLACE ALL OCCURRENCES OF '&#39;' IN rv_text WITH `'` .
    REPLACE ALL OCCURRENCES OF '&nbsp;' IN rv_text WITH ` `.
    REPLACE ALL OCCURRENCES OF '&amp;' IN rv_text WITH '&'.
  ENDMETHOD.


  METHOD table_boxes.
    DATA lv_lower TYPE string.
    DATA lv_pos TYPE i.
    DATA lv_row_at TYPE i.
    DATA lv_row_end TYPE i.
    DATA lv_cell_at TYPE i.
    DATA lv_cell_end TYPE i.
    DATA lv_row TYPE string.
    DATA lv_cell TYPE string.
    DATA lv_y TYPE decfloat34.
    DATA lv_x TYPE decfloat34.
    DATA lv_left TYPE decfloat34.
    DATA lv_top TYPE decfloat34.
    DATA lv_width TYPE decfloat34.
    DATA lv_row_h TYPE decfloat34.
    DATA lv_cols TYPE i.
    DATA lv_col TYPE i.
    DATA ls_box TYPE ty_box.
    DATA lt_cells TYPE string_table.
    DATA lv_cell_html TYPE string.
    DATA lv_td TYPE string.
    DATA lv_td_style TYPE string.
    DATA lv_gt TYPE i.
    DATA lv_cell_w TYPE decfloat34.
    DATA lv_table_size TYPE decfloat34.

    lv_table_size = style_num( iv_style = iv_style iv_name = 'font-size' ).
    IF style_prop( iv_style = iv_style iv_name = 'font-size' ) CS 'px'.
      lv_table_size = px_to_pt( lv_table_size ).
    ENDIF.
    IF lv_table_size <= 0.
      lv_table_size = 11.
    ENDIF.
    lv_left = style_num( iv_style = iv_style iv_name = 'left' ).
    lv_top = style_num( iv_style = iv_style iv_name = 'top' ).
    lv_width = style_num( iv_style = iv_style iv_name = 'width' ).
    IF lv_width <= 0.
      lv_width = 400.
    ENDIF.
    lv_y = lv_top.
    lv_lower = to_lower( iv_inner ).
    WHILE lv_pos < strlen( lv_lower ).
      lv_row_at = find( val = lv_lower sub = '<tr' off = lv_pos ).
      IF lv_row_at < 0.
        EXIT.
      ENDIF.
      lv_row_end = find( val = lv_lower sub = '</tr>' off = lv_row_at ).
      IF lv_row_end < 0.
        EXIT.
      ENDIF.
      lv_row = substring( val = iv_inner off = lv_row_at len = lv_row_end - lv_row_at ).
      CLEAR lt_cells.
      lv_cell_at = 0.
      DATA(lv_row_lower) = to_lower( lv_row ).
      WHILE lv_cell_at < strlen( lv_row_lower ).
        lv_cell_at = find( val = lv_row_lower sub = '<td' off = lv_cell_at ).
        IF lv_cell_at < 0.
          EXIT.
        ENDIF.
        lv_cell_end = find( val = lv_row_lower sub = '</td>' off = lv_cell_at ).
        IF lv_cell_end < 0.
          EXIT.
        ENDIF.
        lv_cell = substring( val = lv_row off = lv_cell_at len = lv_cell_end - lv_cell_at ).
        APPEND lv_cell TO lt_cells.
        lv_cell_at = lv_cell_end + 5.
      ENDWHILE.
      lv_cols = lines( lt_cells ).
      IF lv_cols = 0.
        lv_pos = lv_row_end + 5.
        CONTINUE.
      ENDIF.
      lv_row_h = 28.
      READ TABLE lt_cells INDEX 1 INTO lv_cell_html.
      lv_gt = find( val = lv_cell_html sub = '>' ).
      IF lv_gt > 0.
        lv_td_style = html_attr( iv_tag = substring( val = lv_cell_html len = lv_gt + 1 ) iv_name = 'style' ).
        IF style_num( iv_style = lv_td_style iv_name = 'height' ) > 0.
          lv_row_h = style_num( iv_style = lv_td_style iv_name = 'height' ).
        ENDIF.
      ENDIF.
      lv_x = lv_left.
      lv_col = 0.
      LOOP AT lt_cells INTO lv_cell_html.
        lv_col = lv_col + 1.
        CLEAR ls_box.
        CLEAR lv_td_style.
        lv_gt = find( val = lv_cell_html sub = '>' ).
        IF lv_gt > 0.
          lv_td = substring( val = lv_cell_html len = lv_gt + 1 ).
          lv_td_style = html_attr( iv_tag = lv_td iv_name = 'style' ).
        ENDIF.
        lv_cell_w = style_num( iv_style = lv_td_style iv_name = 'width' ).
        IF lv_cell_w <= 0.
          lv_cell_w = lv_width / lv_cols.
        ENDIF.
        ls_box-fixed = iv_fixed.
        ls_box-footer = iv_footer.
        ls_box-x = lv_x.
        ls_box-y = lv_y.
        ls_box-w = lv_cell_w.
        ls_box-h = lv_row_h.
        ls_box-text = plain_text( lv_cell_html ).
        ls_box-size = style_num( iv_style = lv_td_style iv_name = 'font-size' ).
        IF style_prop( iv_style = lv_td_style iv_name = 'font-size' ) CS 'px'.
          ls_box-size = px_to_pt( ls_box-size ).
        ENDIF.
        IF ls_box-size <= 0.
          ls_box-size = lv_table_size.
        ENDIF.
        ls_box-color = pdf_color( style_prop( iv_style = lv_td_style iv_name = 'color' ) ).
        ls_box-fill = pdf_color( style_prop( iv_style = lv_td_style iv_name = 'background' ) ).
        IF style_prop( iv_style = lv_td_style iv_name = 'border' ) IS NOT INITIAL.
          ls_box-border_w = style_num( iv_style = lv_td_style iv_name = 'border' ).
          ls_box-border = pdf_color( style_prop( iv_style = lv_td_style iv_name = 'border' ) ).
        ELSE.
          ls_box-border_w = 1.
          ls_box-border = '0.07 0.07 0.07'.
        ENDIF.
        IF style_prop( iv_style = lv_td_style iv_name = 'font-weight' ) CS 'bold'
            OR style_prop( iv_style = lv_td_style iv_name = 'font-weight' ) = '700'.
          ls_box-bold = abap_true.
        ENDIF.
        IF style_prop( iv_style = lv_td_style iv_name = 'font-style' ) CS 'italic'.
          ls_box-italic = abap_true.
        ENDIF.
        ls_box-face = style_prop( iv_style = lv_td_style iv_name = 'font-family' ).
        IF ls_box-face IS INITIAL.
          ls_box-face = style_prop( iv_style = iv_style iv_name = 'font-family' ).
        ENDIF.
        ls_box-align = to_lower( style_prop( iv_style = lv_td_style iv_name = 'text-align' ) ).
        IF ls_box-align IS INITIAL.
          ls_box-align = 'left'.
        ENDIF.
        ls_box-valign = 'middle'.
        ls_box-flow = iv_flow.
        APPEND ls_box TO rt_boxes.
        lv_x = lv_x + ls_box-w.
      ENDLOOP.
      lv_y = lv_y + lv_row_h.
      lv_pos = lv_row_end + 5.
    ENDWHILE.
  ENDMETHOD.


  METHOD text_width.
    DATA lv_metrics TYPE string.
    DATA lv_i TYPE i.
    DATA lv_at TYPE i.
    DATA lv_units TYPE i.
    DATA lv_digits TYPE n LENGTH 3.
    DATA lv_ch TYPE string.
    IF iv_face CS 'Courier'.
      rv_width = strlen( iv_text ) * iv_size * '0.6'.
      RETURN.
    ENDIF.
    IF iv_face CS 'Bold'.
      lv_metrics = c_bold_1 && c_bold_2 && c_bold_3.
    ELSE.
      lv_metrics = c_helv_1 && c_helv_2 && c_helv_3.
    ENDIF.
    DO strlen( iv_text ) TIMES.
      lv_i = sy-index - 1.
      lv_ch = substring( val = iv_text off = lv_i len = 1 ).
      lv_at = find( val = c_ascii sub = lv_ch ).
      IF lv_at >= 0.
        "A string function is not allowed inside an arithmetic expression.
        lv_digits = substring( val = lv_metrics off = lv_at * 3 len = 3 ).
        lv_units = lv_units + lv_digits.
      ELSE.
        lv_units = lv_units + 556.
      ENDIF.
    ENDDO.
    rv_width = lv_units * iv_size / 1000.
  ENDMETHOD.


  METHOD wrap_text.
    DATA lt_paragraphs TYPE string_table.
    DATA lt_words TYPE string_table.
    DATA lv_paragraph TYPE string.
    DATA lv_word TYPE string.
    DATA lv_line TYPE string.
    DATA lv_try TYPE string.
    SPLIT iv_text AT cl_abap_char_utilities=>newline INTO TABLE lt_paragraphs.
    LOOP AT lt_paragraphs INTO lv_paragraph.
      "Arabic is shaped and measured by ZCL_ABAPPDF_FONT; it stays on one line.
      IF iv_width <= 0
          OR lv_paragraph NS ` `
          OR zcl_abappdf_font=>contains( lv_paragraph ) = abap_true
          OR text_width( iv_text = lv_paragraph iv_size = iv_size iv_face = iv_face ) <= iv_width.
        APPEND lv_paragraph TO rt_lines.
        CONTINUE.
      ENDIF.
      SPLIT lv_paragraph AT ` ` INTO TABLE lt_words.
      CLEAR lv_line.
      LOOP AT lt_words INTO lv_word.
        IF lv_line IS INITIAL.
          lv_line = lv_word.
          CONTINUE.
        ENDIF.
        lv_try = lv_line && ` ` && lv_word.
        IF text_width( iv_text = lv_try iv_size = iv_size iv_face = iv_face ) > iv_width.
          APPEND lv_line TO rt_lines.
          lv_line = lv_word.
        ELSE.
          lv_line = lv_try.
        ENDIF.
      ENDLOOP.
      APPEND lv_line TO rt_lines.
    ENDLOOP.
  ENDMETHOD.


  METHOD band_box.
    DATA lv_style TYPE string.
    DATA lv_gt TYPE i.
    lv_gt = find( val = iv_html sub = '>' ).
    IF lv_gt > 0 AND iv_html CP '<*'.
      lv_style = html_attr( iv_tag = substring( val = iv_html len = lv_gt + 1 ) iv_name = 'style' ).
    ENDIF.
    rs_box-fixed = abap_true.
    rs_box-footer = iv_footer.
    rs_box-x = iv_x.
    rs_box-y = iv_y.
    rs_box-w = iv_w.
    rs_box-h = iv_h.
    rs_box-text = plain_text( iv_html ).
    rs_box-size = style_num( iv_style = lv_style iv_name = 'font-size' ).
    IF style_prop( iv_style = lv_style iv_name = 'font-size' ) CS 'px'.
      rs_box-size = px_to_pt( rs_box-size ).
    ENDIF.
    IF rs_box-size <= 0.
      rs_box-size = 9.
    ENDIF.
    rs_box-color = pdf_color( style_prop( iv_style = lv_style iv_name = 'color' ) ).
    rs_box-align = to_lower( style_prop( iv_style = lv_style iv_name = 'text-align' ) ).
    IF rs_box-align IS INITIAL.
      rs_box-align = 'center'.
    ENDIF.
    IF style_prop( iv_style = lv_style iv_name = 'font-weight' ) CS 'bold'.
      rs_box-bold = abap_true.
    ENDIF.
    rs_box-face = style_prop( iv_style = lv_style iv_name = 'font-family' ).
    rs_box-valign = 'middle'.
  ENDMETHOD.


  METHOD pdf_color.
    DATA lv_hex TYPE string.
    DATA lv_r TYPE i.
    DATA lv_g TYPE i.
    DATA lv_b TYPE i.

    lv_hex = to_lower( iv_value ).
    SHIFT lv_hex LEFT DELETING LEADING space.
    IF lv_hex IS INITIAL OR lv_hex CS 'transparent'.
      RETURN.
    ENDIF.
    DATA(lv_hash) = find( val = lv_hex sub = '#' ).
    IF lv_hash < 0.
      RETURN.
    ENDIF.
    lv_hex = substring( val = lv_hex off = lv_hash + 1 ).
    IF strlen( lv_hex ) >= 6.
      lv_hex = substring( val = lv_hex len = 6 ).
    ELSEIF strlen( lv_hex ) >= 3.
      lv_hex = substring( val = lv_hex off = 0 len = 1 ) && substring( val = lv_hex off = 0 len = 1 ) &&
        substring( val = lv_hex off = 1 len = 1 ) && substring( val = lv_hex off = 1 len = 1 ) &&
        substring( val = lv_hex off = 2 len = 1 ) && substring( val = lv_hex off = 2 len = 1 ).
    ELSE.
      RETURN.
    ENDIF.
    IF lv_hex CN '0123456789abcdef'.
      RETURN.
    ENDIF.
    lv_r = nibble( substring( val = lv_hex off = 0 len = 1 ) ) * 16
      + nibble( substring( val = lv_hex off = 1 len = 1 ) ).
    lv_g = nibble( substring( val = lv_hex off = 2 len = 1 ) ) * 16
      + nibble( substring( val = lv_hex off = 3 len = 1 ) ).
    lv_b = nibble( substring( val = lv_hex off = 4 len = 1 ) ) * 16
      + nibble( substring( val = lv_hex off = 5 len = 1 ) ).
    rv_rgb = num2( CONV decfloat34( lv_r ) / 255 ) && ` ` &&
      num2( CONV decfloat34( lv_g ) / 255 ) && ` ` &&
      num2( CONV decfloat34( lv_b ) / 255 ).
  ENDMETHOD.


  METHOD nibble.
    CASE to_lower( iv_ch ).
      WHEN '0'. rv_n = 0.
      WHEN '1'. rv_n = 1.
      WHEN '2'. rv_n = 2.
      WHEN '3'. rv_n = 3.
      WHEN '4'. rv_n = 4.
      WHEN '5'. rv_n = 5.
      WHEN '6'. rv_n = 6.
      WHEN '7'. rv_n = 7.
      WHEN '8'. rv_n = 8.
      WHEN '9'. rv_n = 9.
      WHEN 'a'. rv_n = 10.
      WHEN 'b'. rv_n = 11.
      WHEN 'c'. rv_n = 12.
      WHEN 'd'. rv_n = 13.
      WHEN 'e'. rv_n = 14.
      WHEN 'f'. rv_n = 15.
      WHEN OTHERS. rv_n = 0.
    ENDCASE.
  ENDMETHOD.


  METHOD face_name.
    DATA lv_family TYPE string.
    DATA lv_base TYPE string.
    lv_family = to_lower( is_box-face ).
    lv_base = zcl_abappdf_config=>font_helvetica.
    IF lv_family CS zcl_abappdf_config=>family_times OR lv_family CS zcl_abappdf_config=>family_georgia.
      lv_base = zcl_abappdf_config=>font_times.
    ELSEIF lv_family CS zcl_abappdf_config=>family_courier.
      lv_base = zcl_abappdf_config=>font_courier.
    ENDIF.
    IF lv_base = zcl_abappdf_config=>font_times.
      IF is_box-bold = abap_true AND is_box-italic = abap_true.
        rv_face = zcl_abappdf_config=>font_times_bold_italic.
      ELSEIF is_box-bold = abap_true.
        rv_face = zcl_abappdf_config=>font_times_bold.
      ELSEIF is_box-italic = abap_true.
        rv_face = zcl_abappdf_config=>font_times_italic.
      ELSE.
        rv_face = zcl_abappdf_config=>font_times_roman.
      ENDIF.
      RETURN.
    ENDIF.
    IF lv_base = zcl_abappdf_config=>font_courier.
      IF is_box-bold = abap_true AND is_box-italic = abap_true.
        rv_face = zcl_abappdf_config=>font_courier_bold_oblique.
      ELSEIF is_box-bold = abap_true.
        rv_face = zcl_abappdf_config=>font_courier_bold.
      ELSEIF is_box-italic = abap_true.
        rv_face = zcl_abappdf_config=>font_courier_oblique.
      ELSE.
        rv_face = zcl_abappdf_config=>font_courier.
      ENDIF.
      RETURN.
    ENDIF.
    IF is_box-bold = abap_true AND is_box-italic = abap_true.
      rv_face = zcl_abappdf_config=>font_helvetica_bold_oblique.
    ELSEIF is_box-bold = abap_true.
      rv_face = zcl_abappdf_config=>font_helvetica_bold.
    ELSEIF is_box-italic = abap_true.
      rv_face = zcl_abappdf_config=>font_helvetica_oblique.
    ELSE.
      rv_face = zcl_abappdf_config=>font_helvetica.
    ENDIF.
  ENDMETHOD.


  METHOD num2.
    DATA lv_value TYPE p LENGTH 16 DECIMALS 4.
    DATA lv_scaled TYPE p LENGTH 16 DECIMALS 2.
    DATA lv_neg TYPE abap_bool.
    DATA lv_whole TYPE i.
    DATA lv_frac TYPE i.
    lv_value = iv_value.
    IF lv_value < 0.
      lv_neg = abap_true.
      lv_value = - lv_value.
    ENDIF.
    lv_scaled = lv_value.
    lv_whole = trunc( lv_scaled ).
    lv_frac = ( lv_scaled - lv_whole ) * 100.
    IF lv_frac >= 100.
      lv_whole = lv_whole + 1.
      lv_frac = lv_frac - 100.
    ENDIF.
    rv_text = |{ lv_whole }.{ lv_frac WIDTH = 2 ALIGN = RIGHT PAD = '0' }|.
    CONDENSE rv_text NO-GAPS.
    IF lv_neg = abap_true AND lv_scaled <> 0.
      rv_text = '-' && rv_text.
    ENDIF.
  ENDMETHOD.


  METHOD pdf_escape.
    "Standard fonts use WinAnsiEncoding: ASCII as is, Latin-1 letters and signs
    "(U+00A0 to U+00FF, e.g. the middle dot) as octal escapes, anything else as '?'.
    DATA lv_len TYPE i.
    DATA lv_i TYPE i.
    DATA lv_ch TYPE string.
    DATA lv_x TYPE xstring.
    DATA lv_b1 TYPE x LENGTH 1.
    DATA lv_b2 TYPE x LENGTH 1.
    DATA lv_code TYPE i.
    DATA lv_oct TYPE string.
    lv_len = strlen( iv_text ).
    DO lv_len TIMES.
      lv_i = sy-index - 1.
      lv_ch = substring( val = iv_text off = lv_i len = 1 ).
      lv_x = cl_abap_conv_codepage=>create_out( codepage = 'UTF-8' )->convert( lv_ch ).
      IF xstrlen( lv_x ) = 2.
        lv_b1 = lv_x(1).
        lv_b2 = lv_x+1(1).
        IF lv_b1 = 'C2' OR lv_b1 = 'C3'.
          lv_code = lv_b2.
          IF lv_b1 = 'C3'.
            lv_code = lv_code + 64.
          ENDIF.
          IF lv_code >= 160.
            lv_oct = |\\{ lv_code DIV 64 }{ ( lv_code MOD 64 ) DIV 8 }{ lv_code MOD 8 }|.
            rv_text = rv_text && lv_oct.
            CONTINUE.
          ENDIF.
        ENDIF.
      ENDIF.
      IF xstrlen( lv_x ) <> 1.
        rv_text = rv_text && '?'.
        CONTINUE.
      ENDIF.
      IF lv_ch = '\' OR lv_ch = '(' OR lv_ch = ')'.
        rv_text = rv_text && '\' && lv_ch.
      ELSE.
        rv_text = rv_text && lv_ch.
      ENDIF.
    ENDDO.
  ENDMETHOD.


  METHOD draw_box.
    DATA lv_x TYPE decfloat34.
    DATA lv_y TYPE decfloat34.
    DATA lv_w TYPE decfloat34.
    DATA lv_h TYPE decfloat34.
    DATA lv_face TYPE i VALUE 1.
    DATA lv_text TYPE string.
    DATA lt_lines TYPE string_table.
    DATA lv_line TYPE string.
    DATA lv_idx TYPE i.
    DATA lv_text_w TYPE decfloat34.
    DATA lv_text_x TYPE decfloat34.
    DATA lv_base TYPE decfloat34.
    DATA lv_size TYPE decfloat34.
    DATA lv_nl TYPE string.
    DATA lv_color TYPE string.
    DATA lv_bar_h TYPE decfloat34.
    DATA lv_ar TYPE i.
    DATA lv_hex TYPE string.
    DATA lv_arabic TYPE abap_bool.
    DATA lv_top TYPE decfloat34.
    lv_nl = cl_abap_char_utilities=>newline.
    lv_x = px_to_pt( is_box-x ).
    lv_w = px_to_pt( is_box-w ).
    lv_h = px_to_pt( is_box-h ).
    IF lv_w < 1.
      lv_w = 1.
    ENDIF.
    IF lv_h < 1.
      lv_h = 1.
    ENDIF.
    lv_y = iv_page_h - px_to_pt( is_box-y ) - lv_h.
    lv_size = is_box-size.
    IF lv_size <= 0.
      lv_size = 12.
    ENDIF.
    READ TABLE it_faces TRANSPORTING NO FIELDS WITH KEY table_line = face_name( is_box ).
    IF sy-subrc = 0.
      lv_face = sy-tabix.
    ENDIF.
    rv_ops = |q{ lv_nl }{ num2( lv_x ) } { num2( lv_y ) } { num2( lv_w ) } { num2( lv_h ) } re W n{ lv_nl }|.
    IF is_box-fill IS NOT INITIAL.
      rv_ops = rv_ops && is_box-fill && | rg{ lv_nl }| &&
        |{ num2( lv_x ) } { num2( lv_y ) } { num2( lv_w ) } { num2( lv_h ) } re f{ lv_nl }|.
    ENDIF.
    lv_bar_h = lv_h.
    IF is_box-code = 'qr' OR is_box-code = 'code128'.
      IF is_box-code = 'code128' AND is_box-hr = abap_true.
        lv_bar_h = lv_h - lv_size * '1.4'.
        IF lv_bar_h < 4.
          lv_bar_h = lv_h.
        ENDIF.
      ENDIF.
      rv_ops = rv_ops && code_ops(
        is_box = is_box
        iv_x   = lv_x
        iv_y   = lv_y + lv_h - lv_bar_h
        iv_w   = lv_w
        iv_h   = lv_bar_h ).
    ENDIF.
    lv_text = is_box-text.
    IF is_box-code = 'qr' OR ( is_box-code = 'code128' AND is_box-hr = abap_false ).
      CLEAR lv_text.
    ENDIF.
    IF is_box-footer = abap_true AND to_upper( lv_text ) CS 'PAGE'.
      lv_text = |Page { iv_page_no } / { iv_page_count }|.
    ENDIF.
    IF lv_text IS NOT INITIAL.
      IF is_box-color IS INITIAL.
        lv_color = '0.07 0.07 0.07'.
      ELSE.
        lv_color = is_box-color.
      ENDIF.
      IF is_box-code IS INITIAL.
        lt_lines = wrap_text(
          iv_text  = lv_text
          iv_size  = lv_size
          iv_face  = face_name( is_box )
          iv_width = lv_w - 4 ).
      ELSE.
        SPLIT lv_text AT cl_abap_char_utilities=>newline INTO TABLE lt_lines.
      ENDIF.
      CLEAR lv_top.
      IF is_box-valign = 'middle'.
        lv_top = ( lv_h - lines( lt_lines ) * lv_size * '1.2' ) / 2 - 2 + lv_size * '0.1'.
        IF lv_top < 0.
          lv_top = 0.
        ENDIF.
      ENDIF.
      READ TABLE it_faces WITH KEY table_line = zcl_abappdf_config=>font_arabic TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        lv_ar = sy-tabix.
      ENDIF.
      rv_ops = rv_ops && |BT { lv_color } rg{ lv_nl }|.
      LOOP AT lt_lines INTO lv_line.
        lv_idx = sy-tabix - 1.
        CLEAR lv_hex.
        lv_arabic = abap_false.
        IF lv_ar > 0 AND zcl_abappdf_font=>contains( lv_line ) = abap_true.
          lv_hex = zcl_abappdf_font=>glyphs( lv_line ).
          IF lv_hex IS NOT INITIAL.
            lv_arabic = abap_true.
            lv_text_w = zcl_abappdf_font=>advance( iv_text = lv_line iv_size = lv_size ).
          ENDIF.
        ENDIF.
        IF lv_arabic = abap_false.
          lv_text_w = text_width( iv_text = lv_line iv_size = lv_size iv_face = face_name( is_box ) ).
        ENDIF.
        IF is_box-align = 'center'.
          lv_text_x = lv_x + ( lv_w - lv_text_w ) / 2.
        ELSEIF is_box-align = 'right' OR lv_arabic = abap_true.
          lv_text_x = lv_x + lv_w - lv_text_w - 2.
        ELSE.
          lv_text_x = lv_x + 2.
        ENDIF.
        IF lv_text_x < lv_x.
          lv_text_x = lv_x.
        ENDIF.
        IF is_box-code = 'code128' AND is_box-hr = abap_true.
          lv_base = lv_y + lv_size * '0.15'.
        ELSE.
          lv_base = lv_y + lv_h - 2 - lv_top - lv_size * ( lv_idx * '1.2' + '0.9' ).
        ENDIF.
        IF lv_arabic = abap_true.
          rv_ops = rv_ops && |/F{ lv_ar } { num2( lv_size ) } Tf 1 0 0 1 { num2( lv_text_x ) } { num2( lv_base ) } Tm <{ lv_hex }> Tj{ lv_nl }|.
        ELSE.
          rv_ops = rv_ops && |/F{ lv_face } { num2( lv_size ) } Tf 1 0 0 1 { num2( lv_text_x ) } { num2( lv_base ) } Tm ({ pdf_escape( lv_line ) }) Tj{ lv_nl }|.
        ENDIF.
      ENDLOOP.
      rv_ops = rv_ops && |ET{ lv_nl }|.
    ENDIF.
    IF is_box-border_w > 0 AND is_box-border IS NOT INITIAL.
      rv_ops = rv_ops && is_box-border && | RG { num2( px_to_pt( is_box-border_w ) ) } w{ lv_nl }| &&
        |{ num2( lv_x ) } { num2( lv_y ) } { num2( lv_w ) } { num2( lv_h ) } re S{ lv_nl }|.
    ENDIF.
    rv_ops = rv_ops && |Q{ lv_nl }|.
  ENDMETHOD.


  METHOD html_attr.
    DATA lv_key TYPE string.
    DATA lv_at TYPE i.
    DATA lv_end TYPE i.
    lv_key = | { iv_name }="|.
    lv_at = find( val = iv_tag sub = lv_key ).
    IF lv_at < 0.
      lv_key = |{ iv_name }="|.
      lv_at = find( val = iv_tag sub = lv_key ).
      IF lv_at < 0.
        RETURN.
      ENDIF.
    ENDIF.
    lv_at = lv_at + strlen( lv_key ).
    lv_end = find( val = iv_tag sub = '"' off = lv_at ).
    IF lv_end > lv_at.
      rv_value = substring( val = iv_tag off = lv_at len = lv_end - lv_at ).
    ENDIF.
  ENDMETHOD.


  METHOD code_ops.
    DATA lv_color TYPE string.
    DATA lv_nl TYPE string.
    DATA lt_rows TYPE zcl_abappdf_codes=>ty_rows.
    DATA lv_row TYPE string.
    DATA lv_n TYPE i.
    DATA lv_side TYPE decfloat34.
    DATA lv_mod TYPE decfloat34.
    DATA lv_ox TYPE decfloat34.
    DATA lv_top TYPE decfloat34.
    DATA lv_x TYPE i.
    DATA lv_run TYPE i.
    DATA lv_rx TYPE decfloat34.
    DATA lv_ry TYPE decfloat34.
    DATA lv_widths TYPE string.
    DATA lv_total TYPE i.
    DATA lv_i TYPE i.
    DATA lv_w TYPE i.
    DATA lv_at TYPE i.
    DATA lv_bar TYPE abap_bool VALUE abap_true.
    lv_nl = cl_abap_char_utilities=>newline.
    IF is_box-text IS INITIAL.
      RETURN.
    ENDIF.
    IF is_box-color IS INITIAL.
      lv_color = '0 0 0'.
    ELSE.
      lv_color = is_box-color.
    ENDIF.
    rv_ops = lv_color && | rg{ lv_nl }|.
    IF is_box-code = 'qr'.
      lt_rows = zcl_abappdf_codes=>qr( iv_text = is_box-text iv_level = is_box-ecc ).
      lv_n = lines( lt_rows ).
      IF lv_n = 0.
        RETURN.
      ENDIF.
      lv_side = lv_n + 8.
      lv_mod = iv_w / lv_side.
      IF iv_h / lv_side < lv_mod.
        lv_mod = iv_h / lv_side.
      ENDIF.
      lv_ox = iv_x + ( iv_w - lv_side * lv_mod ) / 2.
      lv_top = iv_y + iv_h - ( iv_h - lv_side * lv_mod ) / 2.
      LOOP AT lt_rows INTO lv_row.
        lv_x = 0.
        WHILE lv_x < lv_n.
          IF substring( val = lv_row off = lv_x len = 1 ) = '1'.
            lv_run = 0.
            WHILE lv_x + lv_run < lv_n.
              IF substring( val = lv_row off = lv_x + lv_run len = 1 ) <> '1'.
                EXIT.
              ENDIF.
              lv_run = lv_run + 1.
            ENDWHILE.
            lv_rx = lv_ox + ( lv_x + 4 ) * lv_mod.
            lv_ry = lv_top - ( sy-tabix + 4 ) * lv_mod.
            rv_ops = rv_ops && |{ num2( lv_rx ) } { num2( lv_ry ) } | &&
              |{ num2( lv_run * lv_mod ) } { num2( lv_mod ) } re f{ lv_nl }|.
            lv_x = lv_x + lv_run.
          ELSE.
            lv_x = lv_x + 1.
          ENDIF.
        ENDWHILE.
      ENDLOOP.
      RETURN.
    ENDIF.
    lv_widths = zcl_abappdf_codes=>code128( is_box-text ).
    lv_i = 0.
    WHILE lv_i < strlen( lv_widths ).
      lv_total = lv_total + CONV i( substring( val = lv_widths off = lv_i len = 1 ) ).
      lv_i = lv_i + 1.
    ENDWHILE.
    IF lv_total = 0.
      RETURN.
    ENDIF.
    lv_mod = iv_w / ( lv_total + 20 ).
    lv_i = 0.
    WHILE lv_i < strlen( lv_widths ).
      lv_w = CONV i( substring( val = lv_widths off = lv_i len = 1 ) ).
      IF lv_bar = abap_true.
        lv_rx = iv_x + ( lv_at + 10 ) * lv_mod.
        rv_ops = rv_ops && |{ num2( lv_rx ) } { num2( iv_y ) } | &&
          |{ num2( lv_w * lv_mod ) } { num2( iv_h ) } re f{ lv_nl }|.
      ENDIF.
      lv_at = lv_at + lv_w.
      lv_bar = xsdbool( lv_bar = abap_false ).
      lv_i = lv_i + 1.
    ENDWHILE.
  ENDMETHOD.


  METHOD assemble.
    DATA lt_objects TYPE string_table.
    DATA lv_obj TYPE string.
    DATA lv_kids TYPE string.
    DATA lv_fonts TYPE string.
    DATA lv_page TYPE string.
    DATA lv_first_font TYPE i.
    DATA lv_p TYPE i.
    DATA lv_i TYPE i.
    DATA lv_face TYPE string.
    DATA lv_header TYPE string.
    DATA lv_body TYPE string.
    DATA lv_xref TYPE string.
    DATA lv_nl TYPE string.
    DATA lv_offset TYPE i.
    DATA lv_pad TYPE string.
    DATA lt_id TYPE STANDARD TABLE OF i WITH EMPTY KEY.
    DATA lv_id TYPE i.
    DATA lv_next TYPE i.
    DATA lt_font TYPE string_table.
    lv_nl = cl_abap_char_utilities=>newline.
    lv_first_font = 3 + lines( it_pages ) * 2.
    lv_next = lv_first_font.
    LOOP AT it_faces INTO lv_face.
      APPEND lv_next TO lt_id.
      IF lv_face = zcl_abappdf_config=>font_arabic.
        lv_next = lv_next + zcl_abappdf_font=>object_count.
      ELSE.
        lv_next = lv_next + 1.
      ENDIF.
    ENDLOOP.
    DO lines( it_pages ) TIMES.
      lv_kids = lv_kids && |{ 3 + ( sy-index - 1 ) * 2 } 0 R |.
    ENDDO.
    lv_i = 0.
    LOOP AT it_faces INTO lv_face.
      lv_i = lv_i + 1.
      READ TABLE lt_id INDEX lv_i INTO lv_id.
      lv_fonts = lv_fonts && |/F{ lv_i } { lv_id } 0 R |.
    ENDLOOP.
    APPEND |1 0 obj{ lv_nl }<< /Type /Catalog /Pages 2 0 R >>{ lv_nl }endobj{ lv_nl }| TO lt_objects.
    APPEND |2 0 obj{ lv_nl }<< /Type /Pages /Kids [{ lv_kids }] /Count { lines( it_pages ) } >>{ lv_nl }endobj{ lv_nl }| TO lt_objects.
    lv_p = 0.
    LOOP AT it_pages INTO lv_page.
      APPEND |{ 3 + lv_p * 2 } 0 obj{ lv_nl }<< /Type /Page /Parent 2 0 R /MediaBox [0 0 { num2( iv_width ) } { num2( iv_height ) }] /Contents { 4 + lv_p * 2 } 0 R /Resources << /Font << { lv_fonts } >> >> >>{ lv_nl }endobj{ lv_nl }| TO lt_objects.
      APPEND |{ 4 + lv_p * 2 } 0 obj{ lv_nl }<< /Length { strlen( lv_page ) } >>{ lv_nl }stream{ lv_nl }{ lv_page }endstream{ lv_nl }endobj{ lv_nl }| TO lt_objects.
      lv_p = lv_p + 1.
    ENDLOOP.
    lv_i = 0.
    LOOP AT it_faces INTO lv_face.
      lv_i = lv_i + 1.
      READ TABLE lt_id INDEX lv_i INTO lv_id.
      IF lv_face = zcl_abappdf_config=>font_arabic.
        lt_font = zcl_abappdf_font=>objects( lv_id ).
        APPEND LINES OF lt_font TO lt_objects.
      ELSE.
        APPEND |{ lv_id } 0 obj{ lv_nl }<< /Type /Font /Subtype /Type1 /BaseFont /{ lv_face } /Encoding /WinAnsiEncoding >>{ lv_nl }endobj{ lv_nl }| TO lt_objects.
      ENDIF.
    ENDLOOP.
    lv_header = |%PDF-1.4{ lv_nl }|.
    lv_xref = |xref{ lv_nl }0 { lines( lt_objects ) + 1 }{ lv_nl }0000000000 65535 f { lv_nl }|.
    CLEAR lv_body.
    LOOP AT lt_objects INTO lv_obj.
      lv_offset = strlen( lv_header ) + strlen( lv_body ).
      lv_pad = |{ lv_offset }|.
      WHILE strlen( lv_pad ) < 10.
        lv_pad = '0' && lv_pad.
      ENDWHILE.
      lv_xref = lv_xref && lv_pad && | 00000 n { lv_nl }|.
      lv_body = lv_body && lv_obj.
    ENDLOOP.
    DATA(lv_xref_at) = strlen( lv_header ) + strlen( lv_body ).
    rv_pdf = cl_abap_conv_codepage=>create_out( )->convert(
      lv_header && lv_body && lv_xref &&
      |trailer{ lv_nl }<< /Size { lines( lt_objects ) + 1 } /Root 1 0 R >>{ lv_nl }startxref{ lv_nl }{ lv_xref_at }{ lv_nl }%%EOF| ).
  ENDMETHOD.

ENDCLASS.
