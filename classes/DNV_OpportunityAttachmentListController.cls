public without sharing class DNV_OpportunityAttachmentListController {

    private static final String CONTRACT_CONVERTIBLE_ATTACHMENT_RECORD_TYPE_ATTACHMENT = String.valueOf(Attachment.getSObjectType());
    private static final String CONTRACT_CONVERTIBLE_ATTACHMENT_RECORD_TYPE_FILE = 'File';

    private static final List<String> CONTRACT_CONVERTIBLE_ATTACHMENT_RECORD_TYPES_LIST = new List<String>{
            CONTRACT_CONVERTIBLE_ATTACHMENT_RECORD_TYPE_ATTACHMENT,
            CONTRACT_CONVERTIBLE_ATTACHMENT_RECORD_TYPE_FILE
    };

    private List<AttachmentWrapper> combinedAttachmentWrappers;
    private Id opportunityId;
    private DNV_Pagination pagination;
    private DNV_CustomAttachmentService custAttachmentService {
        get {
            if (custAttachmentService == null) {
                custAttachmentService = new DNV_CustomAttachmentService();
            }
            return custAttachmentService;
        }
        private set;
    }
    private DNV_SalesforceFileService salesforceFileService {
        get {
            if (salesforceFileService == null) {
                salesforceFileService = new DNV_SalesforceFileService();
            }
            return salesforceFileService;
        }
        private set;
    }

    public DNV_OpportunityAttachmentListController() {
        this.opportunityId = ApexPages.currentPage().getParameters().get('id');
        this.combinedAttachmentWrappers = new List<AttachmentWrapper>();
    }

    public List<AttachmentWrapper> getCombinedAttachmentWrappers() {
        combinedAttachmentWrappers.clear();
        if (opportunityId != null) {
            for (CombinedAttachment attachedItem : selectCombinedAttachmentsUsingPagination()) {
                combinedAttachmentWrappers.add(new AttachmentWrapper(attachedItem, false));
            }
        }
        return combinedAttachmentWrappers;
    }

    public PageReference saveMarkedContracts() {
        try {
            combinedAttachmentWrappers = populateAttachmentContent(combinedAttachmentWrappers);
            for (AttachmentWrapper attachmentWrapper : combinedAttachmentWrappers) {
                if (attachmentWrapper.isContract == true) {
                    CombinedAttachment attachedItem = attachmentWrapper.attachment;
                    if (attachedItem.id.getSobjectType() == Attachment.SObjectType) {
                        convertAttachmentToContracts(attachmentWrapper);
                    }
                    else if (attachedItem.id.getSobjectType() == ContentDocument.SObjectType) {
                        moveSfFilesToContracts(attachmentWrapper);
                    }
                }
            }
        } catch (Exception e) {
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Could not save attachment.'));
            System.debug('Could not save attachment! Exception detials: ' + e);
            return null;
        }
        return navigateBack();
    }

    private List<AttachmentWrapper> populateAttachmentContent(List<AttachmentWrapper> combinedAttachmentWrappers) {
        Set<Id> sfFileIds = new Set<Id>();
        Set<Id> attachmentIds = new Set<Id>();
        Map<Id, AttachmentWrapper> attachmentWrapperMap = new Map<Id, AttachmentWrapper>();
        for (AttachmentWrapper attachmentWrapper : combinedAttachmentWrappers) {
            CombinedAttachment attachedItem = attachmentWrapper.attachment;
            if (attachedItem.id.getSobjectType() == ContentDocument.SObjectType && attachmentWrapper.isContract == true) {
                sfFileIds.add(attachedItem.id);
            }
            else if (attachedItem.id.getSobjectType() == Attachment.SObjectType && attachmentWrapper.isContract == true) {
                attachmentIds.add(attachedItem.id);
            }
            attachmentWrapperMap.put(attachedItem.id, attachmentWrapper);
        }

        List<ContentDocument> sfFiles = [SELECT Id, Title, (SELECT Id FROM ContentDocumentLinks WHERE LinkedEntityId = :this.opportunityId) FROM ContentDocument WHERE Id IN :sfFileIds];
        List<Attachment> attachments = [SELECT Id, Name, Body FROM Attachment WHERE Id IN :attachmentIds];

        for (ContentDocument file : sfFiles) {
            if (attachmentWrapperMap.containsKey(file.id) && file.ContentDocumentLinks.isEmpty() == false) {
                attachmentWrapperMap.get(file.id).fileLinkObjectIdToParent = file.ContentDocumentLinks.get(0).id;
            }
        }

        for (Attachment attachment : attachments) {
            if (attachmentWrapperMap.containsKey(attachment.id)) {
                attachmentWrapperMap.get(attachment.id).fileBody = attachment.Body;
            }
        }
        return attachmentWrapperMap.values();
    }

    private void moveSfFilesToContracts(AttachmentWrapper attachmentWrapper) {
        DNV_Custom_Attachment__c createdCustomAttachment = custAttachmentService.createCustomAttachment(new Opportunity(Id = opportunityId), DNV_CustomAttachmentService.CUSTOM_ATTACHMENT_TYPE_CONTRACT, '');
        custAttachmentService.attachFileToCustomAttachment(createdCustomAttachment, new ContentDocument(Id = attachmentWrapper.attachment.id, Title = attachmentWrapper.attachment.Title));
        insert new ContentDocumentLink(ContentDocumentId = attachmentWrapper.attachment.id, LinkedEntityId = createdCustomAttachment.id, ShareType = 'I');
        delete new ContentDocumentLink(Id = attachmentWrapper.fileLinkObjectIdToParent);
    }

    private void convertAttachmentToContracts(AttachmentWrapper attachmentWrapper) {
        DNV_Custom_Attachment__c createdCustomAttachment = custAttachmentService.createCustomAttachment(new Opportunity(Id = opportunityId), DNV_CustomAttachmentService.CUSTOM_ATTACHMENT_TYPE_CONTRACT, '');
        createdCustomAttachment = custAttachmentService.populateCustomAttachmentByOriginalAttachmentData(createdCustomAttachment, attachmentWrapper.attachment);
        ContentDocument createdContentDocument = salesforceFileService.saveSalesforceFile(createdCustomAttachment.Id, attachmentWrapper.attachment.Title, attachmentWrapper.fileBody);
        // update the custom attachment record with some attachment info
        custAttachmentService.attachFileToCustomAttachment(createdCustomAttachment, createdContentDocument);
        // remove old attachment (some information were already moved to the custom attachment object like created date, ...)
        delete new Attachment(Id = attachmentWrapper.attachment.id, ParentId = createdCustomAttachment.id);
    }

    public class AttachmentWrapper {
        public CombinedAttachment attachment {get; set;}
        public Boolean isContract {get; set;}
        public transient Blob fileBody {get;set;}
        public Id fileLinkObjectIdToParent {get; set;}

        public AttachmentWrapper() {
            this.isContract = false;
        }

        public AttachmentWrapper(CombinedAttachment attachment, Boolean isContract) {
            this.attachment = attachment;
            this.isContract = isContract;
        }
    }

    public PageReference navigateBack() {
        return new PageReference('/'+opportunityId);
    }

    public DNV_Pagination getPagination() {
        if (this.pagination == null) {
            initPagination();
        }
        return this.pagination;
    }

    private List<CombinedAttachment> selectCombinedAttachmentsUsingPagination() {
        // entity CombinedAttachment doesn't support a direct query
        String mainAttachmentsQuery = 'SELECT Id, Name, (SELECT Id, Title, RecordType, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById FROM CombinedAttachments';
        mainAttachmentsQuery += ' WHERE RecordType IN (:CONTRACT_CONVERTIBLE_ATTACHMENT_RECORD_TYPE_ATTACHMENT, :CONTRACT_CONVERTIBLE_ATTACHMENT_RECORD_TYPE_FILE)';
        mainAttachmentsQuery += ' ORDER BY LastModifiedDate DESC';
        if (getPagination().getLimit() > 0) {
            mainAttachmentsQuery += ' LIMIT ' + getPagination().getLimit();
        }
        if (getPagination().getOffset() > 0) {
            mainAttachmentsQuery += ' OFFSET ' + getPagination().getOffset();
        }
        mainAttachmentsQuery += ') FROM Opportunity WHERE Id = :opportunityId LIMIT 1';
        Opportunity parentOpp = Database.query(mainAttachmentsQuery);
        if (parentOpp != null && parentOpp.CombinedAttachments != null) {
            return parentOpp.CombinedAttachments;
        }
        return new List<CombinedAttachment>();
    }

    public String query {
        get; set;
    }

    private Integer selectCountOfCombinedAttachments() {
        // entity CombinedAttachment doesn't support a direct query
        List<Opportunity> oppsWithCombinedAttachments = [SELECT Id, (SELECT Id FROM CombinedAttachments WHERE RecordType IN (:CONTRACT_CONVERTIBLE_ATTACHMENT_RECORD_TYPE_ATTACHMENT, :CONTRACT_CONVERTIBLE_ATTACHMENT_RECORD_TYPE_FILE)) FROM Opportunity WHERE Id = :opportunityId];
        if (oppsWithCombinedAttachments.isEmpty() == false) {
            if (oppsWithCombinedAttachments.get(0).CombinedAttachments != null) {
                return oppsWithCombinedAttachments.get(0).CombinedAttachments.size();
            }
        }
        return 0;
    }

    private void initPagination() {
        Integer recordTotalCount = selectCountOfCombinedAttachments();
        this.pagination = DNV_Pagination.getPaginationInstance('DNV_OpportunityAttachmentListController', recordTotalCount);
    }

}