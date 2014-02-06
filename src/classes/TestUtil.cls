@isTest
public class TestUtil {
    public static Parent__c createParent(String textFieldValue, Boolean doInsert) {
        Parent__c parent = new Parent__c();
        parent.Text_Field__c = textFieldValue;

        if(doInsert) {
            insert parent;
        }

        return parent;
    }

    public static Child__c createChild(Id parentId, Boolean doInsert) {
        Child__c child = new Child__c();
        child.Parent__c = parentId;

        if(doInsert) {
            insert child;
        }

        return child;
    }
}