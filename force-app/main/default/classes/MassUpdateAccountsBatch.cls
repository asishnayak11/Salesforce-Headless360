public class MassUpdateAccountsBatch implements Database.Batchable<sObject>, Database.Stateful {
    private Integer succeeded = 0;
    private Integer failed = 0;
    private List<String> errorSummaries = new List<String>();

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Industry FROM Account WHERE Industry = null
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        for (Account a : scope) {
            a.Industry = 'Technology'; // your actual update logic
        }
        List<Database.SaveResult> results = Database.update(scope, false);
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                succeeded++;
            } else {
                failed++;
                for (Database.Error err : results[i].getErrors()) {
                    errorSummaries.add(scope[i].Id + ': ' + err.getMessage());
                }
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        EventBus.publish(new Bulk_Job_Settled__e(
            Job_Id__c = bc.getJobId(),
            Records_Processed__c = succeeded + failed,
            Records_Succeeded__c = succeeded,
            Records_Failed__c = failed,
            Error_Summary__c = String.join(errorSummaries, '\n').abbreviate(30000)
        ));
    }
}