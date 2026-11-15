CLASS zcl_abappdf_data DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    CLASS-METHODS read
      IMPORTING
        iv_source      TYPE string
        iv_key         TYPE string
      RETURNING
        VALUE(rv_json) TYPE string
      RAISING
        zcx_abappdf.

    CLASS-METHODS resolve
      IMPORTING
        iv_sample      TYPE string
        iv_key         TYPE string OPTIONAL
      RETURNING
        VALUE(rv_json) TYPE string
      RAISING
        zcx_abappdf.

  PRIVATE SECTION.
    CLASS-METHODS provider
      IMPORTING
        iv_class         TYPE string
      RETURNING
        VALUE(ro_source) TYPE REF TO zif_abappdf_data
      RAISING
        zcx_abappdf.
ENDCLASS.



CLASS zcl_abappdf_data IMPLEMENTATION.

  METHOD read.
    DATA lv_source TYPE string.
    DATA lv_bad TYPE abap_bool.

    lv_source = to_upper( iv_source ).
    IF lv_source IS INITIAL OR strlen( lv_source ) > 30.
      lv_bad = abap_true.
    ELSEIF lv_source CN 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_/'.
      lv_bad = abap_true.
    ENDIF.
    IF lv_bad = abap_true.
      RAISE EXCEPTION TYPE zcx_abappdf
        EXPORTING textid = zcx_abappdf=>source_unknown msgv1 = CONV symsgv( lv_source ).
    ENDIF.

    "Short name for the shipped demo source.
    IF lv_source = '/DMO/TRAVEL'.
      lv_source = 'ZCL_ABAPPDF_TRAVEL'.
    ENDIF.
    rv_json = provider( lv_source )->read( iv_key ).
  ENDMETHOD.


  METHOD provider.
    "A data source is any global class that implements ZIF_ABAPPDF_DATA and can be
    "created without parameters. Its READ method checks the caller's authorization.
    DATA lo_type TYPE REF TO cl_abap_typedescr.
    DATA lo_class TYPE REF TO cl_abap_classdescr.
    DATA lo_object TYPE REF TO object.

    cl_abap_typedescr=>describe_by_name(
      EXPORTING
        p_name         = iv_class
      RECEIVING
        p_descr_ref    = lo_type
      EXCEPTIONS
        type_not_found = 1
        OTHERS         = 2 ).
    IF sy-subrc = 0 AND lo_type->kind = cl_abap_typedescr=>kind_class.
      lo_class ?= lo_type.
      IF line_exists( lo_class->interfaces[ name = 'ZIF_ABAPPDF_DATA' ] ).
        TRY.
            CREATE OBJECT lo_object TYPE (iv_class).
            ro_source ?= lo_object.
            RETURN.
          CATCH cx_sy_create_object_error cx_sy_move_cast_error.
        ENDTRY.
      ENDIF.
    ENDIF.
    RAISE EXCEPTION TYPE zcx_abappdf
      EXPORTING textid = zcx_abappdf=>source_unknown msgv1 = CONV symsgv( iv_class ).
  ENDMETHOD.


  METHOD resolve.
    DATA lr_node TYPE REF TO data.
    DATA lv_source TYPE string.
    DATA lv_key TYPE string.

    rv_json = iv_sample.
    IF iv_sample IS INITIAL.
      RETURN.
    ENDIF.
    TRY.
        lr_node = zcl_abappdf_json=>parse( iv_sample ).
      CATCH zcx_abappdf.
        RETURN.
    ENDTRY.
    IF zcl_abappdf_json=>kind( lr_node ) <> 'O'.
      RETURN.
    ENDIF.
    lv_source = to_upper( zcl_abappdf_json=>text_of(
      zcl_abappdf_json=>member( ir_node = lr_node iv_name = 'source' ) ) ).
    IF lv_source IS INITIAL.
      RETURN.
    ENDIF.
    lv_key = to_upper( zcl_abappdf_json=>text_of(
      zcl_abappdf_json=>member( ir_node = lr_node iv_name = 'key' ) ) ).
    IF lv_key IS INITIAL.
      lv_key = iv_key.
    ENDIF.
    rv_json = read( iv_source = lv_source iv_key = lv_key ).
  ENDMETHOD.

ENDCLASS.
