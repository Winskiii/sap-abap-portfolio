@EndUserText.label : 'Sales Order Header - Mini Project 2'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zsd_ordhdr_m2 {
  key client     : mandt not null;
  key order_no   : char10 not null;
  customer_name  : char40;
  order_date     : abap.dats;
  currency       : abap.cuky;
}
