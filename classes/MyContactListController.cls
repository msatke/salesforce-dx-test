public class MyContactListController {
    
    private static Id accountId {get; set;}

    @AuraEnabled
    public static List<Contact> getContacts() {
        // System.debug(accountId);
        //c = '001w0000019xGksAAE'; 
        return [Select Id, Name, Email, Title, Phone, AccountId, Account.Name From Contact WHERE AccountId = :accountId];
    }
}