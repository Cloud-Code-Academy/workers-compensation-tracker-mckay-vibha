/**
 * Claim trigger Helper
 * Contains the utility logic called by the ClaimTriggerHandler
 */
public with sharing class ClaimHelper {
    /**
     * Determine if the Claim is high value based on the Settlement amount
     * @param claims a list of Claim records
     */
    public static void determineIsHighValue(List<Claim__c> claims){
        Workers_Comp_Tracker_Threshold__mdt threshold = Workers_Comp_Tracker_Threshold__mdt.getInstance('High_Value_Claim');
        for(Claim__c claim : claims){
            if (claim.Settlement_Amount__c != null && claim.Settlement_Amount__c >= threshold.Value__c){
                claim.Is_High_Value__c = true;
            }
            else{
                claim.Is_High_Value__c = false;
            }
        }
    }

    /**
     * Calculate the number of days the Claim has been open
     * @param claims a list of Claim records
     */
    public static void calculateDaysOpen(List<Claim__c> claims){
        for(Claim__c claim : claims){
            if (claim.Status__c == 'Settled' || claim.Status__c == 'Denied'){
                claim.Days_Open__c = claim.Incident_Date__c.daysBetween(claim.Date_Filed__c);
            }
            else{
                claim.Days_Open__c = claim.Incident_Date__c.daysBetween(Date.today());
            }
        }
    }

    /**
     * Verify claim date field values are valid and show error to the user if they are not
     * @param claims a list of Claim records
     */
    public static void verifyDates(List<Claim__c> claims){
        for(Claim__c claim : claims){
            if (claim.Date_Filed__c > Date.today() || claim.Incident_Date__c > Date.today() || claim.Settlement_Date__c > Date.today()){
                claim.addError('Date Filed, Incident Date, or Settlement Date fields cannot be in the future');
            }
            if(claim.Incident_Date__c > claim.Date_Filed__c){
                claim.addError('Incident Date cannot be after the Date Filed - claims cannot be reported before they happen');
            }
        }
    }

    /**
     * Populate the Settlement Amount on claim status change
     * @param claims a list of Claim records
     */
    public static void determineSettlementDate(List<Claim__c> claims){
        for(Claim__c claim : claims){
            if (claim.Status__c == 'Settled' && claim.Settlement_Date__c == null){
                if(claim.Settlement_Amount__c > 0){
                    claim.Settlement_Date__c = Date.today();
                }
                else{
                    claim.addError('A claim cannot have status of Settled if the Settlement Amount is 0');
                }
            }
            if(claim.Status__c == 'Denied' && claim.Settlement_Amount__c != 0){
                claim.Settlement_Amount__c = 0;
                claim.Settlement_Date__c = null;
            }
        }
    }
}