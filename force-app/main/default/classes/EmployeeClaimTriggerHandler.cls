/**
 * Employee Claim Trigger Handler
 * Extends the virtual TriggerHandler framework class and overrides the context methods
 * TriggerHandler Source: https://github.com/kevinohara80/sfdc-trigger-framework
 * @see <a href="https://www.apexhours.com/trigger-framework-in-salesforce/">Trigger Frameworks in Salesforce</a>
 */
public with sharing class EmployeeClaimTriggerHandler extends TriggerHandler {
    // Local copies of the Trigger context variables
    private List<Employee_Claim__c> newEmployeeClaims;
    private List<Employee_Claim__c> oldEmployeeClaims;
    private Map<Id, Employee_Claim__c> oldEmployeeClaimsMap;

    /**
     * CONSTRUCTOR
     * Handles the necessary type casting for Trigger context variables referenced in a class
     */
    public EmployeeClaimTriggerHandler() {
        // Constructor takes care of the type casting to the appropriate object so object fields can be directly referenced
        this.newEmployeeClaims = (List<Employee_Claim__c>) Trigger.new;
    }

    /**
     * BEFORE_INSERT
     */
    public override void beforeInsert(){
        // before insert trigger logic here
    }

    /**
     * BEFORE_UPDATE
     */
    public override void beforeUpdate(){
        // before update trigger logic here
    }
}