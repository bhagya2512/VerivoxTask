trigger LeaveApplicationTrigger on Leave_Application__c (after update) {
       LeaveApplicationTriggerHandler.sendLeaveUpdateInformation(Trigger.new, Trigger.oldMap);
}