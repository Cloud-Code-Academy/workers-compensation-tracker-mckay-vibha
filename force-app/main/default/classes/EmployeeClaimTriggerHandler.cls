/**
 * Employee Claim Trigger Handler
 * Extends the virtual TriggerHandler framework class and overrides the context methods
 * TriggerHandler Source: https://github.com/kevinohara80/sfdc-trigger-framework
 * @see <a href="https://www.apexhours.com/trigger-framework-in-salesforce/">Trigger Frameworks in Salesforce</a>
 */
public with sharing class EmployeeClaimTriggerHandler extends TriggerHandler {
    // Local copies of the Trigger context variables populated by the constructor
    private List<Employee_Claim__c> newEmployeeClaims;
    private List<Employee_Claim__c> oldEmployeeClaims;

    /**
     * CONSTRUCTOR
     * Handles the necessary type casting for Trigger context variables referenced in a class
     */
    public EmployeeClaimTriggerHandler() {
        // Type casting allows the object fields to be directly referenced
        this.newEmployeeClaims = (List<Employee_Claim__c>) Trigger.new;
        this.oldEmployeeClaims = (List<Employee_Claim__c>) Trigger.old;
    }

    /***************************************
     * CONTEXT METHODS
     ***************************************/

    /**
     * AFTER_INSERT
     */
    public override void afterInsert(){
        // Get Employee Ids from trigger.new
    }

    /**
     * AFTER_UPDATE
     */
    public override void afterUpdate(){
        // Get Employee Ids from trigger.new
        Set<Id> employeeIds = EmployeeClaimHelper.getEmployeeIds(newEmployeeClaims);
        EmployeeClaimHelper.updateEmployeeRiskAndTotals(employeeIds);
    }

    /**
     * AFTER_DELETE
     */
    public override void afterDelete(){
        // Get Employee Ids from trigger.old
        Set<Id> employeeIds = EmployeeClaimHelper.getEmployeeIds(oldEmployeeClaims);
        EmployeeClaimHelper.updateEmployeeRiskAndTotals(employeeIds);
    }

    /**
     * AFTER_UNDELETE
     */
    public override void afterUndelete(){
        // Get Employee Ids from trigger.new
    }
}