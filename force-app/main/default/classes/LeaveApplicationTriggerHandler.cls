public with sharing class LeaveApplicationTriggerHandler {


    public void sendLeaveUpdateInformation(List<Leave_Application__c> approvedLeaves, Map<Id,Leave_Application__c> oldMap) {
        for (Leave_Application__c leave : approvedLeaves) {
            Leave_Application__c oldLeave = oldMap.get(leave.Id);
            if (leave.Status__c == 'Approved' && oldLeave.Status__c != 'Approved') {
                approvedLeaves.add(leave);
            }
        }
    
        if (!approvedLeaves.isEmpty()) {
            // Call method to update ERP system
            updateERPSystem(approvedLeaves);
        }
    }

    private void updateERPSystem(List<Leave_Application__c> approvedLeaves) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://your-erp-system/api/updateVacationBalance');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
    
        for (Leave_Application__c leave : approvedLeaves) {
            String jsonBody = JSON.serialize(new Map<String, Object>{
                'email' => leave.Employee_Name__r.Email,
                'updatedBalance' => calculateNewBalance(leave)
            });
            request.setBody(jsonBody);
    
            // Send the request
            HttpResponse response = http.send(request);
    
            // Log the response
            System.debug('ERP Update Response: ' + response.getBody());
            System.debug('Response Status Code: ' + response.getStatusCode());
        }
    }

    private Decimal calculateNewBalance(Leave_Application__c leave) {
        Decimal newBalance;
        List<User> userInfo = [ SELECT Id, Name, Email, Current_Leave_Balance__c, Leave_Days_To_Be_Approved__c, ManagerId
                                FROM User
                                WHERE Id = :leave.Employee_Name__c
                                ORDER BY CreatedDate DESC];
            for (User user : userInfo) {
                newBalance = user.Current_Leave_Balance__c;
            }
        return newBalance;
        
    }
}