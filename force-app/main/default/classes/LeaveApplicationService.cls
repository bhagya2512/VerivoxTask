@RestResource(urlMapping='/leaveApplications/*')
global with sharing class LeaveApplicationService {
// Endpoint URL : /services/apexrest/leaveApplications/b.mandlik@gmail.com
    @HttpGet
    global static LeaveApplicationResponse doGet() {
        RestRequest req = RestContext.request;
        String email = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);

        // Validate email
        if (String.isEmpty(email) || !isValidEmail(email)) {
            RestContext.response.statusCode = 400; // Bad Request
            return new LeaveApplicationResponse('Invalid email address1');
        }

        // Get current financial year (e.g., April to March)
        Date startOfFinancialYear = Date.newInstance(Date.today().year(), 4, 1);
        Date endOfFinancialYear = Date.newInstance(Date.today().year() + 1, 3, 31);

        // Query leave applications
        List<Leave_Application__c> leaveApplications = [
            SELECT Id, Start_Date__c, End_Date__c, Status__c 
            FROM Leave_Application__c 
            WHERE Employee_Name__r.Email = :email 
            AND Start_Date__c >= :startOfFinancialYear 
            AND End_Date__c <= :endOfFinancialYear
        ];

        return new LeaveApplicationResponse(leaveApplications);
    }

    private static Boolean isValidEmail(String email) {
        // Basic email validation
        Pattern emailPattern = Pattern.compile('^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$');
        Matcher matcher = emailPattern.matcher(email);
        return matcher.matches();
    }
    
    global class LeaveApplicationResponse {
        public String message;
        public List<Leave_Application__c> leaveApplications;

        public LeaveApplicationResponse(String message) {
            this.message = message;
            this.leaveApplications = new List<Leave_Application__c>();
        }

        public LeaveApplicationResponse(List<Leave_Application__c> leaveApplications) {
            this.message = 'Success';
            this.leaveApplications = leaveApplications;
        }
    }
}
