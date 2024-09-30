import { LightningElement, wire, api, track} from 'lwc';
import getLeaveRequests from "@salesforce/apex/LeaveApplicationController.getLeaveRequests";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import Id from "@salesforce/user/Id";
import { FlowNavigationFinishEvent} from 'lightning/flowSupport';
import { refreshApex } from "@salesforce/apex";

import { subscribe,unsubscribe,MessageContext } from 'lightning/messageService';
import APPLICATION_STATUS_CHANNEL from '@salesforce/messageChannel/Send_Application_Status__c';

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
      label: "Approve/Reject",
      name: "Approve/Reject",
      title: "Approve/Reject",
      variant: "brand",
      iconName: "utility:edit",
      value: "edit",
      disabled: { fieldName: "isEditDisabled" }
    },
    cellAttributes: { class: { fieldName: "cellClass" } }
  }
];

export default class LeavesManagerView extends LightningElement {
  columns = COLUMNS;

  @api refreshGrid() {
    refreshApex(this.leavesRequestsWireResult);
  }
  @track leavesReqeusts = [];
  @track leavesRequestsWireResult;
  @track showModalPopup = false;
  @api objectApiName = "Leave_Application__c";
  @api recordId = "";
  @api leaveRecordId = "";
  @api currentUserId = Id;
  @track subscription;
  @track openApprovalFlow = false;
  @wire(getLeaveRequests)
  wiredMyLeaves(result) {
    this.leavesRequestsWireResult = result;
    if (result.data) {
      this.leavesReqeusts = result.data.map((a) => ({
        ...a,
        userName: a.Employee_Name__r.Name,
        isEditDisabled: a.Status__c !== "In Progress"
      }));
    }
    if (result.error) {
      console.log("Error occured while fetching leaves - ", result.error);
    }
  }

  @wire(MessageContext) messageContext;

  connectedCallback() {
    this.subscribeToMessageChannel();
  }

  subscribeToMessageChannel() {
      this.subscription = subscribe(
          this.messageContext,
          APPLICATION_STATUS_CHANNEL,
          (message) => this.handleMessage(message)
      );
  }
  handleMessage(message) {
      if (message.recordId != null){
          this.value = message.approvalStatus;
      }
      this.successHandler();
  }

  get inputVariables() {
    return [
        {
            name: 'recordId',
            type: 'String',
            value: this.leaveRecordId
        }
    ];
}

  get noRecordsFound() {
    return this.leavesReqeusts.length == 0;
  }

  rowActionHandler(event) {
    this.openApprovalFlow = true;
    this.leaveRecordId = event.detail.row.Id;
  }

  successHandler(event) {
    this.refreshGrid();
    this.openApprovalFlow = false;
  }
  handleStatusChange(){
    console.log("Status Flow ");
  }

  handleCloseClick(event) {
    var navigationEvent = new FlowNavigationFinishEvent();
        this.dispatchEvent(navigationEvent);
        this.openApprovalFlow = false;
        this.refreshGrid();
  }
}