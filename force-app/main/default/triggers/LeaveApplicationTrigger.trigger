trigger LeaveApplicationTrigger on Leave_Application__c (after update) {
        if(Trigger.isUpdate){
            if(Trigger.isAfter){
              LeaveApplicationTriggerHandler.sendLeaveUpdateInformation(Trigger.new, Trigger.oldMap);
            }
       }

}