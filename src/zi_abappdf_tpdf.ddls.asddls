@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Stored travel PDF'
define root view entity ZI_ABAPPDF_TPDF
  as select from zabappdf_tpdf
{
  key travel_id,
      pdf_filename,
      @Semantics.mimeType: true
      pdf_mimetype,
      @Semantics.largeObject: {
        mimeType: 'pdf_mimetype',
        fileName: 'pdf_filename',
        contentDispositionPreference: #INLINE
      }
      pdf_content
}
