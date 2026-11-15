INTERFACE zif_abappdf_data
  PUBLIC.

  METHODS read
    IMPORTING
      iv_key         TYPE string
    RETURNING
      VALUE(rv_json) TYPE string
    RAISING
      zcx_abappdf.
ENDINTERFACE.
