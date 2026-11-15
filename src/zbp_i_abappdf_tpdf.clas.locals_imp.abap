CLASS lhc_pdf DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Pdf RESULT result.
ENDCLASS.

CLASS lhc_pdf IMPLEMENTATION.

  METHOD get_global_authorizations.
    result-%create = if_abap_behv=>auth-allowed.
    result-%update = if_abap_behv=>auth-allowed.
  ENDMETHOD.

ENDCLASS.
