/**
 * Unit tests for the EmployeeClaimHelper class
 * NOTE: most tests for the updateEmployeeRiskAndTotals method are covered in the TestEmployeeClaimHandler
 * @see EmployeeClaimHelper
 */
@isTest
private class TestEmployeeClaimHelper {
    /** Test Data Setup */
    @TestSetup static void setup(){
        List<Account> providers = new List<Account>();
        providers.add(new Account(Name = 'Provider 1'));
        providers.add(new Account(Name = 'Provider 2'));
        insert providers;

        List<Employee__c> employees = new List<Employee__c>();
        Employee__c employee1 = new Employee__c();
            employee1.Name = 'Employee 1';
            employee1.Hire_Date__c = Date.today();
            employees.add(employee1);
        Employee__c employee2 = employee1.clone();
            employee2.Name = 'Employee 2';
            employees.add(employee2);
        insert employees;

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
    }

    /** Test getEmployeeIds with a variety of input scenarios */
    @IsTest
    static void testGetEmployeeIds() {
        List<Employee_Claim__c> employeeClaims;

        // Null input
        Set<Id> employeeIds = EmployeeClaimHelper.getEmployeeIds(employeeClaims);
        Assert.isTrue(employeeIds.isEmpty(), 'Expected no employee Ids');

        // Empty input
        employeeClaims = new List<Employee_Claim__c>();
        employeeIds = EmployeeClaimHelper.getEmployeeIds(employeeClaims);
        Assert.isTrue(employeeIds.isEmpty(), 'Expected no employee Ids');

        // Single values in input list
        List<Employee__c> employees = [SELECT Id FROM Employee__c];
        employeeClaims.add(new Employee_Claim__c(Employee_Name__c = employees[0].Id));
        employeeIds = EmployeeClaimHelper.getEmployeeIds(employeeClaims);
        Assert.areEqual(1, employeeIds.size(), 'Expected 1 unique Employee Id');

        // Multiple claims for same employee in input list
        employeeClaims.add(new Employee_Claim__c(Employee_Name__c = employees[0].Id));
        employeeIds = EmployeeClaimHelper.getEmployeeIds(employeeClaims);
        Assert.areEqual(1, employeeIds.size(), 'Expected 1 unique Employee Ids');

        // Include second employee in claims list
        employeeClaims.add(new Employee_Claim__c(Employee_Name__c = employees[1].Id));
        employeeIds = EmployeeClaimHelper.getEmployeeIds(employeeClaims);
        Assert.areEqual(2, employeeIds.size(), 'Expected 2 unique Employee Ids');
    }

    /** Test calculateProviderRiskLevel with a variety of input scenarios */
    @IsTest
    static void testCalculateProviderRiskLevel() {
        // Get all the risk threshold values to check
        Decimal highClaimQty = Workers_Comp_Tracker_Threshold__mdt.getInstance('High_Risk_Claim_Quantity').Value__c;
        Decimal highPayout = Workers_Comp_Tracker_Threshold__mdt.getInstance('High_Risk_Total_Payout').Value__c;
        Decimal mediumClaimQty = Workers_Comp_Tracker_Threshold__mdt.getInstance('Medium_Risk_Claim_Quantity').Value__c;
        Decimal mediumPayout = Workers_Comp_Tracker_Threshold__mdt.getInstance('Medium_Risk_Total_Payout').Value__c;

        // Null input
        Decimal numClaims;
        Decimal settlementAmount;
        String riskLevel = EmployeeClaimHelper.calculateProviderRiskLevel(numClaims, settlementAmount);
        Assert.areEqual('Standard', riskLevel, 'Expected risk level Standard');

        // Negative input
        numClaims = -1;
        settlementAmount = -1000.0;
        riskLevel = EmployeeClaimHelper.calculateProviderRiskLevel(numClaims, settlementAmount);
        Assert.areEqual('Standard', riskLevel, 'Expected risk level Standard');

        // Zero input
        numClaims = 0;
        settlementAmount = 0.0;
        riskLevel = EmployeeClaimHelper.calculateProviderRiskLevel(numClaims, settlementAmount);
        Assert.areEqual('Standard', riskLevel, 'Expected risk level Standard');

        // Medium Claim quantity
        numClaims = mediumClaimQty;
        settlementAmount = 0.0;
        riskLevel = EmployeeClaimHelper.calculateProviderRiskLevel(numClaims, settlementAmount);
        Assert.areEqual('Medium Risk', riskLevel, 'Expected risk level Medium Risk');

        // Medium Settlement amount
        numClaims = 0;
        settlementAmount = mediumPayout;
        riskLevel = EmployeeClaimHelper.calculateProviderRiskLevel(numClaims, settlementAmount);
        Assert.areEqual('Medium Risk', riskLevel, 'Expected risk level Medium Risk');

        // High Claim quantity
        numClaims = highClaimQty;
        settlementAmount = 0.0;
        riskLevel = EmployeeClaimHelper.calculateProviderRiskLevel(numClaims, settlementAmount);
        Assert.areEqual('High Risk', riskLevel, 'Expected risk level High Risk');

        // High Settlement amount
        numClaims = 0;
        settlementAmount = highPayout;
        riskLevel = EmployeeClaimHelper.calculateProviderRiskLevel(numClaims, settlementAmount);
        Assert.areEqual('High Risk', riskLevel, 'Expected risk level High Risk');
    }

    /** Test the updateEmployeeRiskAndTotals method */
    @IsTest
    static void testUpdateEmployeeRiskAndTotals() {
        // Null input
        Set<Id> employeeIds;
        EmployeeClaimHelper.updateEmployeeRiskAndTotals(employeeIds);

        // Empty input
        employeeIds = new Set<Id>();
        EmployeeClaimHelper.updateEmployeeRiskAndTotals(employeeIds);
    }

    /** Test the generateEmployeeUpdateMap method */
    @IsTest
    static void testGenerateEmployeeUpdateMap(){
        // Get all the risk threshold values to check
        Decimal highClaimQty = Workers_Comp_Tracker_Threshold__mdt.getInstance('High_Risk_Claim_Quantity').Value__c;
        Decimal highPayout = Workers_Comp_Tracker_Threshold__mdt.getInstance('High_Risk_Total_Payout').Value__c;
        Decimal mediumClaimQty = Workers_Comp_Tracker_Threshold__mdt.getInstance('Medium_Risk_Claim_Quantity').Value__c;
        Decimal mediumPayout = Workers_Comp_Tracker_Threshold__mdt.getInstance('Medium_Risk_Total_Payout').Value__c;

        // Retrieve test Employee data
        List<Employee__c> employees = [SELECT Id, Name FROM Employee__c];
        Id firstEmployeeId = employees[0].Id;
        Set<Id> employeeIds = new Map<Id, Employee__c>(employees).keySet();
        List<EmployeeClaimHelper.EmployeeProviderTotal> employeeProviderTotals = new List<EmployeeClaimHelper.EmployeeProviderTotal>();

        // Scenario: no query results found for this employee
        System.debug('Scenario: No Employee Claims');
        Map<Id, Employee__c> employeeMap = EmployeeClaimHelper.generateEmployeeUpdateMap(employeeIds, employeeProviderTotals);
        for(Id employeeId : employeeIds){
            Assert.areEqual(0, employeeMap.get(firstEmployeeId).Total_Claims__c, 'Expected 0 claims');
            Assert.areEqual(0, employeeMap.get(firstEmployeeId).Total_Settlement_Amount__c, 'Expected 0 settlement amount');
            Assert.areEqual('Standard', employeeMap.get(firstEmployeeId).Risk_Level__c, 'Expected Standard risk');
        }

        // Scenario: Claim not settled (don't consider settlement amount until settled)
        System.debug('Scenario: Claim not Settled');
        EmployeeClaimHelper.EmployeeProviderTotal ept = new EmployeeClaimHelper.EmployeeProviderTotal();
            ept.employee = firstEmployeeId;
            ept.status = 'Open';
            ept.providerClaims = mediumClaimQty - 1;
            ept.providerSettlementAmount = highPayout;
            employeeProviderTotals.add(ept);
        employeeMap = EmployeeClaimHelper.generateEmployeeUpdateMap(employeeIds, employeeProviderTotals);
        Assert.areEqual(mediumClaimQty - 1, employeeMap.get(firstEmployeeId).Total_Claims__c, 'Expected 1 less than medium threshold claim qty');
        Assert.areEqual(0, employeeMap.get(firstEmployeeId).Total_Settlement_Amount__c, 'Expected 0 settlement amount since claims are open');
        Assert.areEqual('Standard', employeeMap.get(firstEmployeeId).Risk_Level__c, 'Expected Standard risk');

        // Scenario: standard payout & claim qty risk
        System.debug('Scenario: Standard Claim Quantity and Payout Risk');
        employeeProviderTotals.clear();
            ept.employee = firstEmployeeId;
            ept.status = 'Settled';
            ept.providerClaims = mediumClaimQty - 1;
            ept.providerSettlementAmount = mediumPayout - 1;
            employeeProviderTotals.add(ept);
        employeeMap = EmployeeClaimHelper.generateEmployeeUpdateMap(employeeIds, employeeProviderTotals);
        Assert.areEqual(mediumClaimQty - 1, employeeMap.get(firstEmployeeId).Total_Claims__c, 'Expected 1 less than medium threshold claim qty');
        Assert.areEqual(mediumPayout - 1, employeeMap.get(firstEmployeeId).Total_Settlement_Amount__c, 'Expected 1 less than medium threshold payout');
        Assert.areEqual('Standard', employeeMap.get(firstEmployeeId).Risk_Level__c, 'Expected Standard risk');

        // Scenario: medium claim quantity risk
        System.debug('Scenario: Medium Claim Quantity Risk');
        employeeProviderTotals.clear();
            ept.employee = firstEmployeeId;
            ept.status = 'Settled';
            ept.providerClaims = mediumClaimQty;
            ept.providerSettlementAmount = mediumPayout - 1;
            employeeProviderTotals.add(ept);
        employeeMap = EmployeeClaimHelper.generateEmployeeUpdateMap(employeeIds, employeeProviderTotals);
        Assert.areEqual(mediumClaimQty, employeeMap.get(firstEmployeeId).Total_Claims__c, 'Expected the medium threshold claim qty');
        Assert.areEqual(mediumPayout - 1, employeeMap.get(firstEmployeeId).Total_Settlement_Amount__c, 'Expected 1 less than medium threshold payout');
        Assert.areEqual('Medium Risk', employeeMap.get(firstEmployeeId).Risk_Level__c, 'Expected Medium risk');

        // Scenario: high claim quantity risk
        System.debug('Scenario: High Claim Quantity Risk');
        employeeProviderTotals.clear();
            ept.employee = firstEmployeeId;
            ept.status = 'Settled';
            ept.providerClaims = highClaimQty;
            ept.providerSettlementAmount = mediumPayout - 1;
            employeeProviderTotals.add(ept);
        employeeMap = EmployeeClaimHelper.generateEmployeeUpdateMap(employeeIds, employeeProviderTotals);
        Assert.areEqual(highClaimQty, employeeMap.get(firstEmployeeId).Total_Claims__c, 'Expected the high threshold claim qty');
        Assert.areEqual(mediumPayout - 1, employeeMap.get(firstEmployeeId).Total_Settlement_Amount__c, 'Expected 1 less than medium threshold payout');
        Assert.areEqual('High Risk', employeeMap.get(firstEmployeeId).Risk_Level__c, 'Expected High risk');

        // Scenario: medium payout risk
        System.debug('Scenario: Medium Payout Risk');
        employeeProviderTotals.clear();
            ept.employee = firstEmployeeId;
            ept.status = 'Settled';
            ept.providerClaims = mediumClaimQty - 1;
            ept.providerSettlementAmount = mediumPayout;
            employeeProviderTotals.add(ept);
        employeeMap = EmployeeClaimHelper.generateEmployeeUpdateMap(employeeIds, employeeProviderTotals);
        Assert.areEqual(mediumClaimQty -1, employeeMap.get(firstEmployeeId).Total_Claims__c, 'Expected 1 less than the medium threshold claim qty');
        Assert.areEqual(mediumPayout, employeeMap.get(firstEmployeeId).Total_Settlement_Amount__c, 'Expected the medium threshold payout');
        Assert.areEqual('Medium Risk', employeeMap.get(firstEmployeeId).Risk_Level__c, 'Expected Medium risk');

        // Scenario: high payout risk
        System.debug('Scenario: High Payout Risk');
        employeeProviderTotals.clear();
            ept.employee = firstEmployeeId;
            ept.status = 'Settled';
            ept.providerClaims = mediumClaimQty - 1;
            ept.providerSettlementAmount = highPayout;
            employeeProviderTotals.add(ept);
        employeeMap = EmployeeClaimHelper.generateEmployeeUpdateMap(employeeIds, employeeProviderTotals);
        Assert.areEqual(mediumClaimQty -1, employeeMap.get(firstEmployeeId).Total_Claims__c, 'Expected 1 less than the medium threshold claim qty');
        Assert.areEqual(highPayout, employeeMap.get(firstEmployeeId).Total_Settlement_Amount__c, 'Expected the high threshold payout');
        Assert.areEqual('High Risk', employeeMap.get(firstEmployeeId).Risk_Level__c, 'Expected High risk');
    }
}