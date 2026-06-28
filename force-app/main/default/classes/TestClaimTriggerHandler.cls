/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class TestClaimTriggerHandler {

    @isTest
    static void testDetermineIsHighValue() {

            // Create test data
             List<Claim__c> claims = new List<Claim__c>();

             Claim__c highClaim = new Claim__c();
             highClaim.Settlement_Amount__c = 500000;
             highClaim.Date_Filed__c = Date.newInstance(2026,06,18);
             highClaim.Incident_Date__c = Date.newInstance(2026,06,18);

             Claim__c lowClaim = new Claim__c(); 
             lowClaim.Settlement_Amount__c = 500;
             lowClaim.Date_Filed__c = Date.newInstance(2026, 06,20);
             lowClaim.Incident_Date__c = Date.newInstance(2026,06,20);

             claims.add(highClaim);
             claims.add(lowClaim);
            

            //Peform the test
             Test.startTest();
             insert claims;
             Test.stopTest();

            //Query for the updated record
            Map<Id, Claim__c> results = new Map<Id, Claim__c>([SELECT Name,Id,Is_High_Value__c FROM Claim__c WHERE Id IN :claims]);

            //Assert the expected outcome
            system.assertEquals(true, results.get(highClaim.Id).Is_High_Value__c, 'IsHighValue should be checked for settlement Amounts greater than the threshold');
            system.assertEquals(false, results.get(lowClaim.Id).Is_High_Value__c, 'IsHighValue should be unchecked for settlement Amounts less than the threshold');

    }
}