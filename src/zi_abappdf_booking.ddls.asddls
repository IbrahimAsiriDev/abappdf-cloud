@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'abapPDF booking'
define view entity ZI_ABAPPDF_BOOKING
  as select from /dmo/booking
  association to parent ZI_ABAPPDF_TRAVEL as _Travel
    on $projection.travel_id = _Travel.travel_id
{
  key travel_id,
  key booking_id,
      carrier_id,
      connection_id,
      flight_date,
      @Semantics.amount.currencyCode: 'currency_code'
      flight_price,
      currency_code,
      _Travel
}
