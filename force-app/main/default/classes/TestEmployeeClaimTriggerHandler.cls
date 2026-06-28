/**
 * Unit tests for the EmployeeClaimTriggerHandler class
 * @see EmployeeClaimTriggerHandler
 */
@IsTest
private class TestEmployeeClaimTriggerHandler {
    /** Test Data Setup */
    @TestSetup static void setup(){
        List<Account> providers = new List<Account>();
        providers.add(new Account(Name = 'Provider 1'));
        providers.add(new Account(Name = 'Provider 2'));
        insert providers;

        Employee__c employee = new Employee__c();
            employee.Name = 'Employee 1';
            employee.Hire_Date__c = Date.today();
        insert employee;

        List<Claim__c> claims = new List<Claim__c>();
        for (Integer i = 0; i < 3; i++){
            Claim__c claim = new Claim__c();
            claim.Incident_Date__c = Date.today() - i;
            claim.Date_Filed__c = Date.today() - i;
            claim.Injury_Type__c = 'Repetitive Motion';
            claim.Status__c = 'Settled';
            claim.Settlement_Amount__c = 1000;
            claim.Insurance_Provider__c = providers[0].Id;
            claims.add(claim);
        }

        claims[1].Insurance_Provider__c = providers[1].Id; // Assign 1 claim to the other provider
        insert claims;

        Employee_Claim__c employeeClaim = new Employee_Claim__c();
            employeeClaim.Employee_Name__c = employee.Id;
            employeeClaim.Claim_Number__c = claims[0].Id;
        insert employeeClaim;
    }

    /** Test the AFTER INSERT context */
    @IsTest
    static void testAfterInsertEmployeeTotals() {
        // Generate test data
        Employee__c employee = [SELECT Id FROM Employee__c WHERE Name = 'Employee 1' LIMIT 1];
        Claim__c claim = [SELECT Id FROM Claim__c LIMIT 1];
        Employee_Claim__c employeeClaim = new Employee_Claim__c();
            employeeClaim.Employee_Name__c = employee.Id;
            employeeClaim.Claim_Number__c = claim.Id;

        // After Insert Context
        Test.startTest();
        insert employeeClaim;
        Test.stopTest();
        employee = [SELECT Total_Claims__c, Total_Settlement_Amount__c FROM Employee__c WHERE Id = :employeeClaim.Employee_Name__c];
        Assert.areEqual(2, employee.Total_Claims__c, 'Expected total claims to be 2');
        Assert.areEqual(2000.00, employee.Total_Settlement_Amount__c, 'Expected total settlement to be 2000');
    }

    /** Test the AFTER UPDATE context */
    @IsTest
    static void testAfterUpdateEmployeeTotals() {
        // Employee Claim is a junction object with 2 master-detail relationships, neither of which allow re-parenting
        // Because of that, we just do a dummy 'update' to run the trigger context but don't actually expect anything to change.
        Employee_Claim__c employeeClaim = [SELECT Id, Employee_Name__c FROM Employee_Claim__c WHERE Employee_Name__r.Name = 'Employee 1'];
        update employeeClaim;
    }

    /** Test the AFTER DELETE context */
    @IsTest
    static void testAfterDeleteEmployeeTotals() {
        // Verify existing data
        Employee_Claim__c employeeClaim = [SELECT Id, Employee_Name__c FROM Employee_Claim__c WHERE Employee_Name__r.Name = 'Employee 1'];
        Employee__c employee = [SELECT Total_Claims__c, Total_Settlement_Amount__c FROM Employee__c WHERE Name = 'Employee 1'];
        Assert.areEqual(1, employee.Total_Claims__c, 'Expected total claims to be 1');
        Assert.areEqual(1000.00, employee.Total_Settlement_Amount__c, 'Expected total settlement to be 1000');

        // After Delete Context
        Test.startTest();
        delete employeeClaim;
        Test.stopTest();
        employee = [SELECT Total_Claims__c, Total_Settlement_Amount__c FROM Employee__c WHERE Name = 'Employee 1'];
        Assert.areEqual(0, employee.Total_Claims__c, 'Expected total claims to be 0');
        Assert.areEqual(0.0, employee.Total_Settlement_Amount__c, 'Expected total settlement to be 0');

    }

    /** Test the AFTER UNDELTE context */
    @IsTest
    static void testAfterUnDeleteEmployeeTotals() {
        // Verify existing data
        Employee_Claim__c employeeClaim = [SELECT Id, Employee_Name__c FROM Employee_Claim__c WHERE Employee_Name__r.Name = 'Employee 1'];
        Employee__c employee = [SELECT Total_Claims__c, Total_Settlement_Amount__c FROM Employee__c WHERE Name = 'Employee 1'];
        Assert.areEqual(1, employee.Total_Claims__c, 'Expected total claims to be 1');
        Assert.areEqual(1000.00, employee.Total_Settlement_Amount__c, 'Expected total settlement to be 1000');
        delete employeeClaim;
        employee = [SELECT Total_Claims__c, Total_Settlement_Amount__c FROM Employee__c WHERE Name = 'Employee 1'];
        Assert.areEqual(0, employee.Total_Claims__c, 'Expected total claims to be 0');
        Assert.areEqual(0.0, employee.Total_Settlement_Amount__c, 'Expected total settlement to be 0');

        // After UnDelete Context
        Test.startTest();
        undelete employeeClaim;
        Test.stopTest();
        employee = [SELECT Total_Claims__c, Total_Settlement_Amount__c FROM Employee__c WHERE Name = 'Employee 1'];
        Assert.areEqual(1, employee.Total_Claims__c, 'Expected total claims to be 1');
        Assert.areEqual(1000.00, employee.Total_Settlement_Amount__c, 'Expected total settlement to be 1000');

    }
}