/**
 * @description Loads {@link Stakeholder_Detail__c} rows for the Work Order's Account and invokes Hubpay related-person / corporate APIs (static payloads until field mapping exists).
 */
public inherited sharing class HubpayShareholderSyncQueueable implements Queueable, Database.AllowsCallouts {
    /** @description Match {@link HubpayWorkStepShareholderService} for log filtering. */
    private static final String LOG_PREFIX = 'HubpayShareholderSync';

    /** @description Soft guard; Hubpay actions issue one callout per shareholder. Salesforce allows 100 callouts per transaction. */
    private static final Integer CALLOUT_WARNING_THRESHOLD = 85;

    private Id workOrderId;

    public HubpayShareholderSyncQueueable(Id workOrderId) {
        this.workOrderId = workOrderId;
    }

    public void execute(QueueableContext context) {
        System.debug(
            LoggingLevel.INFO,
            LOG_PREFIX +
                ' Queueable START parentJobId=' +
                (context == null ? 'null' : String.valueOf(context.getJobId())) +
                ' workOrderId=' +
                String.valueOf(workOrderId)
        );

        if (workOrderId == null) {
            System.debug(LoggingLevel.WARN, LOG_PREFIX + ' Queueable exit: workOrderId is null.');
            return;
        }

        List<WorkOrder> workOrders = [
            SELECT Id, AccountId, Account.Opt_in_for_Hubpay__c
            FROM WorkOrder
            WHERE Id = :workOrderId
            LIMIT 1
        ];
        if (workOrders.isEmpty()) {
            System.debug(LoggingLevel.WARN, LOG_PREFIX + ' Queueable exit: WorkOrder not found. workOrderId=' + workOrderId);
            return;
        }
        WorkOrder wo = workOrders[0];
        if (wo.AccountId == null || wo.Account == null || wo.Account.Opt_in_for_Hubpay__c != true) {
            System.debug(
                LoggingLevel.INFO,
                LOG_PREFIX +
                    ' Queueable exit: missing Account or Hubpay opt-in false. workOrderId=' +
                    wo.Id +
                    ' accountId=' +
                    wo.AccountId
            );
            return;
        }

        Id businessAccountId = wo.AccountId;
        List<Stakeholder_Detail__c> stakeholderRows = [
            SELECT Id, Individual_Stakeholder__c, Corporate_Stakeholder__c
            FROM Stakeholder_Detail__c
            WHERE Business_Account__c = :businessAccountId
        ];

        System.debug(
            LoggingLevel.INFO,
            LOG_PREFIX +
                ' Loaded Stakeholder_Detail__c rows=' +
                stakeholderRows.size() +
                ' for Business_Account__c=' +
                businessAccountId
        );

        List<HubpayAddShareholderAction.Request> individualRequests = new List<HubpayAddShareholderAction.Request>();
        List<HubpayAddCorporateShareholderAction.Request> corporateRequests = new List<HubpayAddCorporateShareholderAction.Request>();

        for (Stakeholder_Detail__c row : stakeholderRows) {
            if (row.Corporate_Stakeholder__c != null) {
                HubpayAddCorporateShareholderAction.Request corpReq = new HubpayAddCorporateShareholderAction.Request();
                corpReq.accountId = businessAccountId;
                corpReq.stakeholderDetailId = row.Id;
                corporateRequests.add(corpReq);
            } else if (row.Individual_Stakeholder__c != null) {
                HubpayAddShareholderAction.Request indReq = new HubpayAddShareholderAction.Request();
                indReq.accountId = businessAccountId;
                indReq.stakeholderDetailId = row.Id;
                individualRequests.add(indReq);
            }
        }

        Integer estimatedCallouts = individualRequests.size() + corporateRequests.size();
        if (estimatedCallouts > CALLOUT_WARNING_THRESHOLD) {
            System.debug(
                LoggingLevel.WARN,
                LOG_PREFIX +
                    ' stakeholder count may exceed safe callout budget. estimatedCallouts=' +
                    estimatedCallouts +
                    ' workOrderId=' +
                    String.valueOf(workOrderId)
            );
        }

        if (individualRequests.isEmpty() && corporateRequests.isEmpty()) {
            System.debug(
                LoggingLevel.INFO,
                LOG_PREFIX +
                    ' DONE — No individual or corporate shareholders to sync (0 Hubpay calls). accountId=' +
                    businessAccountId
            );
            return;
        }

        System.debug(
            LoggingLevel.INFO,
            LOG_PREFIX +
                ' Calling Hubpay: individuals=' +
                individualRequests.size() +
                ' corporates=' +
                corporateRequests.size() +
                ' (approx callouts=' +
                estimatedCallouts +
                ')'
        );

        if (!individualRequests.isEmpty()) {
            List<HubpayAddShareholderAction.Result> indResults = HubpayAddShareholderAction.execute(individualRequests);
            logHubpayPersonResults(indResults);
        }
        if (!corporateRequests.isEmpty()) {
            List<HubpayAddCorporateShareholderAction.Result> corpResults = HubpayAddCorporateShareholderAction.execute(corporateRequests);
            logHubpayCorporateResults(corpResults);
        }

        System.debug(
            LoggingLevel.INFO,
            LOG_PREFIX +
                ' Queueable FINISHED workOrderId=' +
                workOrderId +
                ' accountId=' +
                businessAccountId
        );
    }

    private static void logHubpayPersonResults(List<HubpayAddShareholderAction.Result> results) {
        if (results == null || results.isEmpty()) {
            System.debug(LoggingLevel.WARN, LOG_PREFIX + ' HubpayAddShareholderAction returned no results.');
            return;
        }
        Integer ok = 0;
        Integer fail = 0;
        for (HubpayAddShareholderAction.Result r : results) {
            if (r != null && r.success == true) {
                ok++;
            } else {
                fail++;
                System.debug(
                    LoggingLevel.ERROR,
                    LOG_PREFIX +
                        ' Individual shareholder API failed accountId=' +
                        (r == null ? null : r.accountId) +
                        ' stakeholderDetailId=' +
                        (r == null ? null : r.stakeholderDetailId) +
                        ' msg=' +
                        (r == null ? null : r.message)
                );
            }
        }
        System.debug(
            LoggingLevel.INFO,
            LOG_PREFIX + ' HubpayAddShareholderAction batch summary success=' + ok + ' failed=' + fail + ' total=' + results.size()
        );
    }

    private static void logHubpayCorporateResults(List<HubpayAddCorporateShareholderAction.Result> results) {
        if (results == null || results.isEmpty()) {
            System.debug(LoggingLevel.WARN, LOG_PREFIX + ' HubpayAddCorporateShareholderAction returned no results.');
            return;
        }
        Integer ok = 0;
        Integer fail = 0;
        for (HubpayAddCorporateShareholderAction.Result r : results) {
            if (r != null && r.success == true) {
                ok++;
            } else {
                fail++;
                System.debug(
                    LoggingLevel.ERROR,
                    LOG_PREFIX +
                        ' Corporate shareholder API failed accountId=' +
                        (r == null ? null : r.accountId) +
                        ' stakeholderDetailId=' +
                        (r == null ? null : r.stakeholderDetailId) +
                        ' msg=' +
                        (r == null ? null : r.message)
                );
            }
        }
        System.debug(
            LoggingLevel.INFO,
            LOG_PREFIX + ' HubpayAddCorporateShareholderAction batch summary success=' + ok + ' failed=' + fail + ' total=' + results.size()
        );
    }
}