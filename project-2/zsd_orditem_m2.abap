@EndUserText.label : 'Sales Order Item - Mini Project 2'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zsd_orditem_m2 {
  key client     : mandt not null;
  key order_no   : char10 not null;
  key item_no    : char5 not null;
  material_desc  : char40;
  quantity       : abap.dec(9,2);
  price          : abap.dec(10,2) with currency currency;
  currency       : abap.cuky;
}
