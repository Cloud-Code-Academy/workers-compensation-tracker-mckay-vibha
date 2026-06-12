/**
 * Claim trigger that uses the Trigger Framework with a Virtual Class
 * TriggerHandler Source: https://github.com/kevinohara80/sfdc-trigger-framework
 * @see <a href="https://www.apexhours.com/trigger-framework-in-salesforce/">Trigger Frameworks in Salesforce</a>
 */
trigger ClaimTrigger on Claim__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new ClaimTriggerHandler().run();
    
}