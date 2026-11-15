CLASS zcl_abappdf_tr DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_request,
        request     TYPE string,
        description TYPE string,
      END OF ty_request,
      ty_requests TYPE STANDARD TABLE OF ty_request WITH EMPTY KEY.

    CLASS-METHODS list_requests
      RETURNING
        VALUE(rt_requests) TYPE ty_requests
      RAISING
        zcx_abappdf.

    CLASS-METHODS requests_json
      RETURNING
        VALUE(rv_json) TYPE string
      RAISING
        zcx_abappdf.

    CLASS-METHODS record_form
      IMPORTING
        iv_form_id TYPE string
        iv_request TYPE string OPTIONAL
        iv_create  TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(rv_request) TYPE string
      RAISING
        zcx_abappdf.

  PRIVATE SECTION.
    CLASS-METHODS service_for
      IMPORTING
        iv_table          TYPE string
      RETURNING
        VALUE(ro_service) TYPE REF TO if_bcfg_cd_transport_service
      RAISING
        zcx_abappdf.

    CLASS-METHODS field_text
      IMPORTING
        is_row         TYPE any
        iv_kind        TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.

    CLASS-METHODS record_table
      IMPORTING
        iv_table   TYPE string
        iv_request TYPE string
        it_rows    TYPE ANY TABLE
      RETURNING
        VALUE(rv_task) TYPE string
      RAISING
        zcx_abappdf.
ENDCLASS.



CLASS zcl_abappdf_tr IMPLEMENTATION.

  METHOD list_requests.
    DATA lt_open TYPE if_bcfg_cd_transport_manager=>ty_t_transport.
    DATA ls_open TYPE if_bcfg_cd_transport_manager=>ty_transport.
    DATA ls_request TYPE ty_request.
    DATA(lo_manager) = service_for( 'ZABAPPDF_CONF' )->get_transport_request( ).
    TRY.
        lt_open = lo_manager->get_open_requests( ).
      CATCH cx_bcfg_transport_request INTO DATA(lx_list).
        RAISE EXCEPTION TYPE zcx_abappdf
          EXPORTING
            textid   = zcx_abappdf=>external_error
            previous = lx_list
            msgv1    = CONV symsgv( lx_list->get_text( ) )
            longtext = lx_list->get_text( ).
    ENDTRY.
    LOOP AT lt_open INTO ls_open.
      CLEAR ls_request.
      ls_request-request = field_text( is_row = ls_open iv_kind = 'ID' ).
      ls_request-description = field_text( is_row = ls_open iv_kind = 'TEXT' ).
      IF ls_request-request IS INITIAL.
        CONTINUE.
      ENDIF.
      IF ls_request-description IS INITIAL.
        ls_request-description = ls_request-request.
      ENDIF.
      APPEND ls_request TO rt_requests.
    ENDLOOP.
  ENDMETHOD.


  METHOD requests_json.
    DATA lv_sep TYPE string.
    rv_json = '['.
    LOOP AT list_requests( ) INTO DATA(ls_request).
      rv_json = rv_json && lv_sep &&
        |\{"request":"{ zcl_abappdf_json=>escape( ls_request-request ) }"| &&
        |,"description":"{ zcl_abappdf_json=>escape( ls_request-description ) }"\}|.
      lv_sep = ','.
    ENDLOOP.
    rv_json = rv_json && ']'.
  ENDMETHOD.


  METHOD record_form.
    DATA lt_forms TYPE STANDARD TABLE OF zabappdf_forms WITH EMPTY KEY.
    DATA lt_tmpl TYPE STANDARD TABLE OF zabappdf_tmpl WITH EMPTY KEY.
    DATA lv_request TYPE string.
    DATA(lv_id) = zcl_abappdf_forms=>normalize_id( iv_form_id ).
    zcl_abappdf_forms=>read_form( CONV string( lv_id ) ).
    SELECT * FROM zabappdf_forms WHERE form_id = @lv_id INTO TABLE @lt_forms.
    SELECT * FROM zabappdf_tmpl WHERE form_id = @lv_id INTO TABLE @lt_tmpl.
    lv_request = to_upper( iv_request ).
    CONDENSE lv_request NO-GAPS.
    IF lv_request IS INITIAL AND iv_create = abap_false.
      RAISE EXCEPTION TYPE zcx_abappdf EXPORTING textid = zcx_abappdf=>request_required.
    ENDIF.
    rv_request = record_table(
      iv_table   = 'ZABAPPDF_FORMS'
      iv_request = lv_request
      it_rows    = lt_forms ).
    IF lt_tmpl IS NOT INITIAL.
      record_table(
        iv_table   = 'ZABAPPDF_TMPL'
        iv_request = rv_request
        it_rows    = lt_tmpl ).
    ENDIF.
    IF rv_request IS INITIAL.
      rv_request = lv_request.
    ENDIF.
    zcl_abappdf_forms=>set_transport(
      iv_form_id = CONV string( lv_id )
      iv_request = rv_request ).
  ENDMETHOD.


  METHOD service_for.
    DATA lv_name TYPE cl_bcfg_cd_reuse_api_factory=>ty_object_name.
    lv_name = CONV #( iv_table ).
    TRY.
        ro_service = cl_bcfg_cd_reuse_api_factory=>get_transport_service_instance(
          iv_objectname = lv_name
          iv_objecttype = cl_bcfg_cd_reuse_api_factory=>simple_table ).
      CATCH cx_root INTO DATA(lx_service).
        RAISE EXCEPTION TYPE zcx_abappdf
          EXPORTING
            textid   = zcx_abappdf=>external_error
            previous = lx_service
            msgv1    = CONV symsgv( lx_service->get_text( ) )
            longtext = lx_service->get_text( ).
    ENDTRY.
    IF ro_service IS NOT BOUND.
      RAISE EXCEPTION TYPE zcx_abappdf EXPORTING textid = zcx_abappdf=>transport_unavailable msgv1 = CONV symsgv( iv_table ).
    ENDIF.
  ENDMETHOD.


  METHOD field_text.
    DATA lo_type TYPE REF TO cl_abap_typedescr.
    DATA lo_struct TYPE REF TO cl_abap_structdescr.
    DATA lo_field TYPE REF TO cl_abap_typedescr.
    DATA ls_comp TYPE abap_compdescr.
    DATA lv_name TYPE string.
    DATA lv_value TYPE string.
    DATA lv_first TYPE string.
    FIELD-SYMBOLS <field> TYPE any.

    lo_type = cl_abap_typedescr=>describe_by_data( is_row ).
    IF lo_type->kind <> cl_abap_typedescr=>kind_struct.
      RETURN.
    ENDIF.
    lo_struct = CAST cl_abap_structdescr( lo_type ).
    LOOP AT lo_struct->components INTO ls_comp.
      ASSIGN COMPONENT ls_comp-name OF STRUCTURE is_row TO <field>.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      lo_field = cl_abap_typedescr=>describe_by_data( <field> ).
      IF lo_field->kind <> cl_abap_typedescr=>kind_elem.
        CONTINUE.
      ENDIF.
      lv_value = condense( |{ <field> }| ).
      IF lv_value IS INITIAL.
        CONTINUE.
      ENDIF.
      IF lv_first IS INITIAL.
        lv_first = lv_value.
      ENDIF.
      lv_name = to_upper( ls_comp-name ).
      IF iv_kind = 'ID' AND ( lv_name CS 'REQUEST' OR lv_name CS 'TRKORR' OR lv_name = 'TASK' ).
        rv_text = lv_value.
        RETURN.
      ENDIF.
      IF iv_kind = 'TEXT' AND ( lv_name CS 'DESCR' OR lv_name CS 'TEXT' ).
        rv_text = lv_value.
        RETURN.
      ENDIF.
    ENDLOOP.
    IF iv_kind = 'ID'.
      rv_text = lv_first.
    ENDIF.
  ENDMETHOD.


  METHOD record_table.
    DATA lo_service TYPE REF TO if_bcfg_cd_transport_service.
    DATA lo_manager TYPE REF TO if_bcfg_cd_transport_manager.
    DATA lv_chosen TYPE if_bcfg_cd_transport_manager=>ty_transport_request.
    DATA lv_desc TYPE if_bcfg_cd_transport_manager=>ty_description.
    DATA lv_task TYPE if_bcfg_cd_transport_manager=>ty_task.

    lo_service = service_for( iv_table ).
    lo_manager = lo_service->get_transport_request( ).
    TRY.
        IF iv_request IS NOT INITIAL.
          lv_chosen = CONV #( iv_request ).
          lo_manager->set_transport( lv_chosen ).
        ELSE.
          lv_desc = |abapPDF { iv_table }|.
          lv_chosen = lo_manager->create( lv_desc ).
          lo_manager->set_transport( lv_chosen ).
        ENDIF.
        lo_service->get_transport_recorder( )->add_tabu_content( it_rows ).
        lv_task = lo_manager->get_task( ).
      CATCH cx_bcfg_transport_request cx_bcfg_transport_recorder INTO DATA(lx_record).
        RAISE EXCEPTION TYPE zcx_abappdf
          EXPORTING
            textid   = zcx_abappdf=>external_error
            previous = lx_record
            msgv1    = CONV symsgv( lx_record->get_text( ) )
            longtext = lx_record->get_text( ).
    ENDTRY.
    IF lv_chosen IS NOT INITIAL.
      rv_task = CONV string( lv_chosen ).
    ELSEIF lv_task IS NOT INITIAL.
      rv_task = CONV string( lv_task ).
    ELSE.
      rv_task = iv_request.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
