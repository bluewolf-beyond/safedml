# SafeDML version 1.4
A library to easily attach errors due to dml failures in triggers.

## Motivation
The traditional and correct way to implement safe dml in a trigger is the following:
```java
trigger Account on Account (after insert) {
    List<Contact> contacts = new List<Contact>();
    
    for(Account account : Trigger.new) {
        contacts.add(new Contact(Name = account.Name));
    }
    
    try {
        insert contacts;
    } catch(DMLException e) {
        for(Integer i = 0; i < e.getNumDml(); i++) {
            Integer failedIndex = e.getDmlIndex(i);
            String failedMessage = e.getDmlMessage(i);
            Trigger.new[failedIndex].addError(failedMessage);
        }
    }
}
```

There is a lot of boilerplate that is going on in the previous example.
You also have to write a failure test case in order to get code coverage for the fail case.

Here is the same code using the SafeDML managed package.
```java
trigger Account on Account (after insert) {
    List<Contact> contacts = new List<Contact>();
    
    for(Account account : Trigger.new) {
        contacts.add(new Contact(Name = account.Name));
    }
    
    SafeDML.SafeDML2.safeInsert(contacts, Trigger.new);
}
```

## Install Path
/packaging/installPackage.apexp?p0=04tE00000001XU1

## License
Licensed under the MIT License.
See the LICENSE file.

## Documentation

The supported DML operations are Insert, Update, Upsert, Delete, Undelete.
The functions are located in the SafeDML2 class.
Each operation has 2 forms of the same function.

1. The first form attaches the error message from the _i_ th record to each record in the _i_ th list of related trigger objects. The first form of the function is only necessary when 2 or more trigger objects cause the creation of the same object.

2. The second form attaches the error message from the _i_ th record to the _i_ th related trigger object.

This means that the records and trigger object params need to be the same length.

Each function returns a Boolean of True for success and False for failure.

```java
global static Boolean safeInsert(List<sObject> records, List<List<sObject>> triggerObjects)
global static Boolean safeInsert(List<sObject> records, List<sObject> triggerObjects)

global static Boolean safeUpdate(List<sObject> records, List<List<sObject>> triggerObjects)
global static Boolean safeUpdate(List<sObject> records, List<sObject> triggerObjects)

global static Boolean safeUpsert(List<sObject> records, List<List<sObject>> triggerObjects)
global static Boolean safeUpsert(List<sObject> records, List<sObject> triggerObjects)

global static Boolean safeDelete(List<sObject> records, List<List<sObject>> triggerObjects)
global static Boolean safeDelete(List<sObject> records, List<sObject> triggerObjects)

global static Boolean safeUndelete(List<sObject> records, List<List<sObject>> triggerObjects)
global static Boolean safeUndelete(List<sObject> records, List<sObject> triggerObjects)
```
