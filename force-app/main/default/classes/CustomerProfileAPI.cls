/**
 * Exposes a complete hotel-customer 360 profile through a custom Apex REST
 * endpoint so an Agentforce agent (via a hosted custom MCP server) can answer
 * questions about a guest.
 *
 * This is the @RestResource equivalent of CustomerMcpService. The ApexDoc on
 * the method becomes the OpenAPI operation description, so it is written for
 * the model that will read it — clear, specific, and action oriented.
 *
 * @see https://developer.salesforce.com/docs/platform/hosted-mcp-servers/guide/custom-servers.html
 */
@RestResource(urlMapping='/CustomerProfileAPI/*')
global with sharing class CustomerProfileAPI {

    // GET /services/apexrest/CustomerProfileAPI/?customerName=Mukesh
    // Returns a complete 360 profile for the closest matching customer.
    @HttpGet
    global static List<CustomerDetail> doGet() {
        String customerName = RestContext.request.params.get('customerName');
        if (String.isBlank(customerName)) {
            return new List<CustomerDetail>();
        }

        String pattern = '%' + customerName + '%';

        List<Customer__c> customers = [
            SELECT Id, Name, Customer_Name__c, Booking_ID__c, Check_In_Date__c,
                   Mobile_Phone__c, Room_Preference__c, Status__c,
                   (SELECT Id, Name, Total_Amount__c FROM Food_Bills__r),
                   (SELECT Id, CaseNumber, Subject, Status, Priority, Origin,
                           Description, CreatedDate FROM Cases__r)
            FROM Customer__c
            WHERE Customer_Name__c LIKE :pattern
            WITH USER_MODE
            ORDER BY Name
            LIMIT 1
        ];

        if (customers.isEmpty()) {
            return new List<CustomerDetail>();
        }
        Customer__c customer = customers[0];

        List<Id> billIds = new List<Id>();
        for (Food_Bill__c bill : customer.Food_Bills__r) {
            billIds.add(bill.Id);
        }

        CustomerDetail detail = new CustomerDetail();
        detail.customerId = customer.Id;
        detail.customerNumber = customer.Name;
        detail.Name = customer.Customer_Name__c;
        detail.bookingId = customer.Booking_ID__c;
        detail.checkInDate = customer.Check_In_Date__c;
        detail.mobilePhone = customer.Mobile_Phone__c;
        detail.roomPreference = customer.Room_Preference__c;
        detail.status = customer.Status__c;

        detail.foodBills = new List<FoodBillInfo>();
        for (Food_Bill__c bill : customer.Food_Bills__r) {
            FoodBillInfo billInfo = new FoodBillInfo();
            billInfo.billId = bill.Id;
            billInfo.billNumber = bill.Name;
            billInfo.totalAmount = bill.Total_Amount__c;
            detail.foodBills.add(billInfo);
        }

        detail.roomServiceCases = new List<RoomServiceCaseInfo>();
        for (Case roomCase : customer.Cases__r) {
            RoomServiceCaseInfo caseInfo = new RoomServiceCaseInfo();
            caseInfo.caseId = roomCase.Id;
            caseInfo.caseNumber = roomCase.CaseNumber;
            caseInfo.subject = roomCase.Subject;
            caseInfo.status = roomCase.Status;
            caseInfo.priority = roomCase.Priority;
            caseInfo.origin = roomCase.Origin;
            caseInfo.description = roomCase.Description;
            caseInfo.createdDate = roomCase.CreatedDate;
            detail.roomServiceCases.add(caseInfo);
        }

        return new List<CustomerDetail>{ detail };
    }

    // Concrete return types (not Object) so the OpenAPI generator can describe
    // the full nested response shape.
    global class CustomerDetail {
        global String  customerId;
        global String  name;
        global String  customerNumber;
        global String  bookingId;
        global Date     checkInDate;
        global String  mobilePhone;
        global String  roomPreference;
        global String  status;
        global List<FoodBillInfo> foodBills;
        global List<RoomServiceCaseInfo> roomServiceCases;
    }

    global class FoodBillInfo {
        global String  billId;
        global String  billNumber;
        global Decimal totalAmount;
    }

    global class RoomServiceCaseInfo {
        global String   caseId;
        global String   caseNumber;
        global String   subject;
        global String   status;
        global String   priority;
        global String   origin;
        global String   description;
        global Datetime createdDate;
    }
}