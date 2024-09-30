import { LightningElement , wire, api, track } from 'lwc';
import getLeaveBalance from "@salesforce/apex/LeaveApplicationController.getLeaveBalance";
import checkIfUserisManager from "@salesforce/apex/LeaveApplicationController.checkIfUserisManager";
import recordId from "@salesforce/user/Id";

export default class LeaveApplicationMainTabs extends LightningElement {
    @api recordId = recordId;
    netBalance = {};
    @track isManager = false;
    @wire(getLeaveBalance)
    wiredLeaveBalance(result) {
        this.netBalance = result.data ? result.data : {};
    }
    @wire(checkIfUserisManager, {recordId:'$recordId'})
    wiredcheckIfUserisManager(result) {
        this.isManager = result.data;
    }
}