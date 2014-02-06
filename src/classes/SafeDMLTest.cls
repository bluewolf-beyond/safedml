@isTest
private class SafeDMLTest {
    static final String OLD_TEXT_FIELD_VALUE = 'Scully';
    static final String NEW_TEXT_FIELD_VALUE = 'Mulder';
    static final String CHILD_FIELD_FOR_PARENT_LOOKUP = 'Parent__c';

    static Parent__c parent;
    static Child__c child;

    static void setup(Boolean insertChild) {
        parent = TestUtil.createParent(OLD_TEXT_FIELD_VALUE, true);
        child = TestUtil.createChild(parent.Id, insertChild);
    }

    static testMethod void testGenericSafeUpdate_success() {
        setup(true);

        parent.Text_Field__c = NEW_TEXT_FIELD_VALUE;

        Test.startTest();
            SafeDML.genericSafeUpdate(new List<Parent__c>{parent}, new List<Child__c>{child}, CHILD_FIELD_FOR_PARENT_LOOKUP);
        Test.stopTest();

        parent = [
            SELECT Text_Field__c
            FROM Parent__c
            WHERE Id = :parent.Id
        ];

        System.assertEquals(NEW_TEXT_FIELD_VALUE, parent.Text_Field__c, 'Safe updating a valid parent should succeed');
    }

    static testMethod void testGenericSafeUpdate_failure() {
        setup(true);

        parent.Text_Field__c = NEW_TEXT_FIELD_VALUE;
        parent.OwnerId = parent.Id;

        Test.startTest();
            try {
                SafeDML.genericSafeUpdate(new List<Parent__c>{parent}, new List<Child__c>{child}, CHILD_FIELD_FOR_PARENT_LOOKUP);
            } catch(Exception e) {
                System.assert(false, 'The safe update function should not throw an exception: ' + e.getMessage());
            }
        Test.stopTest();

        parent = [
            SELECT Text_Field__c
            FROM Parent__c
            WHERE Id = :parent.Id
        ];

        System.assertEquals(OLD_TEXT_FIELD_VALUE, parent.Text_Field__c, 'The update should have gracefully failed and not set any field');
    }

    static testMethod void testGenericSafeUpdateSelf_success() {
        setup(false);

        parent.Text_Field__c = NEW_TEXT_FIELD_VALUE;

        Test.startTest();
            SafeDML.genericSafeUpdateSelf(new List<Parent__c>{parent}, new List<Parent__c>{parent});
        Test.stopTest();

        parent = [
            SELECT Text_Field__c
            FROM Parent__c
            WHERE Id = :parent.Id
        ];

        System.assertEquals(NEW_TEXT_FIELD_VALUE, parent.Text_Field__c, 'Safe updating a valid parent should succeed');
    }

    static testMethod void testGenericSafeUpdateSelf_failure() {
        setup(false);

        parent.Text_Field__c = NEW_TEXT_FIELD_VALUE;
        parent.OwnerId = parent.Id;

        Test.startTest();
            SafeDML.genericSafeUpdateSelf(new List<Parent__c>{parent}, new List<Parent__c>{parent});
        Test.stopTest();

        parent = [
            SELECT Text_Field__c
            FROM Parent__c
            WHERE Id = :parent.Id
        ];

        System.assertEquals(OLD_TEXT_FIELD_VALUE, parent.Text_Field__c, 'Safe updating an invalid parent should fail');
    }

    static testMethod void testGenericSafeInsert_success() {
        setup(false);

        Test.startTest();
            SafeDML.genericSafeInsert(new List<Child__c>{child}, new Map<Id, Parent__c>{parent.Id => parent}, CHILD_FIELD_FOR_PARENT_LOOKUP);
        Test.stopTest();

        List<Child__c> children = [
            SELECT Id
            FROM Child__c
            WHERE Parent__c = :parent.Id
        ];

        System.assertEquals(1, children.size(), 'There should be 1 child associated with the parent when inserting a valid child');
    }

    static testMethod void testGenericSafeInsert_failure() {
        setup(false);

        child.OwnerId = parent.Id;

        Test.startTest();
            SafeDML.genericSafeInsert(new List<Child__c>{child}, new Map<Id, Parent__c>{parent.Id => parent}, CHILD_FIELD_FOR_PARENT_LOOKUP);
        Test.stopTest();

        List<Child__c> children = [
            SELECT Id
            FROM Child__c
            WHERE Parent__c = :parent.Id
        ];

        System.assert(children.isEmpty(), 'There should be no children associated with the parent when inserting an invalid child');
    }

    static testMethod void testSafeInsert_success()
    {
        setup(false);

        Test.startTest();
            SafeDML.safeInsert( new List<Child__c>{ child }, new List<List<Parent__c>>{ new List<Parent__c>{ parent } } );
        Test.stopTest();

        List<Child__c> children =
        [
            SELECT Id
            FROM Child__c
            WHERE Parent__c = :parent.Id
        ];

        System.assertEquals( 1, children.size(), 'There should be 1 child associated with the parent when inserting a valid child' );
    }

    static testMethod void testSafeInsert_failure()
    {
        setup( false );

        child.OwnerId = parent.Id;

        Test.startTest();
            try
            {
                SafeDML.safeInsert( new List<Child__c>{ child }, new List<List<Parent__c>>{ new List<Parent__c>{ parent } } );
            }
            catch( DMLException dmx )
            {
                System.assert( false, 'No exception should have been thrown when safe inserting an invalid object: ' + dmx.getMessage() );
            }
        Test.stopTest();

        List<Child__c> children = [
            SELECT Id
            FROM Child__c
            WHERE Parent__c = :parent.Id
        ];

        System.assert(children.isEmpty(), 'There should be no children associated with the parent when inserting an invalid child');
    }

    static testMethod void testSafeInsert_single_success()
    {
        setup(false);

        Test.startTest();
            SafeDML.safeInsert( new List<Child__c>{ child }, new List<Parent__c>{ parent } );
        Test.stopTest();

        List<Child__c> children =
        [
            SELECT Id
            FROM Child__c
            WHERE Parent__c = :parent.Id
        ];

        System.assertEquals( 1, children.size(), 'There should be 1 child associated with the parent when inserting a valid child' );
    }

    static testMethod void testSafeInsert_single_failure()
    {
        setup( false );

        child.OwnerId = parent.Id;

        Test.startTest();
            try
            {
                SafeDML.safeInsert( new List<Child__c>{ child }, new List<Parent__c>{ parent } );
            }
            catch( DMLException dmx )
            {
                System.assert( false, 'No exception should have been thrown when safe inserting an invalid object: ' + dmx.getMessage() );
            }
        Test.stopTest();

        List<Child__c> children = [
            SELECT Id
            FROM Child__c
            WHERE Parent__c = :parent.Id
        ];

        System.assert(children.isEmpty(), 'There should be no children associated with the parent when inserting an invalid child');
    }

    static testMethod void testSafeUpdate_success()
    {
        setup(true);

        parent.Text_Field__c = NEW_TEXT_FIELD_VALUE;

        Test.startTest();
            SafeDML.safeUpdate( new List<Parent__c>{ parent }, new List<List<Child__c>>{ new List<Child__c>{ child } } );
        Test.stopTest();

        parent = [
            SELECT Text_Field__c
            FROM Parent__c
            WHERE Id = :parent.Id
        ];

        System.assertEquals(NEW_TEXT_FIELD_VALUE, parent.Text_Field__c, 'Safe updating a valid parent should succeed');
    }

    static testMethod void testSafeUpdate_failure()
    {
        setup(true);

        parent.Text_Field__c = NEW_TEXT_FIELD_VALUE;
        parent.OwnerId = parent.Id;

        Test.startTest();
            try {
                SafeDML.safeUpdate( new List<Parent__c>{ parent }, new List<List<Child__c>>{ new List<Child__c>{ child } } );
            } catch(Exception e) {
                System.assert(false, 'The safe update function should not throw an exception: ' + e.getMessage());
            }
        Test.stopTest();

        parent = [
            SELECT Text_Field__c
            FROM Parent__c
            WHERE Id = :parent.Id
        ];

        System.assertEquals(OLD_TEXT_FIELD_VALUE, parent.Text_Field__c, 'The update should have gracefully failed and not set any field');
    }

    static testMethod void testSafeUpdate_single_success()
    {
        setup(true);

        parent.Text_Field__c = NEW_TEXT_FIELD_VALUE;

        Test.startTest();
            SafeDML.safeUpdate( new List<Parent__c>{ parent }, new List<Child__c>{ child } );
        Test.stopTest();

        parent = [
            SELECT Text_Field__c
            FROM Parent__c
            WHERE Id = :parent.Id
        ];

        System.assertEquals(NEW_TEXT_FIELD_VALUE, parent.Text_Field__c, 'Safe updating a valid parent should succeed');
    }

    static testMethod void testSafeUpdate_single_failure()
    {
        setup(true);

        parent.Text_Field__c = NEW_TEXT_FIELD_VALUE;
        parent.OwnerId = parent.Id;

        Test.startTest();
            try {
                SafeDML.safeUpdate( new List<Parent__c>{ parent }, new List<Child__c>{ child } );
            } catch(Exception e) {
                System.assert(false, 'The safe update function should not throw an exception: ' + e.getMessage());
            }
        Test.stopTest();

        parent = [
            SELECT Text_Field__c
            FROM Parent__c
            WHERE Id = :parent.Id
        ];

        System.assertEquals(OLD_TEXT_FIELD_VALUE, parent.Text_Field__c, 'The update should have gracefully failed and not set any field');
    }

    static testMethod void testSafeUpsert_insert_success()
    {
        setup(false);

        Test.startTest();
            SafeDML.safeUpsert( new List<Child__c>{ child }, new List<List<Parent__c>>{ new List<Parent__c>{ parent } } );
        Test.stopTest();

        List<Child__c> children =
        [
            SELECT Id
            FROM Child__c
            WHERE Parent__c = :parent.Id
        ];

        System.assertEquals( 1, children.size(), 'There should be 1 child associated with the parent when upserting a valid child' );
    }

    static testMethod void testSafeUpsert_insert_failure()
    {
        setup( false );

        child.OwnerId = parent.Id;

        Test.startTest();
            try
            {
                SafeDML.safeUpsert( new List<Child__c>{ child }, new List<List<Parent__c>>{ new List<Parent__c>{ parent } } );
            }
            catch( DMLException dmx )
            {
                System.assert( false, 'No exception should have been thrown when safe upserting an invalid object: ' + dmx.getMessage() );
            }
        Test.stopTest();

        List<Child__c> children = [
            SELECT Id
            FROM Child__c
            WHERE Parent__c = :parent.Id
        ];

        System.assert(children.isEmpty(), 'There should be no children associated with the parent when upserting an invalid child');
    }

    static testMethod void testSafeUpsert_insert_single_success()
    {
        setup(false);

        Test.startTest();
            SafeDML.safeUpsert( new List<Child__c>{ child }, new List<Parent__c>{ parent } );
        Test.stopTest();

        List<Child__c> children =
        [
            SELECT Id
            FROM Child__c
            WHERE Parent__c = :parent.Id
        ];

        System.assertEquals( 1, children.size(), 'There should be 1 child associated with the parent when upserting a valid child' );
    }

    static testMethod void testSafeUpsert_insert_single_failure()
    {
        setup( false );

        child.OwnerId = parent.Id;

        Test.startTest();
            try
            {
                SafeDML.safeUpsert( new List<Child__c>{ child }, new List<Parent__c>{ parent } );
            }
            catch( DMLException dmx )
            {
                System.assert( false, 'No exception should have been thrown when safe upserting an invalid object: ' + dmx.getMessage() );
            }
        Test.stopTest();

        List<Child__c> children = [
            SELECT Id
            FROM Child__c
            WHERE Parent__c = :parent.Id
        ];

        System.assert(children.isEmpty(), 'There should be no children associated with the parent when upserting an invalid child');
    }

    static testMethod void testSafeUpsert_update_success()
    {
        setup(true);

        parent.Text_Field__c = NEW_TEXT_FIELD_VALUE;

        Test.startTest();
            SafeDML.safeUpsert( new List<Parent__c>{ parent }, new List<List<Child__c>>{ new List<Child__c>{ child } } );
        Test.stopTest();

        parent = [
            SELECT Text_Field__c
            FROM Parent__c
            WHERE Id = :parent.Id
        ];

        System.assertEquals(NEW_TEXT_FIELD_VALUE, parent.Text_Field__c, 'Safe upserting a valid parent should succeed');
    }

    static testMethod void testSafeUpsert_update_failure()
    {
        setup(true);

        parent.Text_Field__c = NEW_TEXT_FIELD_VALUE;
        parent.OwnerId = parent.Id;

        Test.startTest();
            try {
                SafeDML.safeUpsert( new List<Parent__c>{ parent }, new List<List<Child__c>>{ new List<Child__c>{ child } } );
            } catch(Exception e) {
                System.assert(false, 'The safe upsert function should not throw an exception: ' + e.getMessage());
            }
        Test.stopTest();

        parent = [
            SELECT Text_Field__c
            FROM Parent__c
            WHERE Id = :parent.Id
        ];

        System.assertEquals(OLD_TEXT_FIELD_VALUE, parent.Text_Field__c, 'The upsert should have gracefully failed and not set any field');
    }

    static testMethod void testSafeUpsert_update_single_success()
    {
        setup(true);

        parent.Text_Field__c = NEW_TEXT_FIELD_VALUE;

        Test.startTest();
            SafeDML.safeUpsert( new List<Parent__c>{ parent }, new List<Child__c>{ child } );
        Test.stopTest();

        parent = [
            SELECT Text_Field__c
            FROM Parent__c
            WHERE Id = :parent.Id
        ];

        System.assertEquals(NEW_TEXT_FIELD_VALUE, parent.Text_Field__c, 'Safe upserting a valid parent should succeed');
    }

    static testMethod void testSafeUpsert_update_single_failure()
    {
        setup(true);

        parent.Text_Field__c = NEW_TEXT_FIELD_VALUE;
        parent.OwnerId = parent.Id;

        Test.startTest();
            try {
                SafeDML.safeUpsert( new List<Parent__c>{ parent }, new List<Child__c>{ child } );
            } catch(Exception e) {
                System.assert(false, 'The safe upsert function should not throw an exception: ' + e.getMessage());
            }
        Test.stopTest();

        parent = [
            SELECT Text_Field__c
            FROM Parent__c
            WHERE Id = :parent.Id
        ];

        System.assertEquals(OLD_TEXT_FIELD_VALUE, parent.Text_Field__c, 'The upsert should have gracefully failed and not set any field');
    }

    static testMethod void testSafeDelete_success()
    {
        setup(true);

        Test.startTest();
            SafeDML.safeDelete( new List<Child__c>{ child }, new List<List<Parent__c>>{ new List<Parent__c>{ parent } } );
        Test.stopTest();

        List<Child__c> children= [
            SELECT Id
            FROM Child__c
            WHERE Parent__c = :parent.Id
        ];

        System.assert(children.isEmpty(), 'Safe deleting a record should succeed');
    }

    static testMethod void testSafeDelete_failure()
    {
        setup(true);

        delete child;

        Test.startTest();
            try
            {
                SafeDML.safeDelete( new List<Child__c>{ child }, new List<List<Parent__c>>{ new List<Parent__c>{ parent } } );
            }
            catch(DMLException dmx)
            {
                System.assert(false, 'Safe deleting a deleted record should not throw an exception: ' + dmx.getMessage());
            }
        Test.stopTest();

        List<Child__c> children= [
            SELECT Id
            FROM Child__c
            WHERE Parent__c = :parent.Id
        ];

        System.assert(children.isEmpty(), 'Safe deleting an already deleted record should not create any new records in the database');
    }

    static testMethod void testSafeDelete_single_success()
    {
        setup(true);

        Test.startTest();
            SafeDML.safeDelete( new List<Child__c>{ child }, new List<Parent__c>{ parent } );
        Test.stopTest();

        List<Child__c> children= [
            SELECT Id
            FROM Child__c
            WHERE Parent__c = :parent.Id
        ];

        System.assert(children.isEmpty(), 'Safe deleting a record should succeed');
    }

    static testMethod void testSafeDelete_single_failure()
    {
        setup(true);

        delete child;

        Test.startTest();
            try
            {
                SafeDML.safeDelete( new List<Child__c>{ child }, new List<Parent__c>{ parent } );
            }
            catch(DMLException dmx)
            {
                System.assert(false, 'Safe deleting a deleted record should not throw an exception: ' + dmx.getMessage());
            }
        Test.stopTest();

        List<Child__c> children= [
            SELECT Id
            FROM Child__c
            WHERE Parent__c = :parent.Id
        ];

        System.assert(children.isEmpty(), 'Safe deleting an already deleted record should not create any new records in the database');
    }

    static testMethod void testSafeUndelete_success()
    {
        setup(true);

        delete child;

        Test.startTest();
            SafeDML.safeUndelete( new List<Child__c>{ child }, new List<List<Parent__c>>{ new List<Parent__c>{ parent } } );
        Test.stopTest();

        List<Child__c> children= [
            SELECT Id
            FROM Child__c
            WHERE Parent__c = :parent.Id
        ];

        System.assertEquals(1, children.size(), 'Safely undeleting a deleted record should bring back the record');
    }

    static testMethod void testSafeUndelete_failure()
    {
        setup(true);

        Test.startTest();
            try
            {
                SafeDML.safeUndelete( new List<Child__c>{ child }, new List<List<Parent__c>>{ new List<Parent__c>{ parent } } );
            }
            catch(DMLException dmx)
            {
                System.assert(false, 'Safely undeleting a record that has not been deleted should not throw an exception: ' + dmx.getMessage());
            }
        Test.stopTest();

        List<Child__c> children= [
            SELECT Id
            FROM Child__c
            WHERE Parent__c = :parent.Id
        ];

        System.assertEquals(1, children.size(), 'Safely undeleting an existing record should not remove or add any records');
    }

    static testMethod void testSafeUndelete_single_success()
    {
        setup(true);

        delete child;

        Test.startTest();
            SafeDML.safeUndelete( new List<Child__c>{ child }, new List<Parent__c>{ parent } );
        Test.stopTest();

        List<Child__c> children= [
            SELECT Id
            FROM Child__c
            WHERE Parent__c = :parent.Id
        ];

        System.assertEquals(1, children.size(), 'Safely undeleting a deleted record should bring back the record');
    }

    static testMethod void testSafeUndelete_single_failure()
    {
        setup(true);

        Test.startTest();
            try
            {
                SafeDML.safeUndelete( new List<Child__c>{ child }, new List<Parent__c>{ parent } );
            }
            catch(DMLException dmx)
            {
                System.assert(false, 'Safely undeleting a record that has not been deleted should not throw an exception: ' + dmx.getMessage());
            }
        Test.stopTest();

        List<Child__c> children= [
            SELECT Id
            FROM Child__c
            WHERE Parent__c = :parent.Id
        ];

        System.assertEquals(1, children.size(), 'Safely undeleting an existing record should not remove or add any records');
    }

    static testMethod void testParentsRelatedToChildren()
    {
        setup(true);

        Test.startTest();
           List<List<sObject>> parents = SafeDML.parentsRelatedToChildren(new Map<Id, Parent__c>{ parent.Id => parent }, new List<Child__c>{ child }, Child__c.Parent__c);
        Test.stopTest();

        System.assertEquals(1, parents.size(), 'There should be one relationship in a one parent and one child relationship');
        System.assertEquals(1, parents[0].size(), 'There should be one parent in the relationship');
        System.assertEquals(parent.Id, parents[0][0].Id, 'The first parent should be the parent related to the first child');
    }
}