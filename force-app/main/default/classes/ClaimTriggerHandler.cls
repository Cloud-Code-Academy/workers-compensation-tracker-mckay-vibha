/**
 * Claim Trigger Handler
 * Extends the virtual TriggerHandler framework class and overrides the context methods
 * TriggerHandler Source: https://github.com/kevinohara80/sfdc-trigger-framework
 * @see <a href="https://www.apexhours.com/trigger-framework-in-salesforce/">Trigger Frameworks in Salesforce</a>
 */
public with sharing class ClaimTriggerHandler extends TriggerHandler {
    // Local copies of the Trigger context variables
    private List<Claim__c> newClaims;
    private List<Claim__c> oldClaims;
    private Map<Id, Claim__c> oldClaimsMap;

    /**
     * CONSTRUCTOR
     * Handles the necessary type casting for Trigger context variables referenced in a class
     */
    public ClaimTriggerHandler() {
        // Constructor takes care of the 
        this.newClaims = (List<Claim__c>) Trigger.new;
    }

    /**
     * BEFORE_INSERT
     */
    public override void beforeInsert(){
        ClaimHelper.verifyDates(newClaims);
        ClaimHelper.calculateDaysOpen(newClaims);
        ClaimHelper.determineIsHighValue(newClaims);
        ClaimHelper.determineSettlementDate(newClaims);
    }

    /**
     * BEFORE_UPDATE
     */
    public override void beforeUpdate(){
        ClaimHelper.verifyDates(newClaims);
        ClaimHelper.calculateDaysOpen(newClaims);
        ClaimHelper.determineIsHighValue(newClaims);
        ClaimHelper.determineSettlementDate(newClaims);
    }
}