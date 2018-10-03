/**
 * Created by Martin Satke on 16-Apr-18.
 */

public with sharing class DNV_CustomAttachmentService {

    public static final String CUSTOM_ATTACHMENT_TYPE_CONTRACT = 'Contract';

    public DNV_CustomAttachmentService() {}

    public DNV_Custom_Attachment__c createCustomAttachment(SObject parentObject, String attachmentType, String description) {
        DNV_Custom_Attachment__c customAttachment = new DNV_Custom_Attachment__c();
        customAttachment.description__c = description;
        customAttachment.type__c = attachmentType;
        customAttachment = updateParentReference(parentObject, customAttachment);
        insert customAttachment;
        return customAttachment;
    }

    private DNV_Custom_Attachment__c updateParentReference(sObject parentObject, DNV_Custom_Attachment__c customAttachment) {
        if (parentObject != null) {
            if (parentObject instanceof Schema.Opportunity) {
                customAttachment.Opportunity__c = parentObject.Id;
            }
        }
        return customAttachment;
    }

    public DNV_Custom_Attachment__c attachFileToCustomAttachment(DNV_Custom_Attachment__c customAttachment, ContentDocument fileToAttach) {
        customAttachment.name = fileToAttach.Title;
        customAttachment.Attachment__c = fileToAttach.id;
        customAttachment = populateOriginalDataOfCreatedContract(customAttachment);
        update customAttachment;
        return customAttachment;
    }

    private DNV_Custom_Attachment__c populateOriginalDataOfCreatedContract(DNV_Custom_Attachment__c customAttachment) {
        customAttachment.Original_Created_Date__c = customAttachment.CreatedDate;
        customAttachment.Original_Created_By__c = customAttachment.CreatedById;
        customAttachment.Original_Last_Modified_Date__c = customAttachment.LastModifiedDate;
        customAttachment.Original_Last_Modified_By__c = customAttachment.LastModifiedById;
        return customAttachment;
    }

    public DNV_Custom_Attachment__c populateCustomAttachmentByOriginalAttachmentData(DNV_Custom_Attachment__c customAttachment, CombinedAttachment originalAttachment) {
        customAttachment.Original_Created_Date__c = originalAttachment.CreatedDate;
        customAttachment.Original_Created_By__c = originalAttachment.CreatedById;
        customAttachment.Original_Last_Modified_Date__c = originalAttachment.LastModifiedDate;
        customAttachment.Original_Last_Modified_By__c = originalAttachment.LastModifiedById;
        return customAttachment;
    }
}