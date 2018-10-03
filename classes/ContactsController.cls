public class ContactsController {
   @AuraEnabled
   public static List<Contact> getContacts() {
       String test = 'test';
       return [SELECT Id, name, email, phone, accountId
       FROM Contact ORDER BY createdDate ASC];
   }   
}