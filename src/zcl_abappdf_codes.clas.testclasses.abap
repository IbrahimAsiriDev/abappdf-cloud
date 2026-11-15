CLASS ltcl_codes DEFINITION FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS qr_hello FOR TESTING RAISING zcx_abappdf.
    METHODS code128_digits FOR TESTING.
    METHODS expand_qr FOR TESTING RAISING zcx_abappdf.
ENDCLASS.

CLASS ltcl_codes IMPLEMENTATION.

  METHOD qr_hello.
    DATA(lt_rows) = zcl_abappdf_codes=>qr( iv_text = 'HELLO' iv_level = 'M' ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_rows ) exp = 21 ).
    cl_abap_unit_assert=>assert_equals(
      act = strlen( lt_rows[ 1 ] )
      exp = 21 ).
    cl_abap_unit_assert=>assert_equals(
      act = substring( val = lt_rows[ 1 ] len = 7 )
      exp = '1111111' ).
  ENDMETHOD.

  METHOD code128_digits.
    DATA(lv_widths) = zcl_abappdf_codes=>code128( 'HI' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( strlen( lv_widths ) > 7 ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_widths CO '1234' ) ).
    cl_abap_unit_assert=>assert_equals(
      act = substring( val = lv_widths off = strlen( lv_widths ) - 7 len = 7 )
      exp = '2331112' ).
  ENDMETHOD.

  METHOD expand_qr.
    DATA(lv_html) = zcl_abappdf_codes=>expand_html(
      '<div data-code="qr" data-ecc="M">HELLO</div>' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '<svg' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '<path' ) ).
  ENDMETHOD.

ENDCLASS.
