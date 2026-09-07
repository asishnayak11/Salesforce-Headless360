@RestResource(urlMapping='/BulkJobs/MassUpdateAccounts')
global with sharing class MassUpdateAccountsRestApi {

    @HttpPost
    global static Map<String, String> startJob() {
        Id jobId = Database.executeBatch(new MassUpdateAccountsBatch(), 200);

        String trackingMessage = 'Job submitted successfully. You can track its progress in Salesforce '
            + 'under Setup → Apex Jobs (search "Apex Jobs" in the Setup Quick Find box), using batch job ID '
            + jobId + '. Once the job completes, you will be notified with the full results — including '
            + 'success/failure counts and any errors — in the #salesforce-jobs Slack channel.';

        return new Map<String, String>{
            'status' => 'Submitted',
            'batchJobId' => jobId,
            'message' => trackingMessage
        };
    }
}