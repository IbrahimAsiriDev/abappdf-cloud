CLASS ltcl_binder DEFINITION FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_sub,
        name TYPE string,
      END OF ty_sub,
      ty_subs TYPE STANDARD TABLE OF ty_sub WITH EMPTY KEY,
      BEGIN OF ty_item,
        material TYPE string,
        amount   TYPE string,
        subs     TYPE ty_subs,
      END OF ty_item,
      ty_items TYPE STANDARD TABLE OF ty_item WITH EMPTY KEY,
      BEGIN OF ty_root,
        note  TYPE string,
        name  TYPE string,
        items TYPE ty_items,
      END OF ty_root.

    METHODS each_and_if FOR TESTING RAISING zcx_abappdf.
    METHODS nested_each FOR TESTING RAISING zcx_abappdf.
    METHODS column_sum FOR TESTING RAISING zcx_abappdf.
    METHODS unknown_field FOR TESTING.
    METHODS html_escape FOR TESTING RAISING zcx_abappdf.
    METHODS saved_column_sum FOR TESTING RAISING zcx_abappdf.
    METHODS saved_column_sum_b64 FOR TESTING RAISING zcx_abappdf.
    METHODS aggregates FOR TESTING RAISING zcx_abappdf.
    METHODS number_and_date FOR TESTING RAISING zcx_abappdf.
    METHODS row_parity FOR TESTING RAISING zcx_abappdf.
ENDCLASS.

CLASS ltcl_binder IMPLEMENTATION.

  METHOD each_and_if.
    DATA ls_doc TYPE ty_root.
    DATA lv_html TYPE string.
    ls_doc-items = VALUE #(
      ( material = 'M-1' )
      ( material = 'M-2' ) ).
    lv_html = zcl_abappdf_binder=>render(
      iv_template = '{{#each ITEMS}}[{{MATERIAL}}]{{/each}}{{#if NOTE}}Y{{else}}N{{/if}}'
      is_data     = ls_doc ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_html
      exp = '[M-1][M-2]N' ).
  ENDMETHOD.

  METHOD nested_each.
    DATA ls_doc TYPE ty_root.
    DATA ls_item TYPE ty_item.
    DATA lv_html TYPE string.
    ls_item-material = 'MAT-1'.
    ls_item-subs = VALUE #( ( name = 'A' ) ( name = 'B' ) ).
    APPEND ls_item TO ls_doc-items.
    CLEAR ls_item.
    ls_item-material = 'MAT-2'.
    ls_item-subs = VALUE #( ( name = 'C' ) ).
    APPEND ls_item TO ls_doc-items.
    lv_html = zcl_abappdf_binder=>render(
      iv_template = '{{#each ITEMS}}{{ROW}}:{{MATERIAL}}{{#each SUBS}}({{ROW}}{{NAME}}){{/each}};{{/each}}'
      is_data     = ls_doc ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_html
      exp = '1:MAT-1(1A)(2B);2:MAT-2(1C);' ).
  ENDMETHOD.

  METHOD column_sum.
    DATA ls_doc TYPE ty_root.
    DATA lv_html TYPE string.
    APPEND VALUE #( amount = '50.00' ) TO ls_doc-items.
    APPEND VALUE #( amount = '91.00' ) TO ls_doc-items.
    APPEND VALUE #( amount = '16.25' ) TO ls_doc-items.
    APPEND VALUE #( amount = '22.00' ) TO ls_doc-items.
    lv_html = zcl_abappdf_binder=>render(
      iv_template = '{{#each ITEMS}}{{AMOUNT}}{{/each}} {{#sum ITEMS.AMOUNT}}'
      is_data     = ls_doc ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_html
      exp = '50.0091.0016.2522.00 179.25' ).
  ENDMETHOD.

  METHOD unknown_field.
    DATA ls_doc TYPE ty_root.
    ls_doc-name = 'ACME'.
    TRY.
        zcl_abappdf_binder=>render(
          iv_template = '{{MISSING}}'
          is_data     = ls_doc ).
        cl_abap_unit_assert=>fail( msg = 'Unknown field must raise' ).
      CATCH zcx_abappdf INTO DATA(lx_error).
        cl_abap_unit_assert=>assert_equals(
          act = lx_error->get_text( )
          exp = 'Unknown template field: MISSING' ).
    ENDTRY.
  ENDMETHOD.

  METHOD html_escape.
    DATA ls_doc TYPE ty_root.
    ls_doc-name = '<A&B>"'''.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_abappdf_binder=>render( iv_template = '{{NAME}}' is_data = ls_doc )
      exp = '&lt;A&amp;B&gt;&quot;&#39;' ).
  ENDMETHOD.

  METHOD saved_column_sum.
    DATA ls_doc TYPE ty_root.
    DATA lv_html TYPE string.
    DATA lv_template TYPE string.
    APPEND VALUE #( amount = '50.00' ) TO ls_doc-items.
    APPEND VALUE #( amount = '91.00' ) TO ls_doc-items.
    APPEND VALUE #( amount = '16.25' ) TO ls_doc-items.
    APPEND VALUE #( amount = '22.00' ) TO ls_doc-items.
    lv_template = '<!--abappdf:{"widgets":[{"text":"{{AMOUNT}}","dataPath":"ITEMS","sum":1}]}-->' &&
      '{{#each ITEMS}}{{AMOUNT}}{{/each}}<div>0</div>'.
    lv_html = zcl_abappdf_binder=>render(
      iv_template = lv_template
      is_data     = ls_doc ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_html
      exp = '50.0091.0016.2522.00<div>179.25</div>' ).
  ENDMETHOD.

  METHOD saved_column_sum_b64.
    " Same model as saved_column_sum, base64url encoded the way the designer saves it.
    DATA ls_doc TYPE ty_root.
    DATA lv_html TYPE string.
    APPEND VALUE #( amount = '50.00' ) TO ls_doc-items.
    APPEND VALUE #( amount = '91.00' ) TO ls_doc-items.
    APPEND VALUE #( amount = '16.25' ) TO ls_doc-items.
    APPEND VALUE #( amount = '22.00' ) TO ls_doc-items.
    lv_html = zcl_abappdf_binder=>render(
      iv_template = '<!--abappdf64:eyJ3aWRnZXRzIjpbeyJ0ZXh0Ijoie3tBTU9VTlR9fSIsImRhdGFQYXRoIjoiSVRFTVMiLCJzdW0iOjF9XX0-->' &&
        '{{#each ITEMS}}{{AMOUNT}}{{/each}}<div>0</div>'
      is_data     = ls_doc ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_html
      exp = '50.0091.0016.2522.00<div>179.25</div>' ).
  ENDMETHOD.

  METHOD aggregates.
    DATA ls_doc TYPE ty_root.
    DATA lv_html TYPE string.
    APPEND VALUE #( amount = '50.00' ) TO ls_doc-items.
    APPEND VALUE #( amount = '91.00' ) TO ls_doc-items.
    APPEND VALUE #( amount = '16.25' ) TO ls_doc-items.
    APPEND VALUE #( amount = '22.00' ) TO ls_doc-items.
    lv_html = zcl_abappdf_binder=>render(
      iv_template = '{{count ITEMS}}|{{sum ITEMS.AMOUNT}}|{{min ITEMS.AMOUNT}}|{{max ITEMS.AMOUNT}}|{{avg ITEMS.AMOUNT}}'
      is_data     = ls_doc ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_html
      exp = '4|179.25|16.25|91.00|44.81' ).
  ENDMETHOD.

  METHOD number_and_date.
    DATA ls_doc TYPE ty_root.
    DATA lv_html TYPE string.
    ls_doc-note = '17012026'.
    APPEND VALUE #( amount = '1234.5' ) TO ls_doc-items.
    lv_html = zcl_abappdf_binder=>render(
      iv_template = '<span data-fmt="YYYY-MM-DD">{{NOTE}}</span>' &&
        '{{#each ITEMS}}<span data-fmt="#,##0.00">{{AMOUNT}}</span>{{/each}}'
      is_data     = ls_doc ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_html
      exp = '<span data-fmt="YYYY-MM-DD">2026-01-17</span><span data-fmt="#,##0.00">1,234.50</span>' ).
  ENDMETHOD.

  METHOD row_parity.
    DATA ls_doc TYPE ty_root.
    DATA lv_html TYPE string.
    APPEND VALUE #( material = 'A' ) TO ls_doc-items.
    APPEND VALUE #( material = 'B' ) TO ls_doc-items.
    lv_html = zcl_abappdf_binder=>render(
      iv_template = '{{#each ITEMS}}{{#if ROW_EVEN}}E{{else}}O{{/if}}{{/each}}'
      is_data     = ls_doc ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_html
      exp = 'OE' ).
  ENDMETHOD.

ENDCLASS.
