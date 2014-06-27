# SafeDML version 1.5
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
    SafeDML.DMLBox dmlBox = new SafeDML.DMLBox();

    for(Account account : Trigger.new) {
        dmlBox.add(new Contact(Name = account.Name), account);
    }

    dmlBox.safeInsert();
}
```

## Install Path
/packaging/installPackage.apexp?p0=04tE00000001Xld

## License
Licensed under the MIT License.
See the LICENSE file.

## Documentation

The supported DML operations are Insert, Update, Delete, Undelete.
The functions are located in the DMLBox class.

Each function returns a list of:
Insert, Update: Database.SaveResult
Delete: Database.DeleteResult
Undelete: Database.UndeleteResult

Steps to get the package working:

1. Initialize DMLBox

  ```java
SafeDML.DMLBox dmlBox = new SafeDML.DMLBox();
```

2. Add an associated object to do dml on and trigger objects to attach errors to. There are 2 versions of the add function.
  1. One that takes a single related trigger object
  2. One that takes a list of related trigger objects

  ```java
global DMLBox add(Sobject record, Sobject triggerRecord)
global DMLBox add(Sobject record, List<Sobject> triggerRecords)
```

3. Run the safe dml operation

  ```java
global List<Database.SaveResult> safeInsert()
global List<Database.SaveResult> safeUpdate()
global List<Database.DeleteResult> safeDelete()
global List<Database.UndeleteResult> safeUndelete()
```
