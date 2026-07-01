//Testing braching and merging

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
        // Get all related Claims grouped by Employee and Insurance Provider to allow provider-level risk assessment
        List<AggregateResult> employeeProviderTotals = [SELECT Employee_Name__c, Claim_Number__r.Insurance_Provider__c, COUNT(Id) providerClaims, SUM(Claim_Number__r.Settlement_Amount__c) providerSettlementAmount
                                                FROM Employee_Claim__c 
                                                WHERE Employee_Name__c IN :employeeIds 
                                                GROUP BY Employee_Name__c, Claim_Number__r.Insurance_Provider__c
                                                ORDER BY Employee_Name__c];

        // Since query results are sub-grouped by provider, it is possible for the same employee Id to have multiple aggregate result entries with different providers
        // A map will allow claim and settlement total accumulation and highest risk level detection across providers for the same employee
        Map<Id, Employee__c> employeeMap = new Map<Id, Employee__c>();

        // Loop aggregate query results
        for(AggregateResult employeeProviderTotal : employeeProviderTotals){
            // Store provider-level claims and settlement values in an Employee variable then check risk level for this provider
            Employee__c employeeProvider = new Employee__c();
            employeeProvider.Id = (Id)employeeProviderTotal.get('Employee_Name__c');
            employeeProvider.Total_Claims__c = (Decimal)employeeProviderTotal.get('providerClaims');
            employeeProvider.Total_Settlement_Amount__c = (Decimal)employeeProviderTotal.get('providerSettlementAmount');
            employeeProvider.Risk_Level__c = calculateProviderRiskLevel(employeeProvider.Total_Claims__c, employeeProvider.Total_Settlement_Amount__c);

            // If this Employee has already been added to the map, then update it with new values, otherwise add to the map
            if(employeeMap.containsKey(employeeProvider.Id)){
                Employee__c mapEmployee = employeeMap.get(employeeProvider.Id);
                mapEmployee.Total_Claims__c += employeeProvider.Total_Claims__c;
                mapEmployee.Total_Settlement_Amount__c += employeeProvider.Total_Settlement_Amount__c;
                if(mapEmployee.Risk_Level__c == null || mapEmployee.Risk_Level__c == 'Standard' || (mapEmployee.Risk_Level__c == 'Medium Risk' && employeeProvider.Risk_Level__c == 'High Risk')){
                    mapEmployee.Risk_Level__c = employeeProvider.Risk_Level__c;
                }
                employeeMap.put(employeeProvider.Id, mapEmployee);
            }
            else{ // It hasn't been added to the map yet
                employeeMap.put(employeeProvider.Id, employeeProvider);
            }
        }

        // Update the Employee records with values contained in the map
        if(!employeeMap.isEmpty()){
            update employeeMap.values();
        }
    }

    /**
     * Calculate the risk level given a claim quantity and total payout to an Employee from a single Insurance Provider
     * @param numClaims the number of Claims on a single Insurance Provider
     * @param settlementAmount the total Settlement Amount received from a single Insurance Provider
     * @return string representing the Employee record risk level picklist value
     */
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
}