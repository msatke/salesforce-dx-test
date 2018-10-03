public class OppAttachmentsRelatedListController {
    
    private List<CombinedAttachment> notesAndAttachments;
    public Id parentObjectId {get; set;}
    
    public OppAttachmentsRelatedListController() {
        if (ApexPages.currentPage() != null) {
			this.parentObjectId = ApexPages.currentPage().getParameters().get('id');
        }
        this.notesAndAttachments = new List<CombinedAttachment>();
    }
    
    public List<CombinedAttachment> getNotesAndAttachments() {
        if (parentObjectId != null) {
            // entity CombinedAttachment doesn't support a direct query
            List<Opportunity> parentOpportunity = [SELECT Id, Name, (SELECT Id, Title, FileType, FileExtension, RecordType, LastModifiedDate, LastModifiedBy.Name FROM CombinedAttachments) FROM Opportunity WHERE Id = :parentObjectId];
            if (parentOpportunity.size() == 1 && parentOpportunity.get(0).CombinedAttachments != null) {
                for (CombinedAttachment attachedItem : parentOpportunity.get(0).CombinedAttachments) {
                    notesAndAttachments.add(attachedItem);
                }
            }
        }
        return this.notesAndAttachments;
    }

}