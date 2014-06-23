global class SafeDML2 {
    enum DMLOperation { DML_INSERT, DML_UPDATE, DML_UPSERT, DML_DELETE, DML_UNDELETE }

    // this function expects that every record be associated with a list of trigger objects to attach errors to in case of errors
    // returns true if it completed without error and false if it encountered errors
    static Boolean safeDML(DMLOperation operation, List<sObject> records, List<List<sObject>> triggerObjects)
    {
        try
        {
            if(operation == DMLOperation.DML_INSERT)
            {
                insert records;
            }
            if(operation == DMLOperation.DML_UPDATE)
            {
                update records;
            }
            if(operation == DMLOperation.DML_UPSERT)
            {
                upsert records;
            }
            if(operation == DMLOperation.DML_DELETE)
            {
                delete records;
            }
            if(operation == DMLOperation.DML_UNDELETE)
            {
                undelete records;
            }

            return true;
        }
        catch(DMLException dmx)
        {
            for(Integer i = 0; i < dmx.getNumDml(); i++)
            {
                Integer failedIndex = dmx.getDmlIndex(i);
                String failedMessage = dmx.getDmlMessage(i);

                for(sObject triggerObject : triggerObjects[failedIndex])
                {
                    triggerObject.addError(failedMessage);
                }
            }

            return false;
        }
    }

    static List<List<Sobject>> wrapSobjects(List<Sobject> records) {
        List<List<Sobject>> wrappedRecords = new List<List<Sobject>>();

        for(Sobject record : records) {
            wrappedRecords.add(new List<Sobject>{record});
        }

        return wrappedRecords;
    }

    global static Boolean safeInsert(List<sObject> records, List<List<sObject>> triggerObjects)
    {
        return safeDML(DMLOperation.DML_INSERT, records, triggerObjects);
    }

    global static Boolean safeInsert(List<sObject> records, List<sObject> triggerObjects)
    {
        return safeDML(DMLOperation.DML_INSERT, records, wrapSobjects(triggerObjects));
    }

    global static Boolean safeUpdate(List<sObject> records, List<List<sObject>> triggerObjects)
    {
        return safeDML(DMLOperation.DML_UPDATE, records, triggerObjects);
    }

    global static Boolean safeUpdate(List<sObject> records, List<sObject> triggerObjects)
    {
        return safeDML(DMLOperation.DML_UPDATE, records, wrapSobjects(triggerObjects));
    }

    global static Boolean safeUpsert(List<sObject> records, List<List<sObject>> triggerObjects)
    {
        return safeDML(DMLOperation.DML_UPSERT, records, triggerObjects);
    }

    global static Boolean safeUpsert(List<sObject> records, List<sObject> triggerObjects)
    {
        return safeDML(DMLOperation.DML_UPSERT, records, wrapSobjects(triggerObjects));
    }

    global static Boolean safeDelete(List<sObject> records, List<List<sObject>> triggerObjects)
    {
        return safeDML(DMLOperation.DML_DELETE, records, triggerObjects);
    }

    global static Boolean safeDelete(List<sObject> records, List<sObject> triggerObjects)
    {
        return safeDML(DMLOperation.DML_DELETE, records, wrapSobjects(triggerObjects));
    }

    global static Boolean safeUndelete(List<sObject> records, List<List<sObject>> triggerObjects)
    {
        return safeDML(DMLOperation.DML_UNDELETE, records, triggerObjects);
    }

    global static Boolean safeUndelete(List<sObject> records, List<sObject> triggerObjects)
    {
        return safeDML(DMLOperation.DML_UNDELETE, records, wrapSobjects(triggerObjects));
    }
}