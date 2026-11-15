@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'abapPDF booking preview'
@Metadata.allowExtensions: true
define view entity ZC_ABAPPDF_BOOKING
  as projection on ZI_ABAPPDF_BOOKING
{
  key travel_id,
  key booking_id,
      carrier_id,
      connection_id,
      flight_date,
      flight_price,
      currency_code,
      _Travel : redirected to parent ZC_ABAPPDF_TRAVEL
}
