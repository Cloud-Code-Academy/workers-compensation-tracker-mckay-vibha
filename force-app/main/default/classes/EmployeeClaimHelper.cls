/**
 * Employee Claim trigger Helper
 * Contains utility logic called by the EmployeeClaimTriggerHandler and other classes
 */
public with sharing class EmployeeClaimHelper {
    /**
     * Retrieve a unique collection of Employee record Ids from the provided Employee Claims
     * @param employeeClaims a list of the Employee Claim records involved in the trigger context
     * @return a Set of Employee record Ids
     */
    public static Set<Id> getEmployeeIds(List<Employee_Claim__c> employeeClaims){
        Set<Id> employeeIds = new Set<Id>();
        // Check for valid input to avoid null pointer exception in for loop
        if(employeeClaims == null || employeeClaims.isEmpty()){
            return employeeIds;
        }
        for(Employee_Claim__c ec : employeeClaims){
            if(ec.Employee_Name__c != null){
                employeeIds.add(ec.Employee_Name__c);
            }
        }
        return employeeIds;
    }

    /**
     * Update the Employee risk level, total claims, and total settlement amount calculated from all their related Claims
     * @param employeeIds a set of Employee record Ids
     */
    public static void updateEmployeeRiskAndTotals(Set<Id> employeeIds){
        // Check for valid input to avoid null pointer exceptions below
        if(employeeIds == null || employeeIds.isEmpty()){
            return;
        }

        // Get all related Claims grouped by Employee, Insurance Provider, and Status to allow provider-level risk assessment
        // Note the use of aliases 'status', 'provider', 'providerClaims', and 'providerSettlementAmount' for easier reference
        List<AggregateResult> queryResults = [SELECT Employee_Name__c, Claim_Number__r.Insurance_Provider__c provider, Claim_Number__r.Status__c status, COUNT(Id) providerClaims, SUM(Claim_Number__r.Settlement_Amount__c) providerSettlementAmount
                                                FROM Employee_Claim__c
                                                WHERE Employee_Name__c IN :employeeIds
                                                GROUP BY Employee_Name__c, Claim_Number__r.Insurance_Provider__c, Claim_Number__r.Status__c
                                                ORDER BY Employee_Name__c];

        // Transform AggregateResult into custom inner class (for easier testing since AggregateResult can't be constructed)
        List<EmployeeProviderTotal> eptList = new List<EmployeeProviderTotal>();
        for(AggregateResult queryResult : queryResults){
            EmployeeProviderTotal ept = new EmployeeProviderTotal();
            ept.employee = (Id)queryResult.get('Employee_Name__c');
            ept.status = (String)queryResult.get('status');
            ept.provider = (Id)queryResult.get('provider');
            ept.providerClaims = (Decimal)queryResult.get('providerClaims');
            ept.providerSettlementAmount = (Decimal)queryResult.get('providerSettlementAmount');
            eptList.add(ept);
        }

        // Generate a map containing current Employee totals & risk
        Map<Id, Employee__c> employeeMap = generateEmployeeUpdateMap(employeeIds, eptList);

        // Update the Employee records with values contained in the map
        update employeeMap.values();
    }

    /**
     * Calculate the risk level given a claim quantity and total payout to an Employee from a single Insurance Provider
     * @param employeeIds the set of Employee record Ids to be calculated
     * @param employeeProviderTotals aggregate query results showing the employee totals per provider
     * @return map of Employee Ids and Employee records with current total and risk values
     */
    @TestVisible
    private static Map<Id, Employee__c> generateEmployeeUpdateMap(Set<Id> employeeIds, List<EmployeeProviderTotal> employeeProviderTotals){
        // Initialize all affected Employees to ensure they are all updated even if no Employee Claims are found in below query when running in the AFTER DELETE context
        Map<Id, Employee__c> employeeMap = new Map<Id, Employee__c>();
        for(Id employeeId : employeeIds){
            employeeMap.put(employeeId, new Employee__c(
                Id = employeeId,
                Total_Claims__c = 0,
                Total_Settlement_Amount__c = 0,
                Risk_Level__c = 'Standard'
            ));
        }

        // Loop aggregate query results and accumulate totals for each Employee
        for(EmployeeProviderTotal employeeProviderTotal : employeeProviderTotals){
            // Store provider-level claims and settlement values in an Employee variable
            Employee__c employeeProvider = new Employee__c();
            employeeProvider.Id = employeeProviderTotal.employee;
            employeeProvider.Total_Claims__c = employeeProviderTotal.providerClaims;

            // Only store settlement amount if Status = Settled
            System.debug('employeeProviderTotal.status: ' + employeeProviderTotal.status);
            if(employeeProviderTotal.status == 'Settled'){
                employeeProvider.Total_Settlement_Amount__c = employeeProviderTotal.providerSettlementAmount;
            }
            else{
                employeeProvider.Total_Settlement_Amount__c = 0; // Set to 0 to avoid null exception below when incrementing settlement amounts for the employee
            }

            // Calculate the risk level for this provider
            employeeProvider.Risk_Level__c = calculateProviderRiskLevel(employeeProvider.Total_Claims__c, employeeProvider.Total_Settlement_Amount__c);

            // Update the Employee map with with accumated values
            Employee__c employee = employeeMap.get(employeeProvider.Id);
            employee.Total_Claims__c += employeeProvider.Total_Claims__c;
            employee.Total_Settlement_Amount__c += employeeProvider.Total_Settlement_Amount__c;
            if(employee.Risk_Level__c == null || employee.Risk_Level__c == 'Standard' || (employee.Risk_Level__c == 'Medium Risk' && employeeProvider.Risk_Level__c == 'High Risk')){
                employee.Risk_Level__c = employeeProvider.Risk_Level__c;
            }
            employeeMap.put(employeeProvider.Id, employee);
        }

        return employeeMap;
    }

    /**
     * Calculate the risk level given a claim quantity and total payout to an Employee from a single Insurance Provider
     * @param numClaims the number of Claims on a single Insurance Provider
     * @param settlementAmount the total Settlement Amount received from a single Insurance Provider
     * @return string representing the Employee record risk level picklist value
     */
    @TestVisible
    private static String calculateProviderRiskLevel(Decimal numClaims, Decimal settlementAmount){
        // Get all the risk threshold values to check
        Decimal highClaimQty = Workers_Comp_Tracker_Threshold__mdt.getInstance('High_Risk_Claim_Quantity').Value__c;
        Decimal highPayout = Workers_Comp_Tracker_Threshold__mdt.getInstance('High_Risk_Total_Payout').Value__c;
        Decimal mediumClaimQty = Workers_Comp_Tracker_Threshold__mdt.getInstance('Medium_Risk_Claim_Quantity').Value__c;
        Decimal mediumPayout = Workers_Comp_Tracker_Threshold__mdt.getInstance('Medium_Risk_Total_Payout').Value__c;

        if(numClaims >= highClaimQty || settlementAmount >= highPayout){
            return 'High Risk';
        }
        else if(numClaims >= mediumClaimQty || settlementAmount >= mediumPayout){
            return 'Medium Risk';
        }
        else{
            return 'Standard';
        }
    }

    /** Aggregate Query Result */
    @TestVisible
    private class EmployeeProviderTotal{
        public Id employee;
        public Id provider;
        public String status;
        public Decimal providerClaims;
        public Decimal providerSettlementAmount;
    }
}