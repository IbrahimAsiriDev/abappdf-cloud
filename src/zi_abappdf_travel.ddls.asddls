@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'abapPDF travel'
define root view entity ZI_ABAPPDF_TRAVEL
  as select from /dmo/travel as Travel
    left outer join zabappdf_tpdf as Pdf
      on Pdf.travel_id = Travel.travel_id
  composition [0..*] of ZI_ABAPPDF_BOOKING as _Booking
{
  key Travel.travel_id,
      Travel.agency_id,
      Travel.customer_id,
      Travel.begin_date,
      Travel.end_date,
      @Semantics.amount.currencyCode: 'currency_code'
      Travel.booking_fee,
      @Semantics.amount.currencyCode: 'currency_code'
      Travel.total_price,
      Travel.currency_code,
      Travel.description,
      Travel.status,
      Pdf.pdf_filename,
      @Semantics.mimeType: true
      Pdf.pdf_mimetype,
      @Semantics.largeObject: {
        mimeType: 'pdf_mimetype',
        fileName: 'pdf_filename',
        contentDispositionPreference: #INLINE
      }
      Pdf.pdf_content,
      concat(
        '/sap/bc/http/sap/zabappdf_http/print/',
        cast( Travel.travel_id as abap.char( 8 ) ) ) as print_url,
      cast( 'PDF' as abap.char( 3 ) ) as print_label,
      _Booking
}
