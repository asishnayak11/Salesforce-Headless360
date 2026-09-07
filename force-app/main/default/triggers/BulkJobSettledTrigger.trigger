trigger BulkJobSettledTrigger on Bulk_Job_Settled__e (after insert) {
    System.enqueueJob(new NotifyRoutineQueueable(Trigger.new));
}