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
             Claim__c newClaim = new Claim__c();
             newClaim.Settlement_Amount__c = 500000;
             newClaim.Date_Filed__c = Date.newInstance(2026,06,18);
             newClaim.Incident_Date__c = Date.newInstance(2026,06,18);


            //Peform the test
             Test.startTest();
             insert newClaim;
             Test.stopTest();

            //Query for the updated record
            Claim__c claimResult = [SELECT Name,Id,Is_High_Value__c FROM Claim__c WHERE Id = :newClaim.Id];

            //Assert the expected outcome
            system.assertEquals(true, claimResult.Is_High_Value__c, 'IsHighValue should be checked for settlement Amounts greater than the threshold');

    }
}