@isTest
private class DMLBoxTest {
    static final String OLD_TEXT_FIELD_VALUE = 'Scully';
    static final String NEW_TEXT_FIELD_VALUE = 'Mulder';

    static Parent__c parent;
    static Child__c child;
    static DMLBox dmlBox;

    static void setup(Boolean insertChild) {
        parent = TestUtil.createParent(OLD_TEXT_FIELD_VALUE, true);
        child = TestUtil.createChild(parent.Id, insertChild);
        dmlBox = new DMLBox();
    }

    static testMethod void testSafeInsert_success() {
        setup(false);
        dmlBox.add(child, new List<Sobject>{parent});

        Test.startTest();
            List<Database.SaveResult> results = dmlBox.safeInsert();
        Test.stopTest();

        System.assertEquals(1, results.size(), 'A result should get included');

        List<Child__c> children = [
            SELECT Id
            FROM Child__c
            WHERE Parent__c = :parent.Id
        ];

        System.assertEquals(1, children.size(), 'There should be 1 child associated with the parent when inserting a valid child' );
    }

    static testMethod void testSafeInsert_failure() {
        setup( false );
        dmlBox.add(child, parent);

        Test.startTest();
            child.OwnerId = parent.Id;

            List<Database.SaveResult> results = dmlBox.safeInsert();
        Test.stopTest();

        System.assertEquals(1, results.size(), 'A result should get included');

        List<Child__c> children = [
            SELECT Id
            FROM Child__c
            WHERE Parent__c = :parent.Id
        ];

        System.assert(children.isEmpty(), 'There should be no children associated with the parent when inserting an invalid child');
    }

    static testMethod void testSafeUpdate_success() {
        setup(true);
        dmlBox.add(parent, child);

        Test.startTest();
            parent.Text_Field__c = NEW_TEXT_FIELD_VALUE;

            List<Database.SaveResult> results = dmlBox.safeUpdate();
        Test.stopTest();

        System.assertEquals(1, results.size(), 'There should be a result');

        parent = [
            SELECT Text_Field__c
            FROM Parent__c
            WHERE Id = :parent.Id
        ];

        System.assertEquals(NEW_TEXT_FIELD_VALUE, parent.Text_Field__c, 'Safe updating a valid parent should succeed');
    }

    static testMethod void testSafeUpdate_failure() {
        setup(true);
        dmlBox.add(parent, child);

        Test.startTest();
            parent.Text_Field__c = NEW_TEXT_FIELD_VALUE;
            parent.OwnerId = parent.Id;

            List<Database.SaveResult> results = dmlBox.safeUpdate();
        Test.stopTest();

        System.assertEquals(1, results.size(), 'There should be a result');

        parent = [
            SELECT Text_Field__c
            FROM Parent__c
            WHERE Id = :parent.Id
        ];

        System.assertEquals(OLD_TEXT_FIELD_VALUE, parent.Text_Field__c, 'The update should have gracefully failed and not set any field');
    }

    static testMethod void testSafeDelete_success() {
        setup(true);
        dmlBox.add(child, parent);

        Test.startTest();
            List<Database.DeleteResult> results = dmlBox.safeDelete();
        Test.stopTest();

        System.assertEquals(1, results.size(), 'There should be a result');

        List<Child__c> children= [
            SELECT Id
            FROM Child__c
            WHERE Parent__c = :parent.Id
        ];

        System.assert(children.isEmpty(), 'Safe deleting a record should succeed');
    }

    static testMethod void testSafeDelete_failure() {
        setup(true);
        dmlBox.add(child, parent);

        Test.startTest();
            delete child;

            List<Database.DeleteResult> results = dmlBox.safeDelete();
        Test.stopTest();

        System.assertEquals(1, results.size(), 'There should be a result');

        List<Child__c> children= [
            SELECT Id
            FROM Child__c
            WHERE Parent__c = :parent.Id
        ];

        System.assert(children.isEmpty(), 'Safe deleting an already deleted record should not create any new records in the database');
    }

    static testMethod void testSafeUndelete_success() {
        setup(true);
        dmlBox.add(child, parent);

        Test.startTest();
            delete child;

            List<Database.UndeleteResult> results = dmlBox.safeUndelete();
        Test.stopTest();

        System.assertEquals(1, results.size(), 'There should be a result');

        List<Child__c> children= [
            SELECT Id
            FROM Child__c
            WHERE Parent__c = :parent.Id
        ];

        System.assertEquals(1, children.size(), 'Safely undeleting a deleted record should bring back the record');
    }

    static testMethod void testSafeUndelete_failure() {
        setup(true);
        dmlBox.add(child, parent);

        Test.startTest();
            List<Database.UndeleteResult> results = dmlBox.safeUndelete();
        Test.stopTest();

        System.assertEquals(1, results.size(), 'There should be a result');

        List<Child__c> children= [
            SELECT Id
            FROM Child__c
            WHERE Parent__c = :parent.Id
        ];

        System.assertEquals(1, children.size(), 'Safely undeleting an existing record should not remove or add any records');
    }
}
