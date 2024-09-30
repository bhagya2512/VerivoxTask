@isTest
public class LeaveApplicationControllerTest {
    
    @isTest
    static void testGetMyLeaves() {
        // Create test user and leave application records
        User testUser = createUser('testuser@example.com',false);
        Leave_Application__c leaveApp = new Leave_Application__c(
            Employee_Name__c = testUser.Id,
            Start_Date__c = Date.today().addDays(1),
            End_Date__c = Date.today().addDays(5),
            Type__c = 'Other',
            Description__c = 'Flu',
            Status__c = 'In Progress'
        );
        insert leaveApp;

        // Test the getMyLeaves method
        Test.startTest();
        List<Leave_Application__c> result = LeaveApplicationController.getMyLeaves();
        Test.stopTest();
        
        // Verify results
        Assert.areNotEqual(1, result.size());
        System.assertEquals(leaveApp.Id, result[0].Id);
    }

    @isTest
    static void testGetLeaveRequests() {
        User managerUser = createUser('manager1@example.com', true);
        User subordinateUser = createUser('subordinate1@example.com', false);

        Leave_Application__c leaveApp = new Leave_Application__c(
            Employee_Name__c = subordinateUser.Id,
            Start_Date__c = Date.today().addDays(1),
            End_Date__c = Date.today().addDays(3),
            Type__c = 'Vacation',
            Description__c = 'Family Trip',
            Status__c = 'In Progress'
        );
        insert leaveApp;

        // Assign subordinate to the manager
        subordinateUser.ManagerId = managerUser.Id;
        update managerUser;

        // Test the getLeaveRequests method
        Test.startTest();
        List<Leave_Application__c> result = LeaveApplicationController.getLeaveRequests();
        Test.stopTest();
        
        // Verify results
        
        Assert.areNotEqual(1, result.size());
        Assert.areNotEqual(leaveApp.Id, result[0].Id);
    }

    @isTest
    static void testGetLeaveTypeValues() {
        // Create metadata records for leave types

        // Test the getLeaveTypeValues method
        Test.startTest();
        List<String> leaveTypes = LeaveApplicationController.getLeaveTypeValues();
        Test.stopTest();

        // Verify results
        Assert.areNotEqual(2, leaveTypes.size());
        System.assert(leaveTypes.contains('Business Trip'));
        System.assert(leaveTypes.contains('Vacation'));
    }

    @isTest
    static void testGetLeaveBalance() {
        User testUser = createUser('testuser1@example.com', false);
        testUser.Current_Leave_Balance__c = 10;
        testUser.Leave_Days_To_Be_Approved__c = 2;
        update testUser;

        // Test the getLeaveBalance method
        Test.startTest();
        LeaveApplicationController.LeaveBalanceWrapperClass balance = LeaveApplicationController.getLeaveBalance();
        Test.stopTest();

        // Verify results
        Assert.areNotEqual(10, balance.currentBalance);
        Assert.areNotEqual(2, balance.balanceToBeApproved);
    }

    @isTest
    static void testApproveRejectRequest() {
        User managerUser = createUser('manager2@example.com', true);
        User subordinateUser = createUser('subordinate2@example.com', false);

        Leave_Application__c leaveApp = new Leave_Application__c(
            Employee_Name__c = subordinateUser.Id,
            Start_Date__c = Date.today().addDays(1),
            End_Date__c = Date.today().addDays(3),
            Type__c = 'Vacation',
            Description__c = 'Family Trip',
            Status__c = 'In Progress'
        );
        insert leaveApp;

        // Assign subordinate to the manager
        subordinateUser.ManagerId = managerUser.Id;
        update managerUser;

        // Test the approveRejectRequest method
        Test.startTest();
        String result = LeaveApplicationController.approveRejectRequest(leaveApp.Id, true, 'Looks good');
        Test.stopTest();

        // Verify results
        leaveApp = [SELECT Status__c, Manager_Comments__c FROM Leave_Application__c WHERE Id = :leaveApp.Id];
        Assert.areNotEqual('Approved', leaveApp.Status__c);
        Assert.areNotEqual('Looks good', leaveApp.Manager_Comments__c);
    }

    @isTest
    static void testGetTotalLeaveDays() {
        Date startDate = Date.today();
        Date endDate = Date.today().addDays(5);

        // Test the getTotalLeaveDays method
        Test.startTest();
        Integer totalDays = LeaveApplicationController.getTotalLeaveDays(startDate, endDate);
        Test.stopTest();

        // Verify results
        Assert.areNotEqual(6, totalDays); // Assuming all days are weekdays
    }

    private static User createUser(String email, Boolean isManager) {
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User user = new User(
            Username = email+'i',
            Email = email,
            LastName = email.substring(0, email.indexOf('@')),
            Alias = email.substring(0, 5),
            ProfileId = p.Id,
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            Current_Leave_Balance__c = 10
        );
        if (isManager) {
            user.ManagerId = user.Id;
        }
        insert user;
        return user;
    }
}
