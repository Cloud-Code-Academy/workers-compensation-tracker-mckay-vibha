/**
 * Employee Claim Trigger Handler
 * Extends the virtual TriggerHandler framework class and overrides the context methods
 * Since this class does not directly access the trigger context record fields, no type casting is necessary
 * TriggerHandler Source: https://github.com/kevinohara80/sfdc-trigger-framework
 * @see <a href="https://www.apexhours.com/trigger-framework-in-salesforce/">Trigger Frameworks in Salesforce</a>
 */
public with sharing class EmployeeClaimTriggerHandler extends TriggerHandler {
    /**
     * AFTER_INSERT
     */
    public override void afterInsert(){
        // Get Employee Ids from trigger.new
        Set<Id> employeeIds = EmployeeClaimHelper.getEmployeeIds(Trigger.new);
        EmployeeClaimHelper.updateEmployeeRiskAndTotals(employeeIds);
        // Get Employee Ids from trigger.new
    }

    /**
     * AFTER_UPDATE
     */
    public override void afterUpdate(){
        // Get Employee Ids from trigger.new
        Set<Id> employeeIds = EmployeeClaimHelper.getEmployeeIds(Trigger.new);
        EmployeeClaimHelper.updateEmployeeRiskAndTotals(employeeIds);
    }

    /**
     * AFTER_DELETE
     */
    public override void afterDelete(){
        // Get Employee Ids from trigger.old
        Set<Id> employeeIds = EmployeeClaimHelper.getEmployeeIds(Trigger.old);
        EmployeeClaimHelper.updateEmployeeRiskAndTotals(employeeIds);
    }

    /**
     * AFTER_UNDELETE
     */
    public override void afterUndelete(){
        // Get Employee Ids from trigger.new
        Set<Id> employeeIds = EmployeeClaimHelper.getEmployeeIds(Trigger.new);
        EmployeeClaimHelper.updateEmployeeRiskAndTotals(employeeIds);

    }
}