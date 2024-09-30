import { LightningElement,api, wire, track } from 'lwc';
import Leave_Application from '@salesforce/schema/Leave_Application__c';
import approveReject from '@salesforce/apex/LeaveApplicationController.approveRejectRequest';

//import platformShowToastEvent to display toast message
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { publish, MessageContext } from 'lightning/messageService';
import APPLICATION_STATUS_CHANNEL from '@salesforce/messageChannel/Send_Application_Status__c';

export default class LeaveApprovalRejection extends LightningElement {
        //record id
        @api recordId;

        //object info
        objectApiName = Leave_Application;
    
        //variable to pass in the apex method as parameter
        @track isRequestApproved = false;
        @track managerComments;


        @wire(MessageContext) messageContext;

        
        //handleApprove function to send the approve request to apex.
        handleApprove(){
            this.isRequestApproved = true;
            this.sendRequest();
        }
    
        //handleReject function is to send the rejection request to apex. 
        handleReject(){
            this.sendRequest();
        }
        sendRequest(){
            //call the apex method with, sending  1. leave application record id 2. approval or rejection
            approveReject({ recordId : this.recordId, isApproved : this.isRequestApproved, managerComments: this.managerComments })
                .then((result) => {
                    
                    //if record is approved
                    if(result == 'Approved'){
                        
                        //display toast message
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: "Success ! ",
                                message: 'The leave has been approved!',
                                variant: "success"
                            })
                        );
                       
                    }
                    //if record is rejected
                    else if(result =='Rejected'){
                       
                        //display toast message
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: "Success ! ",
                                message: 'The leave has been rejected!',
                                variant: "success"
                            })
                        );
                        
                    }
                    else{
                       
                         //display toast message
                         this.dispatchEvent(
                            new ShowToastEvent({
                                title: "Error ! ",
                                message: result,
                                variant: "error"
                            })
                        );
                        
                    }
                    
                    //publish message to the Send_Application_Status__c to close modal
                    const payload = { recordId: this.recordId, approvalStatus: result};
                    publish(this.messageContext, APPLICATION_STATUS_CHANNEL, payload);
                    this.error = undefined;
                })
                .catch((error) => {
                    
                    this.error = error;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: "Error ",
                            message: 'Leave is already approved/rejected.',
                            variant: "error"
                        })
                    );
                });
        }
}