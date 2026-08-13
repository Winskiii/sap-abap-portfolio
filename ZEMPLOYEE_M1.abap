@EndUserText.label : 'Employee Master - Mini Project 1'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zemployee_m1 {
  key client      : mandt not null;
  key emp_no      : char10 not null;
  emp_name        : char40;
  department      : char20;
  salary          : abap.dec(10,2);
  hire_date       : abap.dats;
}