/*********************************************************************************************************************************
 * @Class Name		:  DAO_TestDataFactory
 * @Description		:  Data Factory to setup all the Test data
 * @Author			:  Shruti Singh (Horizontal)
 * @Date				:  19/07/2023
 * @JIRA				:  RAKDAO-64, RAKDAO-201, RAKDAO-46, RAKDAO-47, RAKDAO 50
 * Revision Log  	:  V1.0 Created
 *******************************************************************************************************************************/
public class DAO_TestDataFactory {
    // Maximum bulkification count
    public static final Integer BULKIFICATION_COUNT = 5;
    
    //********************************************************************************
    //* Method      :   getUniqueName
    //* Description :   Get a unique name for unique username
    //* Parameters  :   None
    //* Returns     :   String, uniqueName
    //*********************************************************************************/
    public static String getUniqueName() {
        // String orgId = UserInfo.getOrganizationId();
        // String dateString = String.valueof(Datetime.now())
        //     .replace(' ', '')
        //     .replace(':', '')
        //     .replace('-', '');
        // Integer randomInt = Integer.valueOf(Math.rint(Math.random() * 1000000));
        // return orgId + dateString + randomInt;

        return UserInfo.getOrganizationId() +
           Datetime.now().format('yyyyMMddHHmmss') +
           Math.round(Math.random() * 1000000);
    }
    
    //********************************************************************************
    //* Method      :   getTestContact
    //* Description :   Get a test Contact record
    //* Parameters  :   String firstName, the first name of contact
    //					String lastName, the last name of contact
    //					Id accountId, the accountId of contact
    //                  Boolean isInsert, whether to insert Contact or not
    //* Returns     :   Contact, a Contact record
    //*********************************************************************************/
    public static Contact getTestContact(String firstName, String lastName, Id accountId, Boolean isInsert) {
        String orgId = UserInfo.getOrganizationId();
        String uniqueName = getUniqueName();
        Contact con = new Contact();
        con.FirstName = firstName;
        con.LastName = lastName;
        con.Email = uniqueName + '@test' + orgId + '.org';
        con.MobilePhone = String.valueOf(Math.abs(Crypto.getRandomLong())).substring(0, 10);
        con.AccountId = accountId;
        
        if (isInsert) {
            insert con;
        }
        return con;
    }
    
    //********************************************************************************
    //* Method      :   getTestUser
    //* Description :   Get User with given profile
    //* Parameters  :   String firstName, the first name of the user
    //                  String lastName, the last name of the user
    //                  Id roleId, the roleId for user
    //                  Id profileId, the profileId for user
    //                  Id managerId, the managerId for user
    //                  Id contactId, the contactId for user
    //                  Boolean isInsert, whether to insert user or not
    //* Returns     :   User, an user record
    //*********************************************************************************/
    public static User getTestUser(String firstName, String lastName, Id roleId, Id profileId, Id managerId, Id contactId, Boolean isInsert) {
        String orgId = UserInfo.getOrganizationId();
        String uniqueName = getUniqueName();
        User usr = new User();
        usr.FirstName = firstName;
        usr.LastName = lastName;
        usr.Email = uniqueName + '@test' + orgId + '.org';
        usr.Username = uniqueName + '@test' + orgId + '.org';
        usr.EmailEncodingKey = 'ISO-8859-1';
        usr.Alias = uniqueName.substring(18, 20);
        usr.TimeZoneSidKey = 'America/Los_Angeles';
        usr.LocaleSidKey = 'en_US';
        usr.LanguageLocaleKey = 'en_US';
        usr.ProfileId = profileId;
        usr.UserRoleId = roleId;
        usr.ManagerId = managerId;
        usr.ContactId = contactId;
        
        if (isInsert) {
            insert usr;
        }
        return usr;
    }
    
    //********************************************************************************
    //* Method      :   getTestLead
    //* Description :   Get a test lead record
    //* Parameters  :   String firstName, the first name of lead
    //                  String lastName, the last name of lead
    //                  Boolean isInsert, whether to insert lead or not
    //* Returns     :   Lead, a lead record
    //* Added by    :   Shruti Singh - RAKDAO-64 - To get a test lead record
    //*********************************************************************************/
    public static Lead getTestLead(String firstName, String lastName, Boolean isInsert) {
        String orgId = UserInfo.getOrganizationId();
        String uniqueName = getUniqueName();
        Lead ld = new Lead();
        ld.FirstName = firstName;
        ld.LastName = lastName;
        ld.Nationality__c = 'IN';
        ld.License_Type__c = 'Standard Company';
        ld.Activity_Group__c = 'DAO';
        ld.Status = 'New';
        ld.Company = firstName + 'T Company';
        ld.LeadSource = 'Website';
        ld.Email = uniqueName + '@test' + orgId + '.org';
        
        if (isInsert) {
            insert ld;
        }
        return ld;
    }
    
    //********************************************************************************
    //* Method      :   getTestAccount
    //* Description :   Get a test account record
    //* Parameters  :   String name, name of the test account record
    //                  Boolean isInsert, whether to insert account or not
    //* Returns     :   Account, an Account record
    //* Added by    :   Shruti Singh - RAKDAO-201 - To get a test account record
    //*********************************************************************************/
    public static Account getTestAccount(String name, Id recordTypeId, Boolean isInsert) {
        String orgId = UserInfo.getOrganizationId();
        String uniqueName = getUniqueName();
        Account acc = new Account();
        acc.RecordTypeId = recordTypeId;
        acc.Name = name;
        acc.BillingCountryCode = 'AF';
        acc.Primary_Email__c = uniqueName + '@test' + orgId + '.org';
        
        if (isInsert) {
            insert acc;
        }
        return acc;
    }
    
    //********************************************************************************
    //* Method      :   getTestAccountWithStatus
    //* Description :   Get a test account record with full data
    //* Parameters  :   String name, name of the test account record
    //                  String Status, status of the account and has to be one of the picklist values
    //                  String entityType, entity type of the account and has to be one of the picklist values
    //                  Boolean isInsert, whether to insert account or not
    //* Returns     :   Account, an Account record
    //*********************************************************************************/
    public static Account getTestAccountWithStatus(String name, Id recordTypeId, String Status, String entityType, Boolean isInsert) {
        String orgId = UserInfo.getOrganizationId();
        String uniqueName = getUniqueName();
        Account acc = new Account();
        acc.RecordTypeId = recordTypeId;
        acc.Name = name;
        acc.BillingCountryCode = 'AF';
        acc.Primary_Email__c = uniqueName + '@test' + orgId + '.org';
        acc.Account_Status__c = Status;
        acc.Entity_Type__c = entityType;
        
        if (isInsert) {
            insert acc;
        }
        return acc;
    }
    
    //********************************************************************************
    //* Method      :   getTestOpportunity
    //* Description :   Get a test opportunity record
    //* Parameters  :   String name, name of the opportunity record
    //                  Id accountId, related account Id
    //                  Boolean isInsert, whether to insert opportunity or not
    //* Returns     :   Opportunity, an opportunity record
    //* Added by    :   Shruti Singh - RAKDAO-201 - To get a test opportunity record
    //*********************************************************************************/
    public static Opportunity getTestOpportunity(String name, String licenseType, Id accountId, Id primaryContactId,
    Boolean isInsert)
    {
        Opportunity opp = new Opportunity();
        String incorporateOppRecordTypeId = SObjectType.Opportunity.getRecordTypeInfosByName().get('New Incorporation').getRecordTypeId();
        opp.RecordTypeId = incorporateOppRecordTypeId;
        opp.Name = name;
        opp.AccountId = accountId;
        opp.StageName = 'Prospecting';
        opp.CloseDate = Date.today() + 10;
        if(String.isNotBlank(licenseType)) {
            opp.License_Type__c = licenseType;
        } else {
            opp.License_Type__c = 'Standard Company';
        }
        if(licenseType == 'Standard Company') {
            opp.Customer_Looking_For__c = 'Dedicated Office';
        }
        opp.Primary_Contact__c = primaryContactId;
        opp.Pricebook2Id = Test.getStandardPricebookId();
        if (isInsert) {
            insert opp;
        }
        return opp;
    }
    
    //********************************************************************************
    //* Method      :   getTestActivityGroup
    //* Description :   Get a test activity Group record
    //* Parameters  :   String name, the name of the activity group
    //                  String licenseType, the license type of the activity group
    //                  Boolean isActive, whether the activity group is active or not
    //                  Boolean isInsert, whether to insert activity group or not
    //* Returns     :   Activity_Group__c, an Activity Group record
    //*********************************************************************************/
    public static Activity_Group__c getTestActivityGroup(String name, String licenseType, Boolean isActive, Boolean isInsert) {
        Activity_Group__c activityGroup = new Activity_Group__c();
        activityGroup.Name = name;
        activityGroup.Active__c = isActive;
        activityGroup.License_Type__c = licenseType;
        
        if(isInsert) {
            insert activityGroup;
        }
        return activityGroup;
    }
    
    //********************************************************************************
    //* Method      :   getTestSubActivity
    //* Description :   Get a test Sub activity
    //* Parameters  :   String Name, the name of the sub activity
    //                  String licenseType, the license type of the sub activity
    //                  String code, the code of the sub activity
    //                  Boolean isPremium, whether the sub activity is premium or not
    //                  Boolean isActive, whether the sub activity is active or not
    //                  Id businessGroup, business group Id of the sub activity
    //                  Boolean isInsert, whether to insert sub activity or not
    //* Returns     :   Sub_Activity__c, a Sub activity record
    //*********************************************************************************/
    public static Sub_Activity__c getTestSubActivity(String name, String licenseType, String code, Boolean isActive, Boolean isPremium, Id businessGroup, Boolean isInsert) {
        Sub_Activity__c subActivity = new Sub_Activity__c();
        subActivity.Name = name;
        subActivity.Active__c = isActive;
        subActivity.Code__c = code;
        subActivity.Premium__c = isPremium;
        subActivity.Activity_Group__c = businessGroup;
        subActivity.License_Type__c = licenseType;
        
        if (isInsert) {
            insert subActivity;
        }
        return subActivity;
    }
    
    //********************************************************************************
    //* Method      :   getTestBusinessActivity
    //* Description :   Get a test Business activity
    //* Parameters  :   String licenseType, the license type of the business activity
    //                  Id businessGroup, the business group Id of the business activity
    //                  Id of subActivity, the sub activity Id of the business activity
    //                  Id accountId, Account Id related to business activity
    //                  Id opportunityId, Opportunity Id related to business activity
    //                  Id leadId, Lead Id related to business activity
    //                  Boolean isInsert, whether to insert business activity or not
    //* Returns     :   Business_Activity__c, a Business Activity record
    //*********************************************************************************/
    public static Business_Activity__c getTestBusinessActivity(String licenseType, Id businessGroup, Id subActivity, Id accountId, Id opportunityId, Id leadId, Boolean isInsert) {
        Business_Activity__c businessActivity = new Business_Activity__c();
        businessActivity.License_Type__c = licenseType;
        businessActivity.Account__c = accountId;
        businessActivity.Opportunity__c = opportunityId;
        businessActivity.Lead__c = leadId;
        businessActivity.Activity_Group__c = businessGroup;
        businessActivity.Activity__c = subActivity;
        
        if (isInsert) {
            insert businessActivity;
        }
        return businessActivity;
    }
    
    //********************************************************************************
    //* Method      :   getTestQueues
    //* Description :   This method creates test data for Queues
    //* @Params     :   String associatedObjectName, the associated object name
    //                  List<String> queueNames, the list of queue names
    //                  Boolean isInsert, whether to insert the queues or not
    //* @Returns    :   List<Group>, the list of queues
    //*********************************************************************************/
    public static List<Group> getTestQueues(String associatedObjectName, List<String> queueNames ,Boolean isInsert) {
        List<Group> testQueues = new List<Group>();
        for (String name : queueNames) {
            testQueues.add(new Group(Name = name, Type = DAO_Constants.GROUP_TYPE_QUEUE));
        }
        if(isInsert) {
            insert testQueues;
            List<QueuesObject> queueAssocList = new List<QueuesObject>();
            for(Group queue: testQueues) {
                QueuesObject testQueue = new QueueSObject(QueueID = queue.Id, SobjectType = associatedObjectName);
                queueAssocList.add(testQueue);
            }
            insert queueAssocList;
        }
        return testQueues;
    }
    
    //***************************************************************************************
    //* @Method         :   getTestQueueMembers
    //* @Description    :   This method creates test data for Queue Members
    //* @Params         :   Map<String, String> queueIdUserIdMap, the map of queue Ids and their associated User Ids
    //                      Boolean isInsert, whether to insert Queue Members or not
    //* @Returns        :   List<GroupMember>, the list of Queue Members
    //****************************************************************************************/
    public static List<GroupMember> getTestQueueMembers(Map<String, String> queueIdUserIdMap, Boolean isInsert) {
        List<GroupMember> queueMembersList = new List<GroupMember>();
        for (String queueId : queueIdUserIdMap.keySet()) {
            queueMembersList.add( new GroupMember(GroupId = queueId,
            UserOrGroupId = queueIdUserIdMap.get(queueId)));
        }
        
        if(isInsert) {
            insert queueMembersList;
        }
        return queueMembersList;
    }
    
    //***************************************************************************************
    //* @Method         :   getTestEmailTemplates
    //* @Description    :   This method creates test data for Email Templates
    //* @Params         :   List<String> templateNames, the list of Email Template names
    //                      Boolean isInsert, whether to insert Email Templates or not
    //* @Returns        :   List<GroupMember>, the list of Email Templates
    //****************************************************************************************/
    public static List<EmailTemplate> getTestEmailTemplates(List<String> templateNames, Boolean isInsert) {
        List<EmailTemplate> emailTemplateList = new List<EmailTemplate>();
        for(String name: templateNames) {
            EmailTemplate validEmailTemplate = new EmailTemplate();
            validEmailTemplate.isActive = true;
            validEmailTemplate.Name = name.replaceAll('_',' ');
            validEmailTemplate.TemplateType = 'text';
            validEmailTemplate.FolderId = UserInfo.getUserId();
            validEmailTemplate.Subject = 'Test Sub';
            validEmailTemplate.DeveloperName = name;
            emailTemplateList.add(validEmailTemplate);
        }
        
        if(isInsert) {
            insert emailTemplateList;
        }
        return emailTemplateList;
    }
    
    //********************************************************************************
    //* Method      :   getTestProduct
    //* Description :   Get a test product record
    //* Parameters  :   String name, name of product
    //                  String productFamily, product family for product
    //                  String productCategory, product category for product
    //                  Boolean isInsert, whether to insert product or not
    //* Returns     :   Product2, a product record record
    //* Added by    :   Harshit Goyal - RAKDAO 46 - To get a test product record
    //*********************************************************************************/
    public static Product2 getTestProduct(String name, String productFamily, String productCategory, Boolean isInsert) {
        Product2 testProduct = new Product2();
        testProduct.Name = name;
        testProduct.Family = productFamily;
        testProduct.Product_Category__c = productCategory;
        testProduct.IsActive = true;
        testProduct.ProductCode = getUniqueName(); 
        // testProduct.ShowInAgentPortal__c = true; testProduct.ShowInCustomerPortal__c = true;
        
        if (isInsert) {
            insert testProduct;
        }
        return testProduct;
    }
    
    //********************************************************************************
    //* Method      :   getTestPriceBookEntry
    //* Description :   Get a test price book Entry record
    //* Parameters  :   Decimal unitPrice, unit price for product
    //					Id productId, id of product
    //                  Boolean isInsert, whether to insert price book entry or not
    //* Returns     :   PricebookEntry, a price book entry record
    //* Added by    :   Harshit Goyal - RAKDAO 46 - To get a test price book entry record
    //*********************************************************************************/
    public static PricebookEntry getTestPriceBookEntry(Decimal unitPrice, Id productId, Boolean isInsert) {
        PricebookEntry testPricebookEntry = new PricebookEntry();
        testPricebookEntry.Pricebook2Id = Test.getStandardPricebookId();
        testPricebookEntry.Product2Id = productId;
        testPricebookEntry.IsActive = true;
        testPricebookEntry.UnitPrice = unitPrice;
        
        if (isInsert) {
            insert testPricebookEntry;
        }
        return testPricebookEntry;
    }
    
    //********************************************************************************
    //* Method      :   getTestOpportunityLineItem
    //* Description :   Get a test Opportunity Line Item record
    //* Parameters  :   Integer quantity, quantity of product
    //					Decimal unitPrice, unit price of product
    //					Id opportunityId, id of oppotunity
    //					Id productId, id of product
    //                  Boolean isInsert, whether to insert price book entry or not
    //* Returns     :   PricebookEntry, a price book entry record
    //* Added by    :   Harshit Goyal - RAKDAO 46 - To get a test price book entry record
    //*********************************************************************************/
    public static OpportunityLineItem getTestOpportunityLineItem(Integer quantity, Decimal unitPrice,
    Id opportunityId, Id productId, Boolean isInsert)
    {
        OpportunityLineItem testOLI = new OpportunityLineItem();
        testOLI.OpportunityId = opportunityId;
        testOLI.Product2Id = productId;
        testOLI.Quantity = quantity;
        testOLI.UnitPrice = unitPrice;
        
        if (isInsert) {
            insert testOLI;
        }
        return testOLI;
    }
    
    //********************************************************************************
    //* Method      :   getTestWorkOrder
    //* Description :   Get a test work order record
    //* Parameters  :   Id accountId, the account ID associated with the work order
    //                  Id contactId, the contact ID associated with the work order
    //                  Id oppId, the opportunity ID associated with the work order
    //                  String internalStatus, internal status of the work order
    //                  String externalStatus, external status of the work order
    //                  Boolean isInsert, whether to insert work order or not
    //* Returns     :   Work Order, a work order record
    //* Added by    :   Shruti Singh - RAKDAO 47 - To get a test work order record
    //*********************************************************************************/
    public static WorkOrder getTestWorkOrder(Id accountId, Id contactId, Id oppId, String licenseType,String internalStatus, String externalStatus,
    Boolean isInsert)
    {
        WorkOrder testWorkOrder = new WorkOrder();
        testWorkOrder.AccountId = accountId;
        testWorkOrder.ContactId = contactId;
        testWorkOrder.Opportunity__c = oppId;
        testWorkOrder.License_Type__c = licenseType;
        testWorkOrder.Status = internalStatus;
        testWorkOrder.External_Status__c = externalStatus;
        testWorkOrder.Suggested_Company_Name_1__c = 'Company Inc';
        testWorkOrder.Suggested_Company_Name_2__c = 'Company Cls';
        testWorkOrder.Suggested_Company_Name_3__c = 'Company Unltd';
        
        if (isInsert) {
            insert testWorkOrder;
        }
        return testWorkOrder;
    }
    
    //********************************************************************************
    //* Method      :   getTestWorkPlanTemplate
    //* Description :   Get a test Work Plan Template record
    //* Parameters  :   String name, the name of Work Plan Template
    //					String licenseType, license type of Work Plan Template
    //					Integer relativeExecutionOrder, order in which Work Plan Template will get executed
    //					Boolean isInsert, whether to insert Work Plan Template record or not
    //* Returns     :   Work Plan Template, a Work Plan Template record
    //* Added by    :   Shruti Singh - RAKDAO 47 - To get a test Work Plan Template record
    //*********************************************************************************/
    public static WorkPlanTemplate getTestWorkPlanTemplate(String name, String licenseType, Integer relativeExecutionOrder, Boolean isInsert) {
        WorkPlanTemplate testWorkPlanTemplate = new WorkPlanTemplate();
        testWorkPlanTemplate.Name = name;
        testWorkPlanTemplate.IsActive = true;
        testWorkPlanTemplate.RelativeExecutionOrder = relativeExecutionOrder;
        testWorkPlanTemplate.License_Type__c = licenseType;
        
        if (isInsert) {
            insert testWorkPlanTemplate;
        }
        return testWorkPlanTemplate;
    }
    
    //********************************************************************************
    //* Method      :   getTestWorkStepTemplate
    //* Description :   Get a test Work Step Template record
    //* Parameters  :   String name, the name of Work Step Template
    //					String actionDefinition, platform action that the work step template executes
    //					String stepHeader, the header used in Work Step Template
    //					String stepIcon, the icon used in Work Step Template
    //					String stepSubHeader, the sub header used in Work Step Template
    //					Boolean isInsert, whether to insert Work Step Template record or not
    //* Returns     :   Work Step Template, a Work Step Template record
    //* Added by    :   Shruti Singh - RAKDAO 47 - To get a test Work Step Template record
    //*********************************************************************************/
    public static WorkStepTemplate getTestWorkStepTemplate(String name, String actionDefinition,
    String stepHeader,
    String stepIcon,
    String stepSubHeader, Boolean isInsert)
    {
        WorkStepTemplate testWorkStepTemplate = new WorkStepTemplate();
        testWorkStepTemplate.Name = name;
        testWorkStepTemplate.ActionDefinition = actionDefinition;
        testWorkStepTemplate.Is_Portal__c = true;
        testWorkStepTemplate.IsActive = true;
        testWorkStepTemplate.Step_Header__c = stepHeader;
        testWorkStepTemplate.Step_Icon__c = stepIcon;
        testWorkStepTemplate.Step_Subheader__c = stepSubHeader;
        
        if (isInsert) {
            insert testWorkStepTemplate;
        }
        return testWorkStepTemplate;
    }
    
    //********************************************************************************
    //* Method      :   getTestWorkPlanTemplateEntry
    //* Description :   Get a test Work Plan Template Entry record
    //* Parameters  :   Integer executionOrder, order in which Work Plan Template Entry will get executed
    //					Id workPlanTemplateId, Id of related Work Plan Template
    //					Id workStepTemplateId, Id of related Work Step Template
    //					Boolean isInsert, whether to insert Work Plan Template Entry record or not
    //* Returns     :   Work Plan Template Entry, a Work Plan Template Entry record
    //* Added by    :   Shruti Singh - RAKDAO 47 - To get a test Work Plan Template Entry record
    //*********************************************************************************/
    public static WorkPlanTemplateEntry getTestWorkPlanTemplateEntry(Integer executionOrder, Id workPlanTemplateId, Id workStepTemplateId, Boolean isInsert) {
        WorkPlanTemplateEntry testWorkPlanTemplateEntry = new WorkPlanTemplateEntry();
        testWorkPlanTemplateEntry.WorkPlanTemplateId = workPlanTemplateId;
        testWorkPlanTemplateEntry.WorkStepTemplateId = workStepTemplateId;
        testWorkPlanTemplateEntry.ExecutionOrder = executionOrder;
        
        if (isInsert) {
            insert testWorkPlanTemplateEntry;
        }
        return testWorkPlanTemplateEntry;
    }
    
    //********************************************************************************
    //* Method      :   getTestWorkPlan
    //* Description :   Get a test Work Plan record
    //* Parameters  :   String name, the name of Work Plan
    //					Integer executionOrder, order in which Work Plan will get executed
    //					Id workOrderId, Id of related Work Order
    //					Boolean isInsert, whether to insert Work Plan record or not
    //* Returns     :   Work Plan, a Work Plan record
    //* Added by    :   Shruti Singh - RAKDAO 47 - To get a test Work Plan record
    //*********************************************************************************/
    public static WorkPlan getTestWorkPlan(String name, Integer executionOrder, Id workOrderId,Boolean isInsert) {
        WorkPlan testWorkPlan = new WorkPlan();
        testWorkPlan.Name = name;
        testWorkPlan.WorkOrderId = workOrderId;
        testWorkPlan.ExecutionOrder = executionOrder;
        
        if (isInsert) {
            insert testWorkPlan;
        }
        
        return testWorkPlan;
    }
    
    //********************************************************************************
    //* Method      :   getTestWorkStep
    //* Description :   Get a test Work Step record
    //* Parameters  :   String name, the name of the Work Step record
    //					String actionDefinition, the platform action that the work step executes
    //					String status, the status of Work Step record
    //   				Integer executionOrder, order in which Work Step will get executed
    //					Id workPlanId, Id of related Work Plan record
    //					Boolean isInsert, whether to insert Work Step record or not
    //* Returns     :   Work Step, a Work Step record
    //* Added by    :   Shruti Singh - RAKDAO 47 - To get a test Work Step record
    //*********************************************************************************/
    public static WorkStep getTestWorkStep(String name, String actionDefinition, String status,  Integer executionOrder, Id workPlanId, Boolean isInsert) {
        WorkStep testWorkStep = new WorkStep();
        testWorkStep.Name = name;
        testWorkStep.ActionDefinition = actionDefinition;
        testWorkStep.Status = status;
        testWorkStep.WorkPlanId = workPlanId;
        testWorkStep.ExecutionOrder = executionOrder;
        
        if (isInsert) {
            insert testWorkStep;
        }
        return testWorkStep;
    }
    
    //********************************************************************************
    //* Method      :   getTestIndividualStakeHolderDetail
    //* Description :   Get the Stakeholder Detail record for Individual stakeholder
    //* Parameters  :   Integer numberofShares, Number of Shares
    //                  Boolean isUbo, whether stakeholder is UBO or not
    //                  Boolean owns25PercentShares, whether stakeholder owns 25 percent shares or not
    //                  Id contactId, Related Contact Id
    //                  Id businessAccountId, Related Business Account Id
    //                  Id recordTypeId, Record type id of Individual stakeholder Detail record
    //                  Boolean isInsert, whether to insert stakeholder Detail record or not
    //* Returns     :   StakeHolderDetail, a StakeHolder Detail record
    //* Added by    :   Aashish Pathak - RAKDAO 86 - To get StakeHolder Detail
    //*********************************************************************************/
    public static Stakeholder_Detail__c getTestIndividualStakeHolderDetail(Integer numberofShares,
    Boolean isUbo,
    Boolean owns25PercentShares,
    Id contactId,
    Id businessAccountId,
    Id recordTypeId,
    Boolean isInsert)
    {
        Stakeholder_Detail__c testIndividualStakeHolderDetail = new Stakeholder_Detail__c();
        testIndividualStakeHolderDetail.Individual_Stakeholder__c = contactId;
        testIndividualStakeHolderDetail.Business_Account__c = businessAccountId;
        testIndividualStakeHolderDetail.RecordTypeId = recordTypeId;
        testIndividualStakeHolderDetail.Number_of_Shares__c = NumberofShares;
        testIndividualStakeHolderDetail.Is_UBO__c = isUbo;
        testIndividualStakeHolderDetail.Owns_25_Percent_Shares__c = owns25PercentShares;
        
        if (isInsert) {
            insert testIndividualStakeHolderDetail;
        }
        return testIndividualStakeHolderDetail;
    }
    
    //********************************************************************************
    //* Method      :   getTestCorporateStakeHolderDetail
    //* Description :   Get the Stakeholder Detail record for corporate stakeholder
    //* Parameters  :   String ownershipType, Ownership type of Corporate Stakeholder
    //                  Integer numberofShares, Number of Shares
    //                  Id corporateAccountId, Related Corporate Account Id
    //                  Id businessAccountId, Related Business Account Id
    //                  Id recordTypeId, Record Type Id of Corporate Stakeholder Detail record
    //                  Boolean isInsert, whether to insert Stakeholder Detail record or not
    //* Returns     :   StakeHolderDetail, a StakeHolder Detail record
    //* Added by    :   Maryann Thomas - RAKDAO 87 - To get StakeHolder Detail
    //*********************************************************************************/
    public static Stakeholder_Detail__c getTestCorporateStakeHolderDetail(String ownershipType,
    Integer numberofShares,
    Id corporateAccountId,
    Id businessAccountId,
    Id recordTypeId,
    Boolean isInsert)
    {
        Stakeholder_Detail__c testCorporateStakeHolderDetail = new Stakeholder_Detail__c();
        testCorporateStakeHolderDetail.Business_Account__c = businessAccountId;
        testCorporateStakeHolderDetail.Corporate_Stakeholder__c = corporateAccountId;
        testCorporateStakeHolderDetail.RecordTypeId = recordTypeId ;
        testCorporateStakeHolderDetail.Number_of_Shares__c = NumberofShares;
        testCorporateStakeHolderDetail.Ownership_Type__c = ownershipType;
        
        if (isInsert) {
            insert testCorporateStakeHolderDetail;
        }
        return testCorporateStakeHolderDetail;
    }
    
    //********************************************************************************
    //* Method      :   getTestUBOStakeHolderDetail
    //* Description :   Get the Stakeholder Detail for UBO stakeholder
    //* Parameters  :   Boolean isUbo, whether stakeholder is UBO or not
    //                  Id ContactId, Related Contact Id
    //                  Id accountId, Related Corporate Account Id
    //                  Id recordTypeId, Record type id of Individual stakeholder Detail record
    //                  Boolean isInsert, whether to insert stakeholder Detail record or not
    //* Returns     :   StakeHolderDetail, a StakeHolder Detail record
    //* Added by    :   Shruti Singh - RAKDAO 50 - To get StakeHolder Detail
    //*********************************************************************************/
    public static Stakeholder_Detail__c getTestUBOStakeHolderDetail(Boolean isUbo,
    Id contactId,
    Id accountId,
    Id bussinessAccountId,
    Id recordTypeId,
    Boolean isInsert)
    {
        Stakeholder_Detail__c testNomineeStakeHolderDetail = new Stakeholder_Detail__c();
        testNomineeStakeHolderDetail.Individual_Stakeholder__c = contactId;
        testNomineeStakeHolderDetail.Nominated_By_Corporate_Stakeholder__c = accountId;
        testNomineeStakeHolderDetail.RecordTypeId = recordTypeId;
        testNomineeStakeHolderDetail.Is_UBO__c =  isUbo;
        testNomineeStakeHolderDetail.Business_Account__c =  bussinessAccountId;
        
        if (isInsert) {
            insert testNomineeStakeHolderDetail;
        }
        return testNomineeStakeHolderDetail;
    }
    
 
    //********************************************************************************
    //* Method      :   getTestUBOStakeHolderDetailNominatedByCorporate
    //* Description :   Get the Stakeholder Detail for UBO stakeholder Nominated By Corporate
    //* Parameters  :   Boolean isUbo, whether stakeholder is UBO or not
    //                  Id ContactId, Related Contact Id
    //                  Id accountId, Related Corporate Account Id
    //                  Id recordTypeId, Record type id of Individual stakeholder Detail record
    //                  Boolean isInsert, whether to insert stakeholder Detail record or not
    //* Returns     :   StakeHolderDetail, a StakeHolder Detail record
    //* Added by    :   Shruti Singh - RAKDAO 50 - To get StakeHolder Detail
    //*********************************************************************************/

    public static Stakeholder_Detail__c getTestUBOStakeHolderDetailNominatedByCorporate(Boolean isUbo,
    Id contactId,
    Id nominatedByStakeholderId,
    Id bussinessAccountId,
    Id recordTypeId,
    Boolean isInsert)
    {
        Stakeholder_Detail__c testNomineeStakeHolderDetail = new Stakeholder_Detail__c();
        testNomineeStakeHolderDetail.Individual_Stakeholder__c = contactId;
        testNomineeStakeHolderDetail.Nominated_By_Corporate_Stakeholder__c = nominatedByStakeholderId;
        testNomineeStakeHolderDetail.RecordTypeId = recordTypeId;
        testNomineeStakeHolderDetail.Is_UBO__c =  isUbo;
        testNomineeStakeHolderDetail.Business_Account__c =  bussinessAccountId;
        
        if (isInsert) {
            insert testNomineeStakeHolderDetail;
        }
        return testNomineeStakeHolderDetail;
    }
    
    
    //********************************************************************************
    //* Method      :   getTestNomineeStakeHolderDetail
    //* Description :   Get the Stakeholder Detail for Nominee stakeholder
    //* Parameters  :   Boolean isUbo, whether stakeholder is UBO or not
    //                  Id ContactId, Related Contact Id
    //                  Id nominatedByStakeholderId, Related Contact  Id of Shareholder
    //                  Id recordTypeId, Record type id of Individual stakeholder Detail record
    //                  Boolean isInsert, whether to insert stakeholder Detail record or not
    //* Returns     :   StakeHolderDetail, a StakeHolder Detail record
    //* Added by    :   Shruti Singh - RAKDAO 50 - To get StakeHolder Detail
    //*********************************************************************************/
    public static Stakeholder_Detail__c getTestNomineeStakeHolderDetail(Boolean isUbo,
    Id contactId,
    Id nominatedByStakeholderId,
    Id bussinessAccountId,
    Id recordTypeId,
    Boolean isInsert)
    {
        Stakeholder_Detail__c testNomineeStakeHolderDetail = new Stakeholder_Detail__c();
        testNomineeStakeHolderDetail.Individual_Stakeholder__c = contactId;
        testNomineeStakeHolderDetail.Nominated_By_Individual_Stakeholder__c = nominatedByStakeholderId;
        testNomineeStakeHolderDetail.RecordTypeId = recordTypeId;
        testNomineeStakeHolderDetail.Is_UBO__c =  isUbo;
        testNomineeStakeHolderDetail.Business_Account__c =  bussinessAccountId;
        
        if (isInsert) {
            insert testNomineeStakeHolderDetail;
        }
        return testNomineeStakeHolderDetail;
    }
    
    
    //********************************************************************************
    //* Method      :   getTestOpportunityTeamMember
    //* Description :   Get a test opportunity team member record
    //* Parameters  :   String opportunityAccessLevel, opportunityAccessLevel of oppTeamMember
    //                  String teamMemberRole, teamMemberRole of oppTeamMember
    //                  Id opportunityId, related opportunity Id
    //                  Id userId, related User Id
    //                  Boolean isInsert, whether to insert OpportunityTeamMember or not
    //* Returns     :   OpportunityTeamMember, an OpportunityTeamMember record
    //* Added by    :   Akash Deep - RAKDAO-1484 - To get a test OpportunityTeamMember record
    //*********************************************************************************/
    public static OpportunityTeamMember getTestOpportunityTeamMember(String opportunityAccessLevel,
    String teamMemberRole,
    Id opportunityId,
    Id userId,
    Boolean isInsert)
    {
        OpportunityTeamMember teamMember = new OpportunityTeamMember();
        teamMember.OpportunityId = opportunityId;
        teamMember.UserId = userId;
        teamMember.OpportunityAccessLevel = opportunityAccessLevel;
        teamMember.TeamMemberRole = teamMemberRole;
        
        if (isInsert) {
            insert teamMember;
        }
        return teamMember;
    }
    
    //********************************************************************************
    //* Method      :   getTestContentVersion
    //* Description :   Get a test Content Version record
    //* Parameters  :   String fileName, the file name of test Content Version record
    //                  String fileBody, the file body of test Content Version record
    //                  Boolean isInsert, whether to insert test Content Version record or not
    //* Returns     :   ContentVersion, a Content Version record
    //* Added by    :   Shruti Singh - RAKDAO-50 - To get a test Content Version record
    //*********************************************************************************/
    public static ContentVersion getTestContentVersion(String fileName, String fileBody, String fileType, Boolean isInsert) {
        ContentVersion testContentVersion = new ContentVersion();
        testContentVersion.ContentLocation = 'S';
        testContentVersion.PathOnClient = fileName + '.' + fileType;
        testContentVersion.Title = fileName;
        testContentVersion.VersionData = Blob.valueOf(fileBody);
        if (isInsert) {
            insert testContentVersion;
        }
        return testContentVersion;
    }
    
    //********************************************************************************
    //* Method      :   getTestDocumentType
    //* Description :   Get a test document type record
    //* Parameters  :   String documentTypeName, the document type name
    //					String licenseType, the license type of document type
    //					String categoryValue, the category value of document type
    //					String actionType, the action type of document type
    //					Boolean isActive, whether document type record is active or not
    //                  Boolean isInsert, whether to insert test document type record or not
    //* Returns     :   Document Type, a document type record
    //* Added by    :   Shruti Singh - RAKDAO-50 - To get a test document type record
    //*********************************************************************************/
    public static Document_Type__c getTestDocumentType(String documentTypeName, String licenseType, String categoryValue, String actionType, Boolean isActive, Boolean isInsert) {
        Document_Type__c testDocumentType = new Document_Type__c();
        testDocumentType.Name = documentTypeName;
        testDocumentType.License_Type__c = licenseType;
        testDocumentType.Category__c = categoryValue;
        testDocumentType.Action_Type__c = actionType;
        testDocumentType.Is_Active__c = isActive;
        if (isInsert) {
            insert testDocumentType;
        }
        return testDocumentType;
    }
    
    //********************************************************************************
    //* Method      :   getTestContentDocumentLink
    //* Description :   Get a test Content Document Link record
    //* Parameters  :   String shareType, the sharing type of test Content Document Link record
    //                  String visibility, the visibility of test Content Document Link record
    //                  Id linkedEntityId, the linked entity record Id of test Content Document Link record
    //                  Id contentDocumentId, the related document Id of test Content Document Link record
    //                  Boolean isInsert, whether to insert test Content Document Link record or not
    //* Returns     :   ContentDocumentLink, a Content Document Link record
    //* Added by    :   Shruti Singh - RAKDAO-50 - To get a test Content Document Link record
    //*********************************************************************************/
    public static ContentDocumentLink getTestContentDocumentLink(String shareType, String visibility, Id linkedEntityId, Id contentDocumentId, Boolean isInsert) {
        ContentDocumentLink testContentDocumentLink = new ContentDocumentLink();
        testContentDocumentLink.LinkedEntityId = linkedEntityId;
        testContentDocumentLink.ContentDocumentId = contentDocumentId;
        testContentDocumentLink.ShareType = shareType;
        testContentDocumentLink.Visibility = visibility;
        if (isInsert) {
            insert testContentDocumentLink;
        }
        return testContentDocumentLink;
    }
    
    //********************************************************************************
    //* Method      :   getTestPayment
    //* Description :   Get a test Payment record
    //* Parameters  :   Id opportunityId, The ID of the related Opportunity record
    //                  Id payerId, The ID of the Payer record
    //                  Id serviceRequestId, The ID of the related Service Request record
    //                  Id accountId, The ID of the related Account record
    //* Returns     :   Payment__c, a Payment record
    //*********************************************************************************/
    public static Payment__c getTestPayment(Id opportunityId, Id payerId, Id serviceRequestId, Id accountId, Boolean isInsert) {
        Payment__c testPaymentRecord = new Payment__c();
        testPaymentRecord.Opportunity__c = opportunityId;
        testPaymentRecord.Payer__c = payerId;
        testPaymentRecord.Service_Request__c = serviceRequestId;
        testPaymentRecord.Account__c = accountId;
        testPaymentRecord.Effective_Date__c = Date.today();
        testPaymentRecord.Status__c = 'Draft';
        
        if (isInsert) {
            insert testPaymentRecord;
        }
        return testPaymentRecord;
    }
    
    //********************************************************************************
    //* Method      :   getTestDocGenPackage
    //* Description :   Get a test DocGen Package
    //* Parameters  :   String name, the name of DocGen Package
    //                  String outputFileName, the output file name of DocGen Package
    //                  String agreementTemplateName, Name of the Agreement Template
    //* Returns     :   Loop__DDP__c, a DocGen Package record
    //* Added by    :   Shruti Singh - RAKDAO-51 - To get a test DocGen Package record
    //*********************************************************************************/
    public static Loop__DDP__c getTestDocGenPackage(String name, String outputFileName, String agreementTemplateName) {
        //Retrieve Record Type Ids of DocGen Integration options
        Id adobeSignIntegrationOptionRecordTypeId = Schema.SObjectType.Loop__DDP_Integration_Option__c.getRecordTypeInfosByDeveloperName().get('EchoSign').getRecordTypeId();
        Id attachIntegrationOptionRecordTypeId = Schema.SObjectType.Loop__DDP_Integration_Option__c.getRecordTypeInfosByDeveloperName().get('Attach').getRecordTypeId();
        Id downloadIntegrationOptionRecordTypeId = Schema.SObjectType.Loop__DDP_Integration_Option__c.getRecordTypeInfosByDeveloperName().get('Download').getRecordTypeId();
        Id emailIntegrationOptionRecordTypeId = Schema.SObjectType.Loop__DDP_Integration_Option__c.getRecordTypeInfosByDeveloperName().get('Email').getRecordTypeId();
        
        //To insert test Docgen Package record
        Loop__DDP__c testDocGenPackage = new Loop__DDP__c();
        testDocGenPackage.Name = name;
        testDocGenPackage.Loop__Output_Filename__c = outputFileName;
        insert testDocGenPackage;
        
        //List to store test Integration option records to insert
        List<Loop__DDP_Integration_Option__c> testPackageIntegrationOptions = new List<Loop__DDP_Integration_Option__c>();
        echosign_dev1__Agreement_Template__c testTemp;
        if(String.isNotBlank(agreementTemplateName) && agreementTemplateName != NULL) {
            testTemp = getTestAdobeAggrementTemplate(agreementTemplateName, agreementTemplateName, true);
        } else {
            testTemp = getTestAdobeAggrementTemplate('Test Agreement', 'Test Checklist Item', false);
        }
        
        //To create Adobe Sign Package Integration option
        Loop__DDP_Integration_Option__c adobeSignIntegrationOption = new Loop__DDP_Integration_Option__c();
        adobeSignIntegrationOption.Name = DAO_Constants.DOCGEN_PACKAGE_DELIVERY_OPTION_SIGN;
        adobeSignIntegrationOption.Loop__DDP__c = testDocGenPackage.Id;
        adobeSignIntegrationOption.RecordTypeId = adobeSignIntegrationOptionRecordTypeId;
        // Map Agreement Template Id
        adobeSignIntegrationOption.Loop__dsTemplateId__c = testTemp.Id;
        testPackageIntegrationOptions.add(adobeSignIntegrationOption);
        //To create Save to Salesforce File Package Integration option
        Loop__DDP_Integration_Option__c attachIntegrationOption = new Loop__DDP_Integration_Option__c();
        attachIntegrationOption.Name = DAO_Constants.DOCGEN_PACKAGE_DELIVERY_OPTION_SAVE;
        attachIntegrationOption.Loop__DDP__c = testDocGenPackage.Id;
        attachIntegrationOption.RecordTypeId = attachIntegrationOptionRecordTypeId;
        testPackageIntegrationOptions.add(attachIntegrationOption);
        //To create Download Package Integration option
        Loop__DDP_Integration_Option__c downloadIntegrationOption = new Loop__DDP_Integration_Option__c();
        downloadIntegrationOption.Name = DAO_Constants.DOCGEN_PACKAGE_DELIVERY_OPTION_DOWNLOAD;
        downloadIntegrationOption.Loop__DDP__c = testDocGenPackage.Id;
        downloadIntegrationOption.RecordTypeId = downloadIntegrationOptionRecordTypeId;
        testPackageIntegrationOptions.add(downloadIntegrationOption);
        //To create Salesforce Email Package Integration option
        Loop__DDP_Integration_Option__c emailIntegrationOption = new Loop__DDP_Integration_Option__c();
        emailIntegrationOption.Name = DAO_Constants.DOCGEN_PACKAGE_DELIVERY_OPTION_EMAIL;
        emailIntegrationOption.Loop__DDP__c = testDocGenPackage.Id;
        emailIntegrationOption.RecordTypeId = emailIntegrationOptionRecordTypeId;
        testPackageIntegrationOptions.add(emailIntegrationOption);
        //inserting test Package Integration options
        insert testPackageIntegrationOptions;
        
        return testDocGenPackage;
    }
    
    //********************************************************************************
    //* Method      :   getTestAdobeAggrementTemplate
    //* Description :   Get an Adobe Aggrement Template record
    //* Parameters  :   String aggrementTemplateName, the template name of test Adobe Aggrement Template record
    //                  String aggrementName, the aggrement name of Adobe Aggrement Template record
    //                  Boolean isInsert, whether to insert test Adobe Aggrement Template record or not
    //* Returns     :   echosign_dev1__Agreement_Template__c, an Adobe Aggrement Template record
    //* Added by    :   Shruti Singh - RAKDAO-51 - To get an Adobe Aggrement Template record
    //*********************************************************************************/
    public static echosign_dev1__Agreement_Template__c getTestAdobeAggrementTemplate(String aggrementTemplateName, String aggrementName, Boolean isInsert) {
        echosign_dev1__Agreement_Template__c testAdobeAggrementTemplate = new echosign_dev1__Agreement_Template__c();
        testAdobeAggrementTemplate.Name = aggrementTemplateName;
        testAdobeAggrementTemplate.echosign_dev1__Name__c = aggrementName;
        
        if (isInsert) {
            insert testAdobeAggrementTemplate;
        }
        return testAdobeAggrementTemplate;
    }
    
    //********************************************************************************
    //* Method      :   getTestChecklistItem
    //* Description :   Get a test Document Checklist Item record
    //* Parameters  :   String name, the name of Document Checklist Item
    //                  String status, the status of the Document Checklist Item
    //                  Id documentTypeId, The ID of the Document Type record
    //                  Id serviceRequestId, The ID of the related Service Request record
    //                  Id accountId, The ID of the related Account record
    // 					Boolean isInsert, whether to insert Document Checklist Item record or not
    //* Returns     :   Document_Checklist_Item__c, a Document Checklist Item record
    //*********************************************************************************/
    public static Document_Checklist_Item__c getTestChecklistItem(String name, String status, Id documentTypeId, Id serviceRequestId, Id accountId, Boolean isInsert) {
        // Create a test Document_Checklist_Item__c record with explicit values for required fields
        Document_Checklist_Item__c testChecklistItem = new Document_Checklist_Item__c();
        testChecklistItem.Name = name;
        testChecklistItem.Document_Type__c = documentTypeId;
        testChecklistItem.Service_Request__c = serviceRequestId;
        testChecklistItem.Account__c = accountId;
        testChecklistItem.Status__c = status;
        
        if (isInsert) {
            insert testChecklistItem;
        }
        return testChecklistItem;
    }
    
    //********************************************************************************
    //* Method      :   getTestAddress
    //* Description :   Get a test Address record
    //* Parameters  :   String addressType, type of address
    //                  String building, name or number of the building
    //                  String street, street of the address
    //                  String area, area of address
    // 					String state, state in the address.
    // 					String country, country in the address.
    // 					String postalCode, postalCode of the address.
    // 					Id contactId, contact associated with the address.
    // 					Boolean isInsert, whether to insert Address record or not
    //* Returns     :   Address__c, a Address record
    //* Added by    :   Yuvraj Singh (Horizontal) - To get a test Address record
    //*********************************************************************************/
    public static Address__c getTestAddress(String addressType, String building, String street, String area, String city, String state , String country, String postalCode, Id contactId, Boolean isInsert)
    {
        Address__c testAddress = new Address__c ();
        testAddress.Contact__c = contactId;
        testAddress.Address_Type__c = addressType;
        testAddress.Building__c = building;
        testAddress.Street__c = street;
        testAddress.Area__c = area;
        testAddress.City_Town_Village__c = city;
        testAddress.State_Province__c = state;
        testAddress.Country__c = country;
        testAddress.Postal_Code__c = postalCode;
        if (isInsert) {
            insert testAddress;
        }
        return testAddress;
    }
    
    //********************************************************************************
    //* Method      :   getTestLicense
    //* Description :   Create a test License record
    //* Parameters  :   String licenseNumber, number of the license
    //					Id accountId, ID of the account associated with the license
    //                  Id serviceRequestId, ID of the service request associated with the license
    //                  Boolean isActive, indicates if the license is active or not
    //                  Boolean isInsert, whether to insert Address record or not
    //* Returns     :   License__c, a License record
    //* Added by    :   Honey Agarwal - To create a test License record
    //*********************************************************************************/
    public static License__c getTestLicense(String licenseNumber, Id accountId, Id serviceRequestId, Boolean isActive, Boolean isInsert) {
        License__c testLicense = new License__c();
        testLicense.Account__c = accountId; // Set to the provided Account ID
        testLicense.Is_Active__c = isActive; // Set to the provided active status
        testLicense.Name = licenseNumber; // Set to the provided license number
        testLicense.Service_Request__c = serviceRequestId; // Set to the provided Service Request ID
        if (isInsert) {
            insert testLicense;
        }
        return testLicense;
    }
    
    //********************************************************************************
    //* Method      :   getTestLicenseWithExpiryDate
    //* Description :   Create a test License record
    //* Parameters  :   String licenseNumber, number of the license
    //					Id accountId, ID of the account associated with the license
    //                  Id serviceRequestId, ID of the service request associated with the license
    //                  Boolean isActive, indicates if the license is active or not
    //                  Boolean isInsert, whether to insert Address record or not
    //* Returns     :   License__c, a License record
    //*********************************************************************************/
    public static License__c getTestLicenseWithExpiryDate(String licenseNumber, Id accountId, Id serviceRequestId, Boolean isActive, Boolean isInsert) {
        License__c testLicense = new License__c();
        testLicense.Account__c = accountId; // Set to the provided Account ID
        testLicense.Is_Active__c = isActive; // Set to the provided active status
        testLicense.Name = licenseNumber; // Set to the provided license number
        testLicense.Service_Request__c = serviceRequestId; // Set to the provided Service Request ID
        testLicense.License_Expiry_Date__c = Date.today();
        if (isInsert) {
            insert testLicense;
        }
        return testLicense;
    }
    //********************************************************************************
    //* Method      :   getTestCompany
    //* Description :   Create wrapper class object company
    //* Parameters  :   String licenseNumber, number of the license
    //					Id accountId, ID of the account associated with the license
    //                  Id serviceRequestId, ID of the service request associated with the license
    //                  Boolean isActive, indicates if the license is active or not
    //                  Boolean isInsert, whether to insert Address record or not
    //* Returns     :   RD_MyCompaniesController.Company an instance of Object
    //*********************************************************************************/
    public static RD_MyCompaniesController.Company getTestCompany(String accountId, String name, String status, String entityType, Date createdDate, Date renewalDate) {
        RD_MyCompaniesController.Company company = new RD_MyCompaniesController.Company();
        company.id = accountId;
        company.name = name;
        company.status = status;
        company.entity = entityType;
        company.createdDate = createdDate;
        company.renewalDate = renewalDate;
        
        return company;
    }

    public static DAO_Address__c getDaoAddress(String accId)
    {
        DAO_Address__c daoAddress = new DAO_Address__c();
        daoAddress.Active__c =true;
        daoAddress.Blockchain__c='Test Blockchain';
        daoAddress.DAO_Account__c = accId;
        daoAddress.Public_Address_of_the_DAO__c='Test public address';
        insert daoAddress;
        return daoAddress;

    }

    public static List<Treasury_Detail__c> getTreasuryDetail(String accId)
    {
        List<Treasury_Detail__c> td=new List<Treasury_Detail__c>();

        Treasury_Detail__c treasuryDetail = new Treasury_Detail__c();
        treasuryDetail.Number_of_Tokens__c =1.10;
        treasuryDetail.Token_Name__c='Test Token';
        treasuryDetail.Account__c = accId;
        treasuryDetail.Total_Values_in_USD__c=100.00;
        insert treasuryDetail;
        td.add(treasuryDetail);
        return td;

    }
}