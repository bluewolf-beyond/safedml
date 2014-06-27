global class DMLBox {
    // upsert is not available as a generic dml operation
    // https://success.salesforce.com/ideaView?id=08730000000aNhVAAU

    public class SafeOperation {
        public Sobject record;
        public List<Sobject> triggerRecords;

        public SafeOperation(Sobject record, List<Sobject> triggerRecords) {
            this.record = record;
            this.triggerRecords = triggerRecords;
        }

        public SafeOperation(Sobject record, Sobject triggerRecord) {
            this(record, new List<Sobject>{triggerRecord});
        }
    }

    public List<SafeOperation> safeOperations;

    global DMLBox() {
        safeOperations = new List<SafeOperation>();
    }

    global DMLBox add(Sobject record, List<Sobject> triggerRecords) {
        safeOperations.add(new SafeOperation(record, triggerRecords));

        return this;
    }

    global DMLBox add(Sobject record, Sobject triggerRecord) {
        safeOperations.add(new SafeOperation(record, triggerRecord));

        return this;
    }

    global DMLBox add(List<Sobject> records, List<Sobject> triggerRecords) {
        for(Sobject record : records) {
            add(record, triggerRecords);
        }

        return this;
    }

    global DMLBox add(List<Sobject> records, Sobject triggerRecord) {
        for(Sobject record : records) {
            add(record, triggerRecord);
        }

        return this;
    }

    global List<Database.SaveResult> safeInsert() {
        List<Sobject> records = pluckRecords(safeOperations);
        List<Database.SaveResult> saveResults = Database.insert(records, false);

        for(Integer i = 0; i < saveResults.size(); i++) {
            Database.SaveResult saveResult = saveResults[i];

            if(!saveResult.isSuccess()) {
                addErrors(safeOperations[i], saveResult.getErrors());
            }
        }

        return saveResults;
    }

    global List<Database.SaveResult> safeUpdate() {
        List<Sobject> records = pluckRecords(safeOperations);
        List<Database.SaveResult> saveResults = Database.update(records, false);

        for(Integer i = 0; i < saveResults.size(); i++) {
            Database.SaveResult saveResult = saveResults[i];

            if(!saveResult.isSuccess()) {
                addErrors(safeOperations[i], saveResult.getErrors());
            }
        }

        return saveResults;
    }

    global List<Database.DeleteResult> safeDelete() {
        List<Sobject> records = pluckRecords(safeOperations);
        List<Database.DeleteResult> deleteResults = Database.delete(records, false);

        for(Integer i = 0; i < deleteResults.size(); i++) {
            Database.DeleteResult deleteResult = deleteResults[i];

            if(!deleteResult.isSuccess()) {
                addErrors(safeOperations[i], deleteResult.getErrors());
            }
        }

        return deleteResults;
    }

    global List<Database.UndeleteResult> safeUndelete() {
        List<Sobject> records = pluckRecords(safeOperations);
        List<Database.UndeleteResult> undeleteResults = Database.undelete(records, false);

        for(Integer i = 0; i < undeleteResults.size(); i++) {
            Database.UndeleteResult undeleteResult = undeleteResults[i];

            if(!undeleteResult.isSuccess()) {
                addErrors(safeOperations[i], undeleteResult.getErrors());
            }
        }

        return undeleteResults;
    }

    static void addErrors(SafeOperation safeOperation, List<Database.Error> errors) {
        String errorMessages = getErrorMessages(errors);
        List<Sobject> triggerRecords = safeOperation.triggerRecords;

        for(sObject triggerRecord : triggerRecords) {
            triggerRecord.addError(errorMessages);
        }
    }

    static String getErrorMessages(List<Database.Error> errors) {
        List<String> errorMessages = new List<String>();

        for(Database.Error error : errors) {
            errorMessages.add(getErrorMessage(error));
        }

        return String.join(errorMessages, ', ');
    }

    static String getErrorMessage(Database.Error error) {
        String errorMessage = String.format('{0}: {1}.', new List<String>
            { 'Got the error'
            , error.getMessage()
            });

        String statusCodeMessage = String.format('{0}: {1}.', new List<String>
            { 'Got the status code'
            , String.valueOf(error.getStatusCode())
            });

        String fieldMessage = '';
        List<String> fields = error.getFields();
        if(!fields.isEmpty()) {
            fieldMessage += String.format('{0}: {1}.', new List<String>
                { 'Fields which caused the error'
                , String.join(fields, ', ')
                });
        }

        String returnMessage = String.format('{0} {1}', new List<String>
            { errorMessage
            , statusCodeMessage
            });

        if(String.isNotBlank(fieldMessage)) {
            returnMessage = String.format('{0} {1}', new List<String>
                { returnMessage
                , fieldMessage
                });
        }

        return returnMessage;
    }

    static List<Sobject> pluckRecords(List<SafeOperation> safeOperations) {
        List<Sobject> records = new List<Sobject>();

        for(SafeOperation safeOperation : safeOperations) {
            records.add(safeOperation.record);
        }

        return records;
    }
}