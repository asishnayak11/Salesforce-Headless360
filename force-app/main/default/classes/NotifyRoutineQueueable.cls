public class NotifyRoutineQueueable implements Queueable, Database.AllowsCallouts {
    
    private static final String ENDPOINT_URL = 'callout:Claude_Routine/';
    
    private List<Bulk_Job_Settled__e> events;
    public NotifyRoutineQueueable(List<Bulk_Job_Settled__e> events) { this.events = events; }

    public void execute(QueueableContext ctx) {
        for (Bulk_Job_Settled__e evt : events) {
            String bodyText = JSON.serialize(new Map<String, Object>{
                'jobId' => evt.Job_Id__c,
                'recordsProcessed' => evt.Records_Processed__c,
                'succeeded' => evt.Records_Succeeded__c,
                'failed' => evt.Records_Failed__c,
                'status' => 'Completed',
                'errors' => evt.Error_Summary__c
            });

            HttpRequest req = new HttpRequest();
            req.setEndpoint(ENDPOINT_URL + 'v1/claude_code/routines/trig_01BhPZ7pcwgDYZWqBNBfUUBB/fire');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('anthropic-version', '2023-06-01');
            req.setHeader('anthropic-beta', 'experimental-cc-routine-2026-04-01');
            // Authorization header no longer set here — Named Credential injects it
            req.setBody(JSON.serialize(new Map<String, String>{ 'text' => bodyText }));

            new Http().send(req);
        }
    }
}