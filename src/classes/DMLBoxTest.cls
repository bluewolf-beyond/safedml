@isTest
private class DMLBoxTest {
    static final String ERROR1 = 'I used to do drugs. I still do drugs. But I used to, too.';
    static final String ERROR2 = 'A waffle is like a pancake with a syrup trap.';
    static final List<String> FIELDS = new List<String>{'Mitch', 'Hedberg'};
    static final DMLBox.Result success;
    static final DMLBox.Result failure;
    static final List<DMLBox.Result> results;

    static {
        success = new DMLBox.Result(true, null);
        failure = new DMLBox.Result(false, new List<DMLBox.Error>
                { new DMLBox.Error(ERROR1, StatusCode.UNKNOWN_EXCEPTION, FIELDS)
                , new DMLBox.Error(ERROR2, StatusCode.STRING_TOO_LONG, FIELDS)
                });
        results = new List<DMLBox.Result>
            { success
            , failure
            };
    }

    static Account account = new Account();
    static DMLBox box = new DMLBox();

    static testMethod void add() {
        Test.startTest();
            box.add(new List<Sobject>{account}, new List<Sobject>{account});
            box.add(new List<Sobject>{account}, account);
        Test.stopTest();

        System.assertEquals(2, box.safeOperations.size(), 'There should be 1 entry for each addition');
    }

    static testMethod void addErrors() {
        box.add(new List<Sobject>{account}, account);
        box.add(new List<Sobject>{account}, account);

        Test.startTest();
            // call to get test code coverage
            // there is no cross org way of safely testing the effects of Sobject.addError
            box.addErrors(results);
        Test.stopTest();
    }

    static testMethod void getErrorMessages() {
        Test.startTest();
            String actual = DMLBox.getErrorMessages(failure.errors);
        Test.stopTest();

        String expected = 'Got the error: I used to do drugs. I still do drugs. But I used to, too.. Got the status code: UNKNOWN_EXCEPTION. Fields which caused the error: Mitch, Hedberg., Got the error: A waffle is like a pancake with a syrup trap.. Got the status code: STRING_TOO_LONG. Fields which caused the error: Mitch, Hedberg.';
        System.assertEquals(expected, actual, 'The string should match');
    }

    static testMethod void pluckRecords() {
        Test.startTest();
            List<Sobject> actual = DMLBox.pluckRecords(new List<DMLBox.SafeOperation>{new DMLBox.SafeOperation(account, account)});
        Test.stopTest();

        System.assertEquals(1, actual.size(), 'There should be 1 record plucked');
        System.assertEquals(account, actual[0], 'The record should match');
    }

    static testMethod void hasFailures_noFailures() {
        Test.startTest();
            Boolean actual = DMLBox.hasFailures(new List<DMLBox.Result>{success});
        Test.stopTest();

        System.assert(!actual, 'The list should not have a failure');
    }

    static testMethod void hasFailures_hasFailures() {
        Test.startTest();
            Boolean actual = DMLBox.hasFailures(results);
        Test.stopTest();

        System.assert(actual, 'The list should have failures');
    }
}