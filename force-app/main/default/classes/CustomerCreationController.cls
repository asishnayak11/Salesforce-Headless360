global with sharing class CustomerCreationController {

    @InvocableMethod(label='Create Customer' 
                     description='Create a Customer record when User asks to check in or create a customer. User will provide Name, Mobile Number, Check In Date and Room Preference. For example user might say Check in John with mobile 9876543210 on 2025-06-15 with Sea View room preference.')
    global static List<Output> createCustomer(List<Input> inputWrapper) {

        Input inp = inputWrapper[0];

        String bookingId = generateRandomBookingId(); // Make External Call to Booking System to get the Booking ID

        Customer__c customer = new Customer__c();
        customer.Customer_Name__c = inp.customerName;
        customer.Mobile_Phone__c = inp.mobileNumber;
        customer.Check_In_Date__c = inp.checkInDate;
        customer.Room_Preference__c = inp.roomPreference;
        customer.Booking_ID__c = bookingId;
        customer.Status__c = 'Ready to Check In';
        insert customer;

        Output out = new Output();
        out.customerName = customer.Name;
        out.mobileNumber = customer.Mobile_Phone__c;
        out.checkInDate = customer.Check_In_Date__c;
        out.roomPreference = customer.Room_Preference__c;
        out.bookingId = customer.Booking_ID__c;
        out.status = customer.Status__c;

        return new List<Output>{ out };
    }

    public static String generateRandomBookingId() {
        Integer minValue = 100000;
        Integer maxValue = 99999999;
        Integer randomNumber = minValue + (Integer)Math.floor(Math.random() * (maxValue - minValue + 1));
        return 'BK-' + String.valueOf(randomNumber);
    }

    global class Input {
        @InvocableVariable(required=true description='The full name of the customer checking in.')
        public String customerName;

        @InvocableVariable(required=true description='The mobile phone number of the customer.')
        public String mobileNumber;

        @InvocableVariable(required=true description='The check-in date for the customer in YYYY-MM-DD format.')
        public Date checkInDate;

        @InvocableVariable(required=true description='The room preference of the customer such as Sea View, Garden View, Pool Side etc.')
        public String roomPreference;
    }

    global class Output {
        @InvocableVariable(description='The name of the created customer.')
        public String customerName;

        @InvocableVariable(description='The mobile phone number of the customer.')
        public String mobileNumber;

        @InvocableVariable(description='The check-in date of the customer.')
        public Date checkInDate;

        @InvocableVariable(description='The room preference of the customer.')
        public String roomPreference;

        @InvocableVariable(description='The auto-generated booking ID for the customer.')
        public String bookingId;

        @InvocableVariable(description='The status of the customer record.')
        public String status;
    }
}