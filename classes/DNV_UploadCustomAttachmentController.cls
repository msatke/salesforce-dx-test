/**
 * Created by Martin Satke on 12-Apr-18.
 */

public class DNV_UploadCustomAttachmentController {

    public String selectedType {get;set;}
    public String description {get;set;}
    private sObject parentObject {get;set;}
    public String fileName {get;set;}
    public transient Blob fileBody {get;set;}

    public DNV_UploadCustomAttachmentController(ApexPages.StandardController controller) {
        this.parentObject = controller.getRecord();
    }

    /**
    * Upload process is:
    *  1. Insert new Contact_Attachment__c record
    *  2. Insert new Attachment with the new Contact_Attachment__c record as parent
    *  3. Update the Contact_Attachment__c record with the ID of the new Attachment
    **/
    public PageReference processUpload() {
        try {
            DNV_Custom_Attachment__c createdCustomAttachment = new DNV_CustomAttachmentService().createCustomAttachment(parentObject, selectedType, description);
            ContentDocument createdFile = new SalesforceFileService().saveSalesforceFile(createdCustomAttachment.id, this.fileName, this.fileBody);

            // update the custom attachment record with some attachment info
            new DNV_CustomAttachmentService().attachFileToCustomAttachment(createdCustomAttachment, createdFile);

        } catch (Exception e) {
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Could not save attachment.'));
            System.debug('Could not save attachment! Exception detials: ' + e);
            return null;
        }

        return new PageReference('/'+parentObject.Id);
    }

    public PageReference navigateBack() {
        return new PageReference('/'+parentObject.Id);
    }

    public List<SelectOption> getTypeOptions() {
        List<SelectOption> typePicklistOptions = new List<SelectOption>();
        Schema.DescribeFieldResult typeDescribeResult = DNV_Custom_Attachment__c.Type__c.getDescribe();
        List<PicklistEntry> typeEntries = typeDescribeResult.getPicklistValues();
        for(PicklistEntry typeEntry: typeEntries){
            typePicklistOptions.add(new SelectOption(typeEntry.getLabel(), typeEntry.getValue()));
        }
        return typePicklistOptions;
    }



}