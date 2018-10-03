public with sharing class SalesforceFileService {

    /**
     * @param parentId - any sObject that allows files to be attached to it
     * @param fileName
     * @param fileBody
     * @exception
     * @return ContentDocument
     */
    public ContentDocument saveSalesforceFile(Id parentId, String fileName, Blob fileBody) {
        ContentVersion fileVersion = new ContentVersion();
        fileVersion.versionData = fileBody;
        fileVersion.title = getCleanFileName(fileName);
        fileVersion.pathOnClient = 'file_' + Datetime.now().getTime() + fileName;
        fileVersion.Contract__c = true;
        insert fileVersion;
        ContentDocument contentDocument = selectContentDocument(fileVersion);
        insertContentDocumentLinkToParent(contentDocument.Id, parentId);
        return contentDocument;
    }

    private ContentDocument selectContentDocument(ContentVersion fileVersion) {
        List<ContentVersion> contentVersion = [SELECT ContentDocument.Id, ContentDocument.Title FROM ContentVersion WHERE Id = :fileVersion.id];
        if (contentVersion.isEmpty() == false) {
            return new ContentDocument(Id = contentVersion.get(0).ContentDocument.Id, Title = contentVersion.get(0).ContentDocument.Title);
        }
        else {
            return null;
        }
    }

    private void insertContentDocumentLinkToParent(Id contentDocumentId, Id parentId) {
        ContentDocumentLink fileLink = new ContentDocumentLink();
        fileLink.ContentDocumentId = contentDocumentId;
        fileLink.LinkedEntityId = parentId;
        fileLink.ShareType = 'I';
        insert fileLink;
        System.debug(fileLink);
    }

    private String getCleanFileName(String fullName) {
        if (fullName != null) {
            List<String> cleanNameParts = new List<String>();
            List<String> nameParts = fullName.split('\\.');
            for (String namePart : nameParts) {
                // add all nameParts except the last one with file extension
                if (cleanNameParts.size() + 1 < nameParts.size()) {
                    cleanNameParts.add(namePart);
                }
            }
            return String.join(cleanNameParts, '.');
        }
        return fullName;
    }

}