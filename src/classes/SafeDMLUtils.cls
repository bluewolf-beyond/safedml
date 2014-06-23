public class SafeDMLUtils {
    public static List<List<Sobject>> wrapSobjects(List<Sobject> records) {
        List<List<Sobject>> wrappedRecords = new List<List<Sobject>>();

        for(Sobject record : records) {
            wrappedRecords.add(new List<Sobject>{record});
        }

        return wrappedRecords;
    }
}
