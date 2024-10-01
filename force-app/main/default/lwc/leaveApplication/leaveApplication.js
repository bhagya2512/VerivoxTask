import { LightningElement, api, wire, track } from 'lwc';

import getMyLeaves from "@salesforce/apex/LeaveApplicationController.getMyLeaves";
import getLeaveTypeValues from "@salesforce/apex/LeaveApplicationController.getLeaveTypeValues";
import calculateTotalDays from "@salesforce/apex/LeaveApplicationController.getTotalLeaveDays";
import getLeaveBalance from "@salesforce/apex/LeaveApplicationController.getLeaveBalance";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import Id from "@salesforce/user/Id";
import { refreshApex } from "@salesforce/apex";


const COLUMNS = [
    {
        label: "Application Id",
        fieldName: "Name",
        cellAttributes: { class: { fieldName: "cellClass" } }
    },
    {
        label: "Start Date",
        fieldName: "Start_Date__c",
        cellAttributes: { class: { fieldName: "cellClass" } }
    },
    {
        label: "End Date",
        fieldName: "End_Date__c",
        cellAttributes: { class: { fieldName: "cellClass" } }
    },
    {
        label: "Type",
        fieldName: "Type__c",
        cellAttributes: { class: { fieldName: "cellClass" } }
    },
    {
        label: "Number of Days",
        fieldName: "Number_of_Days__c",
        cellAttributes: { class: { fieldName: "cellClass" } }
    },
    {
        label: "Status",
        fieldName: "Status__c",
        cellAttributes: { class: { fieldName: "cellClass" } }
    },
    {
        type: "button",
        typeAttributes: {
            label: "Edit",
            name: "Edit",
            title: "Edit",
            value: "edit",
            disabled: { fieldName: "isEditDisabled" }
        }
    }
];



export default class LeaveApplication extends LightningElement {
    columns = COLUMNS;
    options = [
        { label: 'Vacation', value: 'Vacation' },
        { label: 'Business Trip', value: 'Business Trip' },
        { label: 'Other', value: 'Other' }];
    myLeaves = [];
    @track leaveType;
    @track cuurentLeaveStatus = "Draft";
    @track myLeavesWireResult;
    @track showModalPopup = false;
    @api objectApiName = "Leave_Application__c";
    @track recordId = "";
    @track currentUserId = Id;
    @track startDate;
    @track endDate;
    @track type;
    @track leaveType;
    @track leaveStatus;
    @track leaveDayCount;
    @track leaveBalance;
    @track leaveBalanceAfterApproval;
    @api refreshGrid() {
        refreshApex(this.myLeavesWireResult);
    }

    initializeFields() {
        this.recordId = "";
        this.startDate = "";
        this.endDate = "";
        this.type = "";
        this.leaveType = "";
        this.leaveStatus = "Draft";
        this.leaveDayCount = "";
        getLeaveBalance()
            .then(result => {
                console.log("Result is ", result);
                this.leaveDayCount = result.currentBalance;
                this.error = undefined;}
            );
    }

    @wire(getMyLeaves)
    wiredMyLeaves(result) {
        this.myLeavesWireResult = result;
        if (result.data) {
            this.myLeaves = result.data.map((a) => ({
                ...a,
                isEditDisabled: a.Status__c !== "In Progress"
            }));
        }
        if (result.error) {
            console.log("Error occured while fetching leaves - ", result.error);
        }
    }
    @wire(getLeaveTypeValues)
    wiredLeaveTypeValues({ error, data }) {
        if (data) {
            this.typeOptions = data.map(value => {
                return { label: value, value: value };
            });
        } else if (error) {
            console.error('Error fetching picklist values:', error);
        }
    }

    get noRecordsFound() {
        return this.myLeaves.length == 0;
    }

    newRequestClickHandler() {
        this.showModalPopup = true;
        this.initializeFields();
    }
    popupCloseHandler() {
        this.showModalPopup = false;
        this.initializeFields();
    }

    rowActionHandler(event) {
        this.showModalPopup = true;
        this.recordId = event.detail.row.Id;
    }

    successHandler(event) {
        this.showModalPopup = false;
        this.showToast("Sent for Approval");
        refreshApex(this.myLeavesWireResult);
        this.initializeFields();
    }

    submitHandler(event) {
        event.preventDefault();
        const fields = { ...event.detail.fields };
        fields.Status__c = "In Progress";
        fields.Number_of_Days__c = this.leaveDayCount;
        this.refs.leaveRequestForm.submit(fields);
    }
    showToast(message, title = "Success", variant = "success") {
        const event = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(event);
    }
    handleTypeChange(event) {
        this.leaveType = event.detail.value;
    }
    handleStartDate(event) {
        this.startDate = event.detail.value;
        console.log("Start date is ", this.startDate);
    }

    handleLeaveDayCount(event) {
        this.endDate = event.detail.value;
        console.log("Leave day count is ", this.endDate);
        calculateTotalDays({ startDate: this.startDate, endDate: this.endDate })
            .then(result => {
                console.log("Result is ", result);
                this.leaveDayCount = result;
                this.error = undefined;
            })
            .catch(error => {
                this.error = error;
                this.leaveDayCount = undefined;
            });
            this.leaveBalanceAfterApproval  = this.leaveBalance - this.leaveDayCount;
    }
}