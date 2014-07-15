public class DMLBox {
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

    public DMLBox() {
        safeOperations = new List<SafeOperation>();
    }

    public DMLBox add(Sobject record, List<Sobject> triggerRecords) {
        safeOperations.add(new SafeOperation(record, triggerRecords));

        return this;
    }

    public DMLBox add(Sobject record, Sobject triggerRecord) {
        safeOperations.add(new SafeOperation(record, triggerRecord));

        return this;
    }

    public DMLBox add(List<Sobject> records, List<Sobject> triggerRecords) {
        for(Sobject record : records) {
            add(record, triggerRecords);
        }

        return this;
    }

    public DMLBox add(List<Sobject> records, Sobject triggerRecord) {
        for(Sobject record : records) {
            add(record, triggerRecord);
        }

        return this;
    }

    public List<Result> safeInsert() { return addErrors(convert(Database.insert(pluckRecords(safeOperations), false))); }

    public List<Result> safeUpdate() { return addErrors(convert(Database.update(pluckRecords(safeOperations), false))); }

    public List<Result> safeDelete() { return addErrors(convert(Database.delete(pluckRecords(safeOperations), false))); }

    public List<Result> safeUndelete() { return addErrors(convert(Database.undelete(pluckRecords(safeOperations), false))); }

    @TestVisible
    List<Result> addErrors(List<Result> results) {
        for(Integer i = 0; i < results.size(); i++) {
            Result result = results[i];

            if(!result.success) {
                addErrors(safeOperations[i], result.errors);
            }
        }

        return results;
    }

    static void addErrors(SafeOperation safeOperation, List<Error> errors) {
        String errorMessages = getErrorMessages(errors);
        List<Sobject> triggerRecords = safeOperation.triggerRecords;

        for(sObject triggerRecord : triggerRecords) {
            triggerRecord.addError(errorMessages);
        }
    }

    @TestVisible
    static String getErrorMessages(List<Error> errors) {
        List<String> errorMessages = new List<String>();

        for(Error error : errors) {
            errorMessages.add(getErrorMessage(error));
        }

        return String.join(errorMessages, ', ');
    }

    static String getErrorMessage(Error error) {
        String errorMessage = String.format('{0}: {1}.', new List<String>
            { 'Got the error'
            , error.message
            });

        String statusCodeMessage = String.format('{0}: {1}.', new List<String>
            { 'Got the status code'
            , String.valueOf(error.statusCode)
            });

        String fieldMessage = '';
        List<String> fields = error.fields;
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

    // used as a container for Database.Error
    public class Error {
        public String message;
        public StatusCode statusCode;
        public List<String> fields;

        public Error(String message, StatusCode statusCode, List<String> fields) {
            this.message = message;
            this.statusCode = statusCode;
            this.fields = fields;
        }
    }

    static Error convert(Database.Error error) { return new Error(error.getMessage(), error.getStatusCode(), error.getFields()); }

    static List<Error> convert(List<Database.Error> errors) { List<Error> ret = new List<Error>(); for(Database.Error error : errors) { ret.add(convert(error)); } return ret; }

    public class Result {
        public Boolean success;
        public List<Error> errors;

        public Result(Boolean success, List<Error> errors) {
            this.success = success;
            this.errors = errors;
        }
    }

    static Result convert(Database.SaveResult r) { return new Result(r.isSuccess(), convert(r.getErrors())); }

    static Result convert(Database.DeleteResult r) { return new Result(r.isSuccess(), convert(r.getErrors())); }

    static Result convert(Database.UndeleteResult r) { return new Result(r.isSuccess(), convert(r.getErrors())); }

    static List<Result> convert(List<Database.SaveResult> results) { List<Result> ret = new List<Result>(); for(Database.SaveResult result : results) { ret.add(convert(result)); } return ret; }

    static List<Result> convert(List<Database.DeleteResult> results) { List<Result> ret = new List<Result>(); for(Database.DeleteResult result : results) { ret.add(convert(result)); } return ret; }

    static List<Result> convert(List<Database.UndeleteResult> results) { List<Result> ret = new List<Result>(); for(Database.UndeleteResult result : results) { ret.add(convert(result)); } return ret; }

    @TestVisible
    static List<Sobject> pluckRecords(List<SafeOperation> safeOperations) {
        List<Sobject> records = new List<Sobject>();

        for(SafeOperation safeOperation : safeOperations) {
            records.add(safeOperation.record);
        }

        return records;
    }

    public static Boolean hasFailures(List<Result> results) {
        for(Result result : results) {
            if(!result.success) {
                return true;
            }
        }

        return false;
    }
}