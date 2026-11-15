CLASS lhc_travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Travel RESULT result.
    METHODS print FOR MODIFY
      IMPORTING keys FOR ACTION Travel~print RESULT result.
ENDCLASS.

CLASS lhc_travel IMPLEMENTATION.

  METHOD get_global_authorizations.
    result-%action-print = if_abap_behv=>auth-allowed.
  ENDMETHOD.

  METHOD print.
    DATA lt_failed TYPE STANDARD TABLE OF /dmo/travel_id WITH EMPTY KEY.
    DATA lv_pdf TYPE xstring.
    DATA lv_file TYPE string.
    DATA lt_exist TYPE TABLE FOR READ RESULT zi_abappdf_tpdf.
    DATA lt_create TYPE TABLE FOR CREATE zi_abappdf_tpdf.
    DATA lt_update TYPE TABLE FOR UPDATE zi_abappdf_tpdf.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      TRY.
          lv_pdf = zcl_abappdf_rap=>print( <key>-travel_id ).
          lv_file = |{ <key>-travel_id }.pdf|.
          CLEAR lt_exist.
          READ ENTITIES OF zi_abappdf_tpdf
            ENTITY Pdf
            ALL FIELDS WITH VALUE #( ( travel_id = <key>-travel_id ) )
            RESULT lt_exist.
          IF line_exists( lt_exist[ travel_id = <key>-travel_id ] ).
            APPEND VALUE #(
              travel_id = <key>-travel_id
              pdf_filename = lv_file
              pdf_mimetype = zcl_abappdf_config=>mime_pdf
              pdf_content = lv_pdf
              %control-pdf_filename = if_abap_behv=>mk-on
              %control-pdf_mimetype = if_abap_behv=>mk-on
              %control-pdf_content = if_abap_behv=>mk-on ) TO lt_update.
          ELSE.
            APPEND VALUE #(
              %cid = |{ <key>-travel_id }|
              travel_id = <key>-travel_id
              pdf_filename = lv_file
              pdf_mimetype = zcl_abappdf_config=>mime_pdf
              pdf_content = lv_pdf ) TO lt_create.
          ENDIF.
        CATCH zcx_abappdf INTO DATA(lx_pdf).
          APPEND <key>-travel_id TO lt_failed.
          APPEND VALUE #( %tky = <key>-%tky ) TO failed-travel.
          APPEND VALUE #(
            %tky = <key>-%tky
            %msg = new_message_with_text(
                     severity = if_abap_behv_message=>severity-error
                     text     = lx_pdf->get_text( ) ) ) TO reported-travel.
      ENDTRY.
    ENDLOOP.

    IF lt_create IS NOT INITIAL.
      MODIFY ENTITIES OF zi_abappdf_tpdf
        ENTITY Pdf
        CREATE FIELDS ( travel_id pdf_filename pdf_mimetype pdf_content )
        WITH lt_create.
    ENDIF.
    IF lt_update IS NOT INITIAL.
      MODIFY ENTITIES OF zi_abappdf_tpdf
        ENTITY Pdf
        UPDATE FIELDS ( pdf_filename pdf_mimetype pdf_content )
        WITH lt_update.
    ENDIF.

    READ ENTITIES OF zi_abappdf_travel IN LOCAL MODE
      ENTITY Travel
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_travel).

    LOOP AT lt_travel INTO DATA(ls_travel).
      IF line_exists( lt_failed[ table_line = ls_travel-travel_id ] ).
        CONTINUE.
      ENDIF.
      APPEND VALUE #(
        %tky   = ls_travel-%tky
        %param = CORRESPONDING #( ls_travel ) ) TO result.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
