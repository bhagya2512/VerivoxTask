public with sharing class LeaveApplicationController {
    /**
     * Retrieves the current user's leave requests from the Leave_Request__c object.
     * @return A list of Leave_Request__c records for the current user.
     */
    @AuraEnabled(cacheable=true)
    public static List<Leave_Application__c> getMyLeaves() {
        try {
            // Query to fetch leave requests for the current user
            List<Leave_Application__c> leaveApplications = [
                SELECT
                    Id,
                    Name,
                    Start_Date__c,
                    End_Date__c,
                    Type__c,
                    Description__c,
                    Number_of_Days__c,
                    Manager_Comments__c,Current_Leave_Balance__c,
                    Status__c
                FROM Leave_Application__c
                WHERE Employee_Name__c = :UserInfo.getUserId()
                ORDER BY CreatedDate DESC];

            return leaveApplications;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Retrieves leave requests for the subordinates of the current user.
     * @return A list of Leave_Request__c records for the current user's subordinates.
     */
    @AuraEnabled(cacheable=true)
    public static List<Leave_Application__c> getLeaveRequests() {
        try {
            // Query to fetch leave requests for subordinates of the current user
            List<Leave_Application__c> leaveApplications = [
                SELECT
                    Id,
                    Name,
                    Start_Date__c,
                    End_Date__c,
                    Type__c,
                    Description__c,
                    Manager_Comments__c,
                    Status__c,
                    Number_of_Days__c,Current_Leave_Balance__c,
                    Employee_Name__r.ManagerId,
                    Employee_Name__r.Name
                FROM Leave_Application__c
                WHERE Employee_Name__r.ManagerId = :UserInfo.getUserId()
                ORDER BY CreatedDate DESC];
            return leaveApplications;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Retrieve the Picklist Values for the Leave Type field
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getLeaveTypeValues() {
        List<String> leaveTypeList = new List<String>();
        
        // Fetch values from custom metadata
        List<Leave_Types__mdt> leaveTypes = [SELECT LeaveType__c FROM Leave_Types__mdt];

        for (Leave_Types__mdt lt : leaveTypes) {
            leaveTypeList.add(lt.LeaveType__c);
        }
        
        return leaveTypeList;
    }

    @AuraEnabled(cacheable=true)
    public static Boolean checkIfUserisManager(Id recordId) {
        Boolean userIsManager = false;

        List<User> userDetails = [SELECT Id, ManagerId FROM User where ManagerId=:recordId];
        System.debug('User' + userDetails);
        if(!userDetails.isEmpty() ){
            userIsManager = true;
        }else{
            userIsManager = false;
        }
        return userIsManager;
    }

    /**
     * Retrieves and calculates the current user's leave balance.
     * @return An instance of LeaveBalance with calculated leave hours.
     */
    @AuraEnabled(cacheable=true)
    public static LeaveBalanceWrapperClass getLeaveBalance() {
        LeaveBalanceWrapperClass leaveBalance = new LeaveBalanceWrapperClass();
        try {
            List<User> userInfo = [ SELECT Id, Name, Email, Current_Leave_Balance__c, Leave_Days_To_Be_Approved__c, ManagerId
                                FROM User
                                WHERE Id = :UserInfo.getUserId()
                                ORDER BY CreatedDate DESC];
            for (User user : userInfo) {
                leaveBalance.currentBalance = user.Current_Leave_Balance__c;
                leaveBalance.balanceToBeApproved = user.Leave_Days_To_Be_Approved__c;
            }
        return leaveBalance;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Method to calculate the total number of weekdays between two dates.
     * @param startDate The start date of the period.
     * @param endDate The end date of the period.
     * @return The total number of weekdays in the given date range.
     */
    @AuraEnabled(cacheable=true)
    public static Integer getTotalLeaveDays(Date startDate, Date endDate) {
        Date start = startDate;
        Date endDateCalc = endDate;
        
        Integer totalDays = 0;
        BusinessHours workingHours = [SELECT Id FROM BusinessHours WHERE IsDefault = true limit 1];
        System.debug(workingHours);

        System.debug('startDate' + startDate);
        System.debug('workingHours' + workingHours);
        System.debug('endDateCalc' + endDateCalc);

            // Add 1 day to include the end date in the calculation
            while(start <= endDateCalc){

                System.debug('in while');
                if(BusinessHours.isWithin(workingHours.Id, start)){
                    totalDays++;
                }
                start = start.addDays(1);
        }

        return totalDays;
    }


    @AuraEnabled
    public static String approveRejectRequest(String recordId, Boolean isApproved, String managerComments){
        try{
            String resultString = isApproved ? 'Approved': 'Rejected';
           
            Leave_Application__c leaveRequest = [Select Employee_Name__c, Status__c , Manager_Comments__c from Leave_Application__c where id=:recordId];
            User userDetails = [SELECT ManagerID FROM User where id=:leaveRequest.Employee_Name__c];
            //check if current user is manager of requester.
            Boolean isCurrentUserManagerOfRecordOwner  = (userDetails.ManagerID == UserInfo.getUserId() )? true:false;
            
            if(isCurrentUserManagerOfRecordOwner){
                if(leaveRequest != null){
                    if(isApproved){
                        leaveRequest.Status__c = 'Approved';
                        leaveRequest.Manager_Comments__c = managerComments;
                    } else{
                    //to reject use 'Reject'
                        leaveRequest.Status__c = 'Not Approved';
                        leaveRequest.Manager_Comments__c = managerComments;
                    }
                }  
                Database.SaveResult saveResult = Database.update(leaveRequest);
                if (!saveResult.isSuccess()) { 
                    return resultString;
                }
                return resultString;
            }
            else{
                return 'Only the Manager can Approve/Reject leves';
            }
        }
        catch(Exception e){ throw new AuraHandledException(e.getMessage()); }
    }



    /**
     * Wrapper class to handle leave balance calculation.
     */
    public class LeaveBalanceWrapperClass {
        @AuraEnabled
        public Decimal currentBalance { get; set; }
        @AuraEnabled
        public Decimal balanceToBeApproved { get; set; }
    }
}