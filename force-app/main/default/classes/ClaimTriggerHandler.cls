/**
 * Claim Trigger Handler
 * Extends the virtual TriggerHandler framework class and overrides the context methods
 * TriggerHandler Source: https://github.com/kevinohara80/sfdc-trigger-framework
 * @see <a href="https://www.apexhours.com/trigger-framework-in-salesforce/">Trigger Frameworks in Salesforce</a>
 */
public with sharing class ClaimTriggerHandler extends TriggerHandler {


public override void beforeInsert(){
           determineIsHighValue(Trigger.new);
           calculateDaysOpen(Trigger.new);
           validateSettlementAmount(Trigger.new);
           verifyDates(Trigger.new);
}


public override void beforeUpdate(){
            determineIsHighValue(Trigger.new);
            calculateDaysOpen(Trigger.new);
            determineSettlementDate(Trigger.new);
            validateSettlementAmount(Trigger.new);
            verifyDates(Trigger.new);
}

// REQUIREMENT #1 
//High-Value Claim Flag
// Automatically check the Is High Value Checkbox field whenever the Settlement Amount exceeds a threshold we define in Custom metadata
// TBD: Need to confirm with stakeholders if settlement amount = threshold value, should claim be marked as highvalue? Current logic sets the field to high value if settlement date is equal to threshold.


private void determineIsHighValue (List<Claim__c> claims) {
           
    Workers_Comp_Tracker_Threshold__mdt hvc = Workers_Comp_Tracker_Threshold__mdt.getInstance('High_Value_Claim');
 
    if (hvc == null){
           return;
    }
   
     for (Claim__c claim : claims) {
     
         if (claim.Settlement_Amount__c >= hvc.Value__c ){
                    claim.Is_High_Value__c = true;
         }else {
                    claim.Is_High_Value__c = false;
         }

     }
 }


// REQUIREMENT #2
//Claim Duration Tracking
//Calculates the number of days between the Incident Date and today (or the Date Filed if the claim is Settled or Denied) and stores it Days Open field on Claim object
// TBD: Should 'Closed' claims stop counting at Date Filed (like Settled/Denied)?
//TBD: Shouldn't this use Claim__c.Settlement_Date__c if the status = Settled?

    private void calculateDaysOpen(List<Claim__c> claims){

        for( claim__c c : claims) {   
            
        if ( c.Incident_Date__c != null )
        {           
             if(c.Status__c == 'Settled' || c.Status__c == 'Denied') {             
                   if (c.Date_Filed__c != null ) 
                    {
                        
                        c.Days_Open__c = c.Incident_Date__c.daysBetween(c.Date_Filed__c);
                    }
                 
             } else { 
   
                        c.Days_Open__c = c.Incident_Date__c.daysBetween(date.today());
             }

         }
        }
    }


//REQUIREMENT #3
//Claim Status Automation
//When Status changes to Settled: set Settlement Date to today if it is currently blank. 
//When Status changes to Denied: clear the Settlement Amount field (set it to 0)


 private void determineSettlementDate( List<Claim__c> claims) 
  {

         Map<Id, Claim__c> oldClaims = (Map<Id, Claim__c>) Trigger.oldMap;
                      

        for (Claim__c  c : claims)
        {

            if( c.Status__c == 'Settled' &&  oldClaims.get(c.Id).Status__c != 'Settled')
             {
                   if( c.Settlement_Date__c == null)
                    {
                         c.Settlement_Date__c = Date.today();
                     } 

            } else if ( c.Status__c == 'Denied' && oldClaims.get(c.Id).Status__C != 'Denied' ) 
                     {
                     
                         c.Settlement_Amount__c = 0;

                     }  
              }

         }

//Requirement 4:
//Validate that Settlement Amount is greater than zero — a claim cannot be marked Settled with a $0 payout.

private void validateSettlementAmount (List<Claim__c> claims) {

        for (Claim__c  c : claims) {

              if(c.Settlement_Amount__c <= 0 && c.Status__c == 'Settled'){
                          c.addError('A claim cannot have status of Settled if the Settlement Amount is 0');

              } 

            }
        }

//REQUIREMENT 5:
//Validate that Incident Date is not in the future and is not after the Date Filed — a realistic claim cannot be reported before it happened.

private void verifyDates (List<Claim__c> claims){

 for (Claim__c c : claims){
        
         if(c.Incident_Date__c != null && c.Incident_Date__c > Date.today()) {
                               c.addError('Incident Date should not be in the future');
         }
        
         if(c.Incident_Date__c != null && c.Date_Filed__c != null){
             if( c.Incident_Date__c > c.Date_Filed__c){
                            c.addError('Incident Date should not be after the Date filed'); 
          }
         }                     

 }

}



}
    //---------------Logic with helper class--------------------------------------
    // Local copies of the Trigger context variables
  //  private List<Claim__c> newClaims;
   // private List<Claim__c> oldClaims;
   // private Map<Id, Claim__c> oldClaimsMap;

    /**
     * CONSTRUCTOR
     * Handles the necessary type casting for Trigger context variables referenced in a class
     */
  //  public ClaimTriggerHandler() {
        // Constructor takes care of the 
   //     this.newClaims = (List<Claim__c>) Trigger.new;
  //  }

    /**
     * BEFORE_INSERT
     */
//    public override void beforeInsert(){
    //    ClaimHelper.verifyDates(newClaims);
  //      ClaimHelper.calculateDaysOpen(newClaims);
  //      ClaimHelper.determineIsHighValue(newClaims);
   //     ClaimHelper.determineSettlementDate(newClaims);
  //  }

    /**
     * BEFORE_UPDATE
     */
   // public override void beforeUpdate(){
 //       ClaimHelper.verifyDates(newClaims);
  //      ClaimHelper.calculateDaysOpen(newClaims);
   //     ClaimHelper.determineIsHighValue(newClaims);
  //      ClaimHelper.determineSettlementDate(newClaims);
 //   }


