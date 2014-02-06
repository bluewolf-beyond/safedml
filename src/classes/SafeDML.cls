global class SafeDML {
    static final String SOBJECT_FIELD_ID = 'Id';

    enum DMLOperation { DML_INSERT, DML_UPDATE, DML_UPSERT, DML_DELETE, DML_UNDELETE }

    static Map<Id, List<sObject>> createRelationshipMap(List<sObject> children, String childFieldForParentLookup) {
        Map<Id, List<sObject>> parentIdToChildren = new Map<Id, List<sObject>>();

        for(sObject child : children) {
            Id parentId = (Id) child.get(childFieldForParentLookup);

            if(parentIdToChildren.get(parentId) == null) {
                parentIdToChildren.put(parentId, new List<sObject>());
            }

            parentIdToChildren.get(parentId).add(child);
        }

        return parentIdToChildren;
    }

    /* used for updating a parent object from a child object trigger */
    /* this can also be used to update an object from the same trigger by setting the childFieldForParentLookup to 'Id' */
	@deprecated
    global static void genericSafeUpdate(List<sObject> recordsToUpdate, List<sObject> triggerRecords, String childFieldForParentLookup) {
        try {
            update recordsToUpdate;
        } catch(DMLException dmx) {
            Map<Id, List<sObject>> recordToUpdateIdToOwner = createRelationshipMap(triggerRecords, childFieldForParentLookup);

            for(Integer i = 0; i < dmx.getNumDml(); i++) {
                List<sObject> failedChildren = recordToUpdateIdToOwner.get(dmx.getDmlId(i));
                String failedMessage = dmx.getDmlMessage(i);

                for(sObject failedChild : failedChildren) {
                    failedChild.addError(failedMessage);
                }
            }
        }
    }

    /* useful when you want to update an object in an after update trigger */
	@deprecated
    global static void genericSafeUpdateSelf(List<sObject> recordsToUpdate, List<sObject> triggerRecords) {
        genericSafeUpdate(recordsToUpdate, triggerRecords, SOBJECT_FIELD_ID);
    }

    /* insert child records safely from a parent trigger */
	@deprecated
    global static void genericSafeInsert(List<sObject> recordsToInsert, Map<Id, sObject> triggerMap, String childFieldForParentLookup) {
        try {
            insert recordsToInsert;
        } catch(DMLException dmx) {
            for(Integer i = 0; i < dmx.getNumDml(); i++) {
                Integer failedIndex = dmx.getDmlIndex(i);
                sObject failedChild = recordsToInsert[failedIndex];
                Id failedParentId = (Id) failedChild.get(childFieldForParentLookup);
                sObject failedParent = triggerMap.get(failedParentId);
                String failedMessage = dmx.getDmlMessage(i);

                failedParent.addError(failedMessage);
            }
        }
    }

    // this function expects that every record be associated with a list of trigger objects to attach errors to in case of errors
    static void safeDML(DMLOperation operation, List<sObject> records, List<List<sObject>> triggerObjects)
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
        }
    }

    static List<List<Sobject>> wrapSobjects(List<Sobject> records) {
        List<List<Sobject>> wrappedRecords = new List<List<Sobject>>();

        for(Sobject record : records) {
            wrappedRecords.add(new List<Sobject>{record});
        }

        return wrappedRecords;
    }

    global static void safeInsert(List<sObject> records, List<List<sObject>> triggerObjects)
    {
        safeDML(DMLOperation.DML_INSERT, records, triggerObjects);
    }

    global static void safeInsert(List<sObject> records, List<sObject> triggerObjects)
    {
        safeDML(DMLOperation.DML_INSERT, records, wrapSobjects(triggerObjects));
    }

    global static void safeUpdate(List<sObject> records, List<List<sObject>> triggerObjects)
    {
        safeDML(DMLOperation.DML_UPDATE, records, triggerObjects);
    }

    global static void safeUpdate(List<sObject> records, List<sObject> triggerObjects)
    {
        safeDML(DMLOperation.DML_UPDATE, records, wrapSobjects(triggerObjects));
    }

    global static void safeUpsert(List<sObject> records, List<List<sObject>> triggerObjects)
    {
        safeDML(DMLOperation.DML_UPSERT, records, triggerObjects);
    }

    global static void safeUpsert(List<sObject> records, List<sObject> triggerObjects)
    {
        safeDML(DMLOperation.DML_UPSERT, records, wrapSobjects(triggerObjects));
    }

    global static void safeDelete(List<sObject> records, List<List<sObject>> triggerObjects)
    {
        safeDML(DMLOperation.DML_DELETE, records, triggerObjects);
    }

    global static void safeDelete(List<sObject> records, List<sObject> triggerObjects)
    {
        safeDML(DMLOperation.DML_DELETE, records, wrapSobjects(triggerObjects));
    }

    global static void safeUndelete(List<sObject> records, List<List<sObject>> triggerObjects)
    {
        safeDML(DMLOperation.DML_UNDELETE, records, triggerObjects);
    }

    global static void safeUndelete(List<sObject> records, List<sObject> triggerObjects)
    {
        safeDML(DMLOperation.DML_UNDELETE, records, wrapSobjects(triggerObjects));
    }

    global static List<List<sObject>> parentsRelatedToChildren(Map<Id, sObject> parents, List<sObject> children, SObjectField childFieldForParentLookup) {
        List<List<sObject>> ret = new List<List<sObject>>();

        for(sObject child : children)
        {
            Id parentId = (Id) child.get(childFieldForParentLookup);
            ret.add(new List<sObject>{parents.get(parentId)});
        }

        return ret;
    }
}