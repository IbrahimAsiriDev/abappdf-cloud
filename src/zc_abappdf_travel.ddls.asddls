@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'abapPDF travel preview'
@Metadata.allowExtensions: true
define root view entity ZC_ABAPPDF_TRAVEL
  provider contract transactional_query
  as projection on ZI_ABAPPDF_TRAVEL
{
  key travel_id,
      agency_id,
      customer_id,
      begin_date,
      end_date,
      booking_fee,
      total_price,
      currency_code,
      description,
      status,
      pdf_filename,
      @Semantics.mimeType: true
      pdf_mimetype,
      @Semantics.largeObject: {
        mimeType: 'pdf_mimetype',
        fileName: 'pdf_filename',
        contentDispositionPreference: #INLINE
      }
      pdf_content,
      print_url,
      print_label,
      _Booking : redirected to composition child ZC_ABAPPDF_BOOKING
}
